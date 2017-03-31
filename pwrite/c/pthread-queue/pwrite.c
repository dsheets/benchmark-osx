#include <assert.h>
#include <fcntl.h>
#include <unistd.h>
#include <pthread.h>

#include "../benchmark_osx_pwrite.h"

// Buffers are "deallocated" and fds closed by process exit.
typedef struct {
    char *buffer;
    int fd;
    int repetition;
    bool busy;
    pthread_t thread;
    pthread_cond_t wake;
} per_file;

void pwrite_thread(per_file *state);
typedef void* (*thread_routine)(void*);

int completed = 0;
pthread_cond_t idle;
pthread_mutex_t queue_mutex;

int main(int argc, char **argv) {
    benchmark_parameters(argc, argv);

    pthread_cond_init(&idle, NULL);
    pthread_mutex_init(&queue_mutex, NULL);

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

        state[thread].repetition = 0;
        state[thread].busy = false;

        int result =
            pthread_create(&state[thread].thread, NULL,
                           (thread_routine)pwrite_thread, &state[thread]);
        if (result != 0) {
            errno = result;
            perror("pthread_create");
            exit(1);
        }

        pthread_cond_init(&state[thread].wake, NULL);
    }

    uint64_t start = mach_absolute_time();

    pthread_mutex_lock(&queue_mutex);
    while (completed < benchmark_concurrency) {
        for (int thread = 0; thread < benchmark_concurrency; ++thread) {
            if (!state[thread].busy) {
                state[thread].busy = true;
                pthread_cond_signal(&state[thread].wake);
            }
        }
        pthread_cond_wait(&idle, &queue_mutex);
    }
    pthread_mutex_unlock(&queue_mutex);

    uint64_t end = mach_absolute_time();
    benchmark_show_result(start, end);

    return 0;
}

void pwrite_thread(per_file *state) {
    pthread_mutex_lock(&queue_mutex);
    while (true) {
        while (!state->busy)
            pthread_cond_wait(&state->wake, &queue_mutex);
        pthread_mutex_unlock(&queue_mutex);

        ssize_t written =
            pwrite(state->fd, state->buffer, benchmark_buffer_size,
                   benchmark_offset(state->repetition));
        if (written == -1) {
            perror("pwrite");
            exit(1);
        }
        assert(written == benchmark_buffer_size);

        ++state->repetition;
        pthread_mutex_lock(&queue_mutex);
        pthread_cond_signal(&idle);
        if (state->repetition < benchmark_repetitions)
            state->busy = false;
        else {
            ++completed;
            pthread_mutex_unlock(&queue_mutex);
            return;
        }
    }
}
