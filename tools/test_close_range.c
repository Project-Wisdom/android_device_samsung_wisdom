/*
 * test_close_range.c - Comprehensive test suite for Linux close_range(2) (syscall 436)
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/syscall.h>
#include <limits.h>
#include <pthread.h>
#include <spawn.h>
#include <sys/wait.h>

#ifndef __NR_close_range
#define __NR_close_range 436
#endif

#ifndef CLOSE_RANGE_UNSHARE
#define CLOSE_RANGE_UNSHARE (1U << 1)
#endif

#ifndef CLOSE_RANGE_CLOEXEC
#define CLOSE_RANGE_CLOEXEC (1U << 2)
#endif

#ifndef POSIX_SPAWN_CLOEXEC_DEFAULT
#define POSIX_SPAWN_CLOEXEC_DEFAULT 256
#endif

static int do_close_range(unsigned int first, unsigned int last, unsigned int flags) {
    return syscall(__NR_close_range, first, last, flags);
}

static int check_fd_open(int fd) {
    errno = 0;
    int flags = fcntl(fd, F_GETFD);
    if (flags == -1 && errno == EBADF)
        return 0; // closed
    return 1; // open
}

static int check_fd_cloexec(int fd) {
    errno = 0;
    int flags = fcntl(fd, F_GETFD);
    if (flags == -1)
        return -1;
    return (flags & FD_CLOEXEC) ? 1 : 0;
}

/* ========================================================================= */
/* Test Part 1: Basic validation, CLOEXEC, Sparse, UINT_MAX                  */
/* ========================================================================= */

static int run_basic_tests(void) {
    printf("\n=== [1/3] Basic Syscall & Parameter Validation Tests ===\n");

    /* 1.1: first > last */
    int ret = do_close_range(10, 5, 0);
    if (ret != -1 || errno != EINVAL) {
        printf("[-] FAIL: first > last expected -EINVAL, got ret=%d errno=%d (%s)\n",
               ret, errno, strerror(errno));
        return 1;
    }
    printf("[+] PASS: first > last -> -EINVAL\n");

    /* 1.2: Unknown flags */
    ret = do_close_range(5, 10, 0x80);
    if (ret != -1 || errno != EINVAL) {
        printf("[-] FAIL: unknown flag 0x80 expected -EINVAL, got ret=%d errno=%d (%s)\n",
               ret, errno, strerror(errno));
        return 1;
    }
    printf("[+] PASS: unknown flags -> -EINVAL\n");

    /* 1.3: first >= max_fds */
    ret = do_close_range(1000000, 2000000, 0);
    if (ret != 0) {
        printf("[-] FAIL: first >= max_fds expected 0, got ret=%d errno=%d\n", ret, errno);
        return 1;
    }
    printf("[+] PASS: first >= max_fds -> 0\n");

    /* 1.4: CLOSE_RANGE_CLOEXEC */
    int fd1 = open("/dev/null", O_RDONLY);
    int fd2 = open("/dev/null", O_RDONLY);
    int fd3 = open("/dev/null", O_RDONLY);
    if (fd1 < 0 || fd2 < 0 || fd3 < 0) {
        perror("[-] open failed");
        return 1;
    }
    ret = do_close_range(fd2, fd3, CLOSE_RANGE_CLOEXEC);
    if (ret != 0) {
        printf("[-] FAIL: CLOEXEC returned %d errno=%d\n", ret, errno);
        return 1;
    }
    if (check_fd_cloexec(fd1) != 0 || check_fd_cloexec(fd2) != 1 || check_fd_cloexec(fd3) != 1) {
        printf("[-] FAIL: CLOEXEC flags mismatch (fd1=%d, fd2=%d, fd3=%d)\n",
               check_fd_cloexec(fd1), check_fd_cloexec(fd2), check_fd_cloexec(fd3));
        return 1;
    }
    if (!check_fd_open(fd2) || !check_fd_open(fd3)) {
        printf("[-] FAIL: fds prematurely closed by CLOEXEC\n");
        return 1;
    }
    printf("[+] PASS: CLOSE_RANGE_CLOEXEC marks bits without closing fds\n");

    /* 1.5: UINT_MAX close */
    ret = do_close_range(fd2, ~0U, 0);
    if (ret != 0 || !check_fd_open(fd1) || check_fd_open(fd2) || check_fd_open(fd3)) {
        printf("[-] FAIL: UINT_MAX close failed (ret=%d, fd1=%d, fd2=%d, fd3=%d)\n",
               ret, check_fd_open(fd1), check_fd_open(fd2), check_fd_open(fd3));
        return 1;
    }
    close(fd1);
    printf("[+] PASS: Normal close with max_fd == UINT_MAX\n");

    /* 1.6: Sparse Range test */
    int sfd1 = open("/dev/null", O_RDONLY);
    // deliberately create a gap by opening and closing middle fds
    int gap1 = open("/dev/null", O_RDONLY);
    int gap2 = open("/dev/null", O_RDONLY);
    close(gap1);
    close(gap2);
    int sfd2 = open("/dev/null", O_RDONLY);
    ret = do_close_range(sfd1, sfd2, 0);
    if (ret != 0 || check_fd_open(sfd1) || check_fd_open(sfd2)) {
        printf("[-] FAIL: Sparse close failed\n");
        return 1;
    }
    printf("[+] PASS: Sparse range with closed gaps closes correctly\n");

    return 0;
}

/* ========================================================================= */
/* Test Part 2: pthread Shared-fdtable & CLOSE_RANGE_UNSHARE Concurrency      */
/* ========================================================================= */

struct thread_sync {
    int shared_pipe[2];
    int shared_file;
    pthread_barrier_t barrier1;
    pthread_barrier_t barrier2;
    int thread_a_result;
    int thread_b_result;
};

static void *thread_a_func(void *arg) {
    struct thread_sync *sync = (struct thread_sync *)arg;

    // Wait for thread B to be ready
    pthread_barrier_wait(&sync->barrier1);

    // Thread A calls CLOSE_RANGE_UNSHARE on shared_pipe[0]..shared_pipe[1]
    int ret = do_close_range(sync->shared_pipe[0], sync->shared_pipe[1], CLOSE_RANGE_UNSHARE);
    if (ret != 0) {
        printf("[-] Thread A: do_close_range failed: %d (%s)\n", errno, strerror(errno));
        sync->thread_a_result = 1;
    }

    // In Thread A, shared_pipe must now be closed!
    if (check_fd_open(sync->shared_pipe[0]) || check_fd_open(sync->shared_pipe[1])) {
        printf("[-] Thread A: pipe fds still open after CLOSE_RANGE_UNSHARE!\n");
        sync->thread_a_result = 2;
    }

    // Now test CLOSE_RANGE_UNSHARE | CLOSE_RANGE_CLOEXEC on shared_file
    ret = do_close_range(sync->shared_file, sync->shared_file,
                         CLOSE_RANGE_UNSHARE | CLOSE_RANGE_CLOEXEC);
    if (ret != 0) {
        printf("[-] Thread A: UNSHARE | CLOEXEC failed: %d\n", errno);
        sync->thread_a_result = 3;
    }
    if (check_fd_cloexec(sync->shared_file) != 1) {
        printf("[-] Thread A: shared_file not cloexec in Thread A!\n");
        sync->thread_a_result = 4;
    }

    // Notify Thread B to check its fds
    pthread_barrier_wait(&sync->barrier2);
    return NULL;
}

static void *thread_b_func(void *arg) {
    struct thread_sync *sync = (struct thread_sync *)arg;

    // Wait for Thread A to reach start
    pthread_barrier_wait(&sync->barrier1);

    // Wait for Thread A to complete unshare & close
    pthread_barrier_wait(&sync->barrier2);

    // In Thread B, the pipe MUST STILL BE OPEN and usable!
    if (!check_fd_open(sync->shared_pipe[0]) || !check_fd_open(sync->shared_pipe[1])) {
        printf("[-] Thread B: pipe fds were incorrectly closed in Thread B!\n");
        sync->thread_b_result = 1;
        return NULL;
    }

    // Verify pipe is actually usable: write and read 1 byte
    char test_byte = 'X', recv_byte = 0;
    if (write(sync->shared_pipe[1], &test_byte, 1) != 1) {
        printf("[-] Thread B: write to shared_pipe[1] failed: %s\n", strerror(errno));
        sync->thread_b_result = 2;
        return NULL;
    }
    if (read(sync->shared_pipe[0], &recv_byte, 1) != 1 || recv_byte != 'X') {
        printf("[-] Thread B: read from shared_pipe[0] failed!\n");
        sync->thread_b_result = 3;
        return NULL;
    }

    // In Thread B, shared_file must NOT have received FD_CLOEXEC from Thread A!
    if (check_fd_cloexec(sync->shared_file) != 0) {
        printf("[-] Thread B: shared_file was modified in Thread B by Thread A's unshared cloexec!\n");
        sync->thread_b_result = 4;
        return NULL;
    }

    close(sync->shared_pipe[0]);
    close(sync->shared_pipe[1]);
    close(sync->shared_file);
    sync->thread_b_result = 0;
    return NULL;
}

static int run_pthread_unshare_tests(void) {
    printf("\n=== [2/3] pthread Shared-fdtable CLOSE_RANGE_UNSHARE Concurrency Tests ===\n");

    struct thread_sync sync;
    memset(&sync, 0, sizeof(sync));
    if (pipe(sync.shared_pipe) < 0) {
        perror("[-] pipe failed");
        return 1;
    }
    sync.shared_file = open("/dev/null", O_RDONLY);
    if (sync.shared_file < 0) {
        perror("[-] open failed");
        return 1;
    }

    pthread_barrier_init(&sync.barrier1, NULL, 2);
    pthread_barrier_init(&sync.barrier2, NULL, 2);

    pthread_t th_a, th_b;
    pthread_create(&th_a, NULL, thread_a_func, &sync);
    pthread_create(&th_b, NULL, thread_b_func, &sync);

    pthread_join(th_a, NULL);
    pthread_join(th_b, NULL);

    pthread_barrier_destroy(&sync.barrier1);
    pthread_barrier_destroy(&sync.barrier2);

    if (sync.thread_a_result != 0) {
        printf("[-] FAIL: Thread A reported error code %d\n", sync.thread_a_result);
        return 1;
    }
    if (sync.thread_b_result != 0) {
        printf("[-] FAIL: Thread B reported error code %d\n", sync.thread_b_result);
        return 1;
    }

    printf("[+] PASS: Thread A gained private fdtable via UNSHARE; closed fds in A without touching Thread B\n");
    printf("[+] PASS: Thread B kept pipe operational and fcntl flags intact\n");
    return 0;
}

/* ========================================================================= */
/* Test Part 3: Real posix_spawn() with POSIX_SPAWN_CLOEXEC_DEFAULT          */
/* ========================================================================= */

static int run_posix_spawn_test(void) {
    printf("\n=== [3/3] Real posix_spawn(..., POSIX_SPAWN_CLOEXEC_DEFAULT) Test ===\n");

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    // Set POSIX_SPAWN_CLOEXEC_DEFAULT flag
    short flags = POSIX_SPAWN_USEVFORK | POSIX_SPAWN_CLOEXEC_DEFAULT;
    int err = posix_spawnattr_setflags(&attr, flags);
    if (err) {
        printf("[-] FAIL: posix_spawnattr_setflags failed: %d (%s)\n", err, strerror(err));
        posix_spawnattr_destroy(&attr);
        return 1;
    }

    // Open extra non-stdio fds that MUST NOT be inherited by child
    int extra_fd1 = open("/dev/null", O_RDONLY);
    int extra_fd2 = open("/dev/null", O_RDONLY);
    printf("[*] Created non-stdio fds: %d, %d (not initially O_CLOEXEC)\n", extra_fd1, extra_fd2);

    // Spawn /system/bin/toybox true or /system/bin/sh -c "exit 0"
    pid_t pid;
    char *const spawn_argv[] = { (char *)"/system/bin/toybox", (char *)"true", NULL };
    char *const spawn_envp[] = { (char *)"PATH=/system/bin", NULL };

    err = posix_spawn(&pid, "/system/bin/toybox", NULL, &attr, spawn_argv, spawn_envp);
    posix_spawnattr_destroy(&attr);

    if (err != 0) {
        printf("[-] FAIL: posix_spawn failed with error: %d (%s)\n", err, strerror(err));
        close(extra_fd1);
        close(extra_fd2);
        return 1;
    }
    printf("[*] posix_spawn returned pid %d (spawn succeeded!)\n", pid);

    int status = 0;
    waitpid(pid, &status, 0);

    if (!WIFEXITED(status)) {
        printf("[-] FAIL: child process did not exit normally (status=0x%x)\n", status);
        close(extra_fd1);
        close(extra_fd2);
        return 1;
    }

    int exit_code = WEXITSTATUS(status);
    printf("[*] Child process exit code: %d\n", exit_code);
    if (exit_code == 127) {
        printf("[-] FAIL: child exited with 127! (close_range syscall failed inside bionic spawn)\n");
        close(extra_fd1);
        close(extra_fd2);
        return 1;
    }
    if (exit_code != 0) {
        printf("[-] FAIL: child exited with non-zero code %d\n", exit_code);
        close(extra_fd1);
        close(extra_fd2);
        return 1;
    }

    printf("[+] PASS: Child process executed cleanly (code 0) under POSIX_SPAWN_CLOEXEC_DEFAULT!\n");

    close(extra_fd1);
    close(extra_fd2);
    return 0;
}

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;
    printf("=================================================================\n");
    printf("Linux close_range(2) / AOSP Android 17 Comprehensive Verification\n");
    printf("=================================================================\n");

    if (run_basic_tests() != 0)
        return 1;

    if (run_pthread_unshare_tests() != 0)
        return 2;

    if (run_posix_spawn_test() != 0)
        return 3;

    printf("\n=================================================================\n");
    printf("[***] ALL COMPREHENSIVE close_range(2) TESTS PASSED! [***]\n");
    printf("=================================================================\n");
    return 0;
}
