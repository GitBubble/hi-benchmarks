// SPDX-License-Identifier: GPL-3.0+
#ifndef HIBENCHMARKS_LOCKS_H
#define HIBENCHMARKS_LOCKS_H

typedef pthread_mutex_t hibenchmarks_mutex_t;
#define HIBENCHMARKS_MUTEX_INITIALIZER PTHREAD_MUTEX_INITIALIZER

typedef pthread_rwlock_t hibenchmarks_rwlock_t;
#define HIBENCHMARKS_RWLOCK_INITIALIZER PTHREAD_RWLOCK_INITIALIZER

extern int __hibenchmarks_mutex_init(hibenchmarks_mutex_t *mutex);
extern int __hibenchmarks_mutex_lock(hibenchmarks_mutex_t *mutex);
extern int __hibenchmarks_mutex_trylock(hibenchmarks_mutex_t *mutex);
extern int __hibenchmarks_mutex_unlock(hibenchmarks_mutex_t *mutex);

extern int __hibenchmarks_rwlock_destroy(hibenchmarks_rwlock_t *rwlock);
extern int __hibenchmarks_rwlock_init(hibenchmarks_rwlock_t *rwlock);
extern int __hibenchmarks_rwlock_rdlock(hibenchmarks_rwlock_t *rwlock);
extern int __hibenchmarks_rwlock_wrlock(hibenchmarks_rwlock_t *rwlock);
extern int __hibenchmarks_rwlock_unlock(hibenchmarks_rwlock_t *rwlock);
extern int __hibenchmarks_rwlock_tryrdlock(hibenchmarks_rwlock_t *rwlock);
extern int __hibenchmarks_rwlock_trywrlock(hibenchmarks_rwlock_t *rwlock);

extern int hibenchmarks_mutex_init_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_mutex_t *mutex);
extern int hibenchmarks_mutex_lock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_mutex_t *mutex);
extern int hibenchmarks_mutex_trylock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_mutex_t *mutex);
extern int hibenchmarks_mutex_unlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_mutex_t *mutex);

extern int hibenchmarks_rwlock_destroy_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock);
extern int hibenchmarks_rwlock_init_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock);
extern int hibenchmarks_rwlock_rdlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock);
extern int hibenchmarks_rwlock_wrlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock);
extern int hibenchmarks_rwlock_unlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock);
extern int hibenchmarks_rwlock_tryrdlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock);
extern int hibenchmarks_rwlock_trywrlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock);

extern void hibenchmarks_thread_disable_cancelability(void);
extern void hibenchmarks_thread_enable_cancelability(void);

#ifdef HIBENCHMARKS_INTERNAL_CHECKS

#define hibenchmarks_mutex_init(mutex)    hibenchmarks_mutex_init_debug(__FILE__, __FUNCTION__, __LINE__, mutex)
#define hibenchmarks_mutex_lock(mutex)    hibenchmarks_mutex_lock_debug(__FILE__, __FUNCTION__, __LINE__, mutex)
#define hibenchmarks_mutex_trylock(mutex) hibenchmarks_mutex_trylock_debug(__FILE__, __FUNCTION__, __LINE__, mutex)
#define hibenchmarks_mutex_unlock(mutex)  hibenchmarks_mutex_unlock_debug(__FILE__, __FUNCTION__, __LINE__, mutex)

#define hibenchmarks_rwlock_destroy(rwlock)   hibenchmarks_rwlock_destroy_debug(__FILE__, __FUNCTION__, __LINE__, rwlock)
#define hibenchmarks_rwlock_init(rwlock)      hibenchmarks_rwlock_init_debug(__FILE__, __FUNCTION__, __LINE__, rwlock)
#define hibenchmarks_rwlock_rdlock(rwlock)    hibenchmarks_rwlock_rdlock_debug(__FILE__, __FUNCTION__, __LINE__, rwlock)
#define hibenchmarks_rwlock_wrlock(rwlock)    hibenchmarks_rwlock_wrlock_debug(__FILE__, __FUNCTION__, __LINE__, rwlock)
#define hibenchmarks_rwlock_unlock(rwlock)    hibenchmarks_rwlock_unlock_debug(__FILE__, __FUNCTION__, __LINE__, rwlock)
#define hibenchmarks_rwlock_tryrdlock(rwlock) hibenchmarks_rwlock_tryrdlock_debug(__FILE__, __FUNCTION__, __LINE__, rwlock)
#define hibenchmarks_rwlock_trywrlock(rwlock) hibenchmarks_rwlock_trywrlock_debug(__FILE__, __FUNCTION__, __LINE__, rwlock)

#else // !HIBENCHMARKS_INTERNAL_CHECKS

#define hibenchmarks_mutex_init(mutex)    __hibenchmarks_mutex_init(mutex)
#define hibenchmarks_mutex_lock(mutex)    __hibenchmarks_mutex_lock(mutex)
#define hibenchmarks_mutex_trylock(mutex) __hibenchmarks_mutex_trylock(mutex)
#define hibenchmarks_mutex_unlock(mutex)  __hibenchmarks_mutex_unlock(mutex)

#define hibenchmarks_rwlock_destroy(rwlock)    __hibenchmarks_rwlock_destroy(rwlock)
#define hibenchmarks_rwlock_init(rwlock)       __hibenchmarks_rwlock_init(rwlock)
#define hibenchmarks_rwlock_rdlock(rwlock)     __hibenchmarks_rwlock_rdlock(rwlock)
#define hibenchmarks_rwlock_wrlock(rwlock)     __hibenchmarks_rwlock_wrlock(rwlock)
#define hibenchmarks_rwlock_unlock(rwlock)     __hibenchmarks_rwlock_unlock(rwlock)
#define hibenchmarks_rwlock_tryrdlock(rwlock)  __hibenchmarks_rwlock_tryrdlock(rwlock)
#define hibenchmarks_rwlock_trywrlock(rwlock)  __hibenchmarks_rwlock_trywrlock(rwlock)

#endif // HIBENCHMARKS_INTERNAL_CHECKS

#endif //HIBENCHMARKS_LOCKS_H
