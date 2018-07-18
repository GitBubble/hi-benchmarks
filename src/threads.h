// SPDX-License-Identifier: GPL-3.0+
#ifndef HIBENCHMARKS_THREADS_H
#define HIBENCHMARKS_THREADS_H

extern pid_t gettid(void);

typedef enum {
    HIBENCHMARKS_THREAD_OPTION_DEFAULT          = 0 << 0,
    HIBENCHMARKS_THREAD_OPTION_JOINABLE         = 1 << 0,
    HIBENCHMARKS_THREAD_OPTION_DONT_LOG_STARTUP = 1 << 1,
    HIBENCHMARKS_THREAD_OPTION_DONT_LOG_CLEANUP = 1 << 2,
    HIBENCHMARKS_THREAD_OPTION_DONT_LOG         = HIBENCHMARKS_THREAD_OPTION_DONT_LOG_STARTUP|HIBENCHMARKS_THREAD_OPTION_DONT_LOG_CLEANUP,
} HIBENCHMARKS_THREAD_OPTIONS;

#define hibenchmarks_thread_cleanup_push(func, arg) pthread_cleanup_push(func, arg)
#define hibenchmarks_thread_cleanup_pop(execute) pthread_cleanup_pop(execute)

typedef pthread_t hibenchmarks_thread_t;

#define HIBENCHMARKS_THREAD_TAG_MAX 100
extern const char *hibenchmarks_thread_tag(void);

extern size_t hibenchmarks_threads_init(void);
extern void hibenchmarks_threads_init_after_fork(size_t stacksize);

extern int hibenchmarks_thread_create(hibenchmarks_thread_t *thread, const char *tag, HIBENCHMARKS_THREAD_OPTIONS options, void *(*start_routine) (void *), void *arg);
extern int hibenchmarks_thread_cancel(hibenchmarks_thread_t thread);
extern int hibenchmarks_thread_join(hibenchmarks_thread_t thread, void **retval);
extern int hibenchmarks_thread_detach(pthread_t thread);

#define hibenchmarks_thread_self pthread_self
#define hibenchmarks_thread_testcancel pthread_testcancel

#endif //HIBENCHMARKS_THREADS_H
