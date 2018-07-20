// SPDX-License-Identifier: GPL-3.0+
#include "common.h"

// ----------------------------------------------------------------------------
// automatic thread cancelability management, based on locks

static __thread int hibenchmarks_thread_first_cancelability = 0;
static __thread int hibenchmarks_thread_lock_cancelability = 0;

inline void hibenchmarks_thread_disable_cancelability(void) {
    int old;
    int ret = pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &old);
    if(ret != 0)
        error("THREAD_CANCELABILITY: pthread_setcancelstate() on thread %s returned error %d", hibenchmarks_thread_tag(), ret);
    else {
        if(!hibenchmarks_thread_lock_cancelability)
            hibenchmarks_thread_first_cancelability = old;

        hibenchmarks_thread_lock_cancelability++;
    }
}

inline void hibenchmarks_thread_enable_cancelability(void) {
    if(hibenchmarks_thread_lock_cancelability < 1) {
        error("THREAD_CANCELABILITY: hibenchmarks_thread_enable_cancelability(): invalid thread cancelability count %d on thread %s - results will be undefined - please report this!", hibenchmarks_thread_lock_cancelability, hibenchmarks_thread_tag());
    }
    else if(hibenchmarks_thread_lock_cancelability == 1) {
        int old = 1;
        int ret = pthread_setcancelstate(hibenchmarks_thread_first_cancelability, &old);
        if(ret != 0)
            error("THREAD_CANCELABILITY: pthread_setcancelstate() on thread %s returned error %d", hibenchmarks_thread_tag(), ret);
        else {
            if(old != PTHREAD_CANCEL_DISABLE)
                error("THREAD_CANCELABILITY: hibenchmarks_thread_enable_cancelability(): old thread cancelability on thread %s was changed, expected DISABLED (%d), found %s (%d) - please report this!", hibenchmarks_thread_tag(), PTHREAD_CANCEL_DISABLE, (old == PTHREAD_CANCEL_ENABLE)?"ENABLED":"UNKNOWN", old);
        }

        hibenchmarks_thread_lock_cancelability = 0;
    }
    else
        hibenchmarks_thread_lock_cancelability--;
}

// ----------------------------------------------------------------------------
// mutex

int __hibenchmarks_mutex_init(hibenchmarks_mutex_t *mutex) {
    int ret = pthread_mutex_init(mutex, NULL);
    if(unlikely(ret != 0))
        error("MUTEX_LOCK: failed to initialize (code %d).", ret);
    return ret;
}

int __hibenchmarks_mutex_lock(hibenchmarks_mutex_t *mutex) {
    hibenchmarks_thread_disable_cancelability();

    int ret = pthread_mutex_lock(mutex);
    if(unlikely(ret != 0)) {
        hibenchmarks_thread_enable_cancelability();
        error("MUTEX_LOCK: failed to get lock (code %d)", ret);
    }
    return ret;
}

int __hibenchmarks_mutex_trylock(hibenchmarks_mutex_t *mutex) {
    hibenchmarks_thread_disable_cancelability();

    int ret = pthread_mutex_trylock(mutex);
    if(ret != 0)
        hibenchmarks_thread_enable_cancelability();

    return ret;
}

int __hibenchmarks_mutex_unlock(hibenchmarks_mutex_t *mutex) {
    int ret = pthread_mutex_unlock(mutex);
    if(unlikely(ret != 0))
        error("MUTEX_LOCK: failed to unlock (code %d).", ret);
    else
        hibenchmarks_thread_enable_cancelability();

    return ret;
}

int hibenchmarks_mutex_init_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_mutex_t *mutex) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "MUTEX_LOCK: hibenchmarks_mutex_init(0x%p) from %lu@%s, %s()", mutex, line, file, function);
    }

    int ret = __hibenchmarks_mutex_init(mutex);

    debug(D_LOCKS, "MUTEX_LOCK: hibenchmarks_mutex_init(0x%p) = %d in %llu usec, from %lu@%s, %s()", mutex, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}

int hibenchmarks_mutex_lock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_mutex_t *mutex) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "MUTEX_LOCK: hibenchmarks_mutex_lock(0x%p) from %lu@%s, %s()", mutex, line, file, function);
    }

    int ret = __hibenchmarks_mutex_lock(mutex);

    debug(D_LOCKS, "MUTEX_LOCK: hibenchmarks_mutex_lock(0x%p) = %d in %llu usec, from %lu@%s, %s()", mutex, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}

int hibenchmarks_mutex_trylock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_mutex_t *mutex) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "MUTEX_LOCK: hibenchmarks_mutex_trylock(0x%p) from %lu@%s, %s()", mutex, line, file, function);
    }

    int ret = __hibenchmarks_mutex_trylock(mutex);

    debug(D_LOCKS, "MUTEX_LOCK: hibenchmarks_mutex_trylock(0x%p) = %d in %llu usec, from %lu@%s, %s()", mutex, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}

int hibenchmarks_mutex_unlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_mutex_t *mutex) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "MUTEX_LOCK: hibenchmarks_mutex_unlock(0x%p) from %lu@%s, %s()", mutex, line, file, function);
    }

    int ret = __hibenchmarks_mutex_unlock(mutex);

    debug(D_LOCKS, "MUTEX_LOCK: hibenchmarks_mutex_unlock(0x%p) = %d in %llu usec, from %lu@%s, %s()", mutex, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}


// ----------------------------------------------------------------------------
// r/w lock

int __hibenchmarks_rwlock_destroy(hibenchmarks_rwlock_t *rwlock) {
    int ret = pthread_rwlock_destroy(rwlock);
    if(unlikely(ret != 0))
        error("RW_LOCK: failed to destroy lock (code %d)", ret);
    return ret;
}

int __hibenchmarks_rwlock_init(hibenchmarks_rwlock_t *rwlock) {
    int ret = pthread_rwlock_init(rwlock, NULL);
    if(unlikely(ret != 0))
        error("RW_LOCK: failed to initialize lock (code %d)", ret);
    return ret;
}

int __hibenchmarks_rwlock_rdlock(hibenchmarks_rwlock_t *rwlock) {
    hibenchmarks_thread_disable_cancelability();

    int ret = pthread_rwlock_rdlock(rwlock);
    if(unlikely(ret != 0)) {
        hibenchmarks_thread_enable_cancelability();
        error("RW_LOCK: failed to obtain read lock (code %d)", ret);
    }

    return ret;
}

int __hibenchmarks_rwlock_wrlock(hibenchmarks_rwlock_t *rwlock) {
    hibenchmarks_thread_disable_cancelability();

    int ret = pthread_rwlock_wrlock(rwlock);
    if(unlikely(ret != 0)) {
        error("RW_LOCK: failed to obtain write lock (code %d)", ret);
        hibenchmarks_thread_enable_cancelability();
    }

    return ret;
}

int __hibenchmarks_rwlock_unlock(hibenchmarks_rwlock_t *rwlock) {
    int ret = pthread_rwlock_unlock(rwlock);
    if(unlikely(ret != 0))
        error("RW_LOCK: failed to release lock (code %d)", ret);
    else
        hibenchmarks_thread_enable_cancelability();

    return ret;
}

int __hibenchmarks_rwlock_tryrdlock(hibenchmarks_rwlock_t *rwlock) {
    hibenchmarks_thread_disable_cancelability();

    int ret = pthread_rwlock_tryrdlock(rwlock);
    if(ret != 0)
        hibenchmarks_thread_enable_cancelability();

    return ret;
}

int __hibenchmarks_rwlock_trywrlock(hibenchmarks_rwlock_t *rwlock) {
    hibenchmarks_thread_disable_cancelability();

    int ret = pthread_rwlock_trywrlock(rwlock);
    if(ret != 0)
        hibenchmarks_thread_enable_cancelability();

    return ret;
}


int hibenchmarks_rwlock_destroy_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_destroy(0x%p) from %lu@%s, %s()", rwlock, line, file, function);
    }

    int ret = __hibenchmarks_rwlock_destroy(rwlock);

    debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_destroy(0x%p) = %d in %llu usec, from %lu@%s, %s()", rwlock, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}

int hibenchmarks_rwlock_init_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_init(0x%p) from %lu@%s, %s()", rwlock, line, file, function);
    }

    int ret = __hibenchmarks_rwlock_init(rwlock);

    debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_init(0x%p) = %d in %llu usec, from %lu@%s, %s()", rwlock, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}

int hibenchmarks_rwlock_rdlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_rdlock(0x%p) from %lu@%s, %s()", rwlock, line, file, function);
    }

    int ret = __hibenchmarks_rwlock_rdlock(rwlock);

    debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_rdlock(0x%p) = %d in %llu usec, from %lu@%s, %s()", rwlock, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}

int hibenchmarks_rwlock_wrlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_wrlock(0x%p) from %lu@%s, %s()", rwlock, line, file, function);
    }

    int ret = __hibenchmarks_rwlock_wrlock(rwlock);

    debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_wrlock(0x%p) = %d in %llu usec, from %lu@%s, %s()", rwlock, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}

int hibenchmarks_rwlock_unlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_unlock(0x%p) from %lu@%s, %s()", rwlock, line, file, function);
    }

    int ret = __hibenchmarks_rwlock_unlock(rwlock);

    debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_unlock(0x%p) = %d in %llu usec, from %lu@%s, %s()", rwlock, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}

int hibenchmarks_rwlock_tryrdlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_tryrdlock(0x%p) from %lu@%s, %s()", rwlock, line, file, function);
    }

    int ret = __hibenchmarks_rwlock_tryrdlock(rwlock);

    debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_tryrdlock(0x%p) = %d in %llu usec, from %lu@%s, %s()", rwlock, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}

int hibenchmarks_rwlock_trywrlock_debug( const char *file, const char *function, const unsigned long line, hibenchmarks_rwlock_t *rwlock) {
    usec_t start = 0;

    if(unlikely(debug_flags & D_LOCKS)) {
        start = now_boottime_usec();
        debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_trywrlock(0x%p) from %lu@%s, %s()", rwlock, line, file, function);
    }

    int ret = __hibenchmarks_rwlock_trywrlock(rwlock);

    debug(D_LOCKS, "RW_LOCK: hibenchmarks_rwlock_trywrlock(0x%p) = %d in %llu usec, from %lu@%s, %s()", rwlock, ret, now_boottime_usec() - start, line, file, function);

    return ret;
}
