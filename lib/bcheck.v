@[translated]
module bcheck

#include <pthread.h>

$if linux {
	@[typedef]
	struct C.pthread_spinlock_t {}

	fn C.pthread_spin_unlock(&C.pthread_spinlock_t)
	fn C.pthread_spin_lock(&C.pthread_spinlock_t)
	fn C.pthread_spin_init(&C.pthread_spinlock_t, int)
}

@[typedef]
struct C.pthread_mutex_t {}

fn C.pthread_mutex_lock(&C.pthread_mutex_t)
fn C.pthread_mutex_unlock(&C.pthread_mutex_t)
fn C.pthread_mutex_init(&C.pthread_mutex_t, voidptr)

$if linux {
	__global bounds_spin = C.pthread_spinlock_t{}
} $else {
	__global bounds_mutex = C.pthread_mutex_t{}
}
__global use_sem = u8(0)
__global inited = u8(0)

@[export: '__bound_checking_lock']
pub fn __bound_checking_lock() {
	wait_sem()
}

@[export: '__bound_checking_unlock']
pub fn __bound_checking_unlock() {
	post_sem()
}

@[inline]
fn wait_sem() {
	if use_sem {
		$if linux {
			C.pthread_spin_lock(&bounds_spin)
		} $else {
			C.pthread_mutex_lock(&bounds_mutex)
		}
	}
}

@[inline]
fn post_sem() {
	if use_sem {
		$if linux {
			C.pthread_spin_unlock(&bounds_spin)
		} $else {
			C.pthread_mutex_unlock(&bounds_mutex)
		}
	}
}

@[inline]
fn init_sem() {
	$if linux {
		C.pthread_spin_init(&bounds_spin, 0)
	} $else {
		C.pthread_mutex_init(&bounds_mutex, unsafe { nil })
	}
}

@[export: '__bound_exit_dll']
pub fn __bound_exit_dll(p &usize) {
}
