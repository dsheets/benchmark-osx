#include <assert.h>
#include <fcntl.h>
#include <unistd.h>
#include <pthread.h>

#include "../benchmark_osx_pwrite.h"

// Buffers are "deallocated" and fds closed by process exit.
typedef struct {
    char *buffer;
    int fd;
    pthread_t thread;
} per_file;

void pwrite_thread(per_file *state);
typedef void* (*thread_routine)(void*);

bool begin = false;
pthread_cond_t begin_condition;
pthread_mutex_t begin_mutex;

int main(int argc, char **argv) {
    benchmark_parameters(argc, argv);

    pthread_cond_init(&begin_condition, NULL);
    pthread_mutex_init(&begin_mutex, NULL);

    per_file *state =
        benchmark_malloc(sizeof(per_file) * benchmark_concurrency);
    for (int thread = 0; thread < benchmark_concurrency; ++thread) {
        state[thread].buffer = benchmark_malloc(benchmark_buffer_size);

        state[thread].fd =
            open(benchmark_file(thread), O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (state[thread].fd == -1) {
            perror("fopen");
            exit(1);
        }

        int result =
            pthread_create(&state[thread].thread, NULL,
                           (thread_routine)pwrite_thread, &state[thread]);
        if (result != 0) {
            errno = result;
            perror("pthread_create");
            exit(1);
        }
    }

    uint64_t start = mach_absolute_time();

    pthread_mutex_lock(&begin_mutex);
    begin = true;
    pthread_cond_broadcast(&begin_condition);
    pthread_mutex_unlock(&begin_mutex);

    for (int thread = 0; thread < benchmark_concurrency; ++thread) {
        int result = pthread_join(state[thread].thread, NULL);
        if (result != 0) {
            errno = result;
            perror("pthread_join");
            exit(1);
        }
    }

    uint64_t end = mach_absolute_time();
    benchmark_show_result(start, end);

    return 0;
}

void pwrite_thread(per_file *state) {
    pthread_mutex_lock(&begin_mutex);
    while (!begin)
        pthread_cond_wait(&begin_condition, &begin_mutex);
    pthread_mutex_unlock(&begin_mutex);

    for (int repetition = 0; repetition < benchmark_repetitions; ++repetition) {
        ssize_t written =
            pwrite(state->fd, state->buffer, benchmark_buffer_size,
                   benchmark_offset(repetition));
        if (written == -1) {
            perror("pwrite");
            exit(1);
        }
        assert(written == benchmark_buffer_size);
    }
}
