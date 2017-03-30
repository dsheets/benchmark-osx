#include <assert.h>
#include <dispatch/dispatch.h>

#include "../benchmark_osx_pwrite.h"

// Buffers are "deallocated" and fds closed by process exit.
typedef struct {
    char *buffer;
    int fd;
    int repetition;
} per_file;

dispatch_queue_t queue;
int completed = 0;

void submit_pwrite_request(per_file *state);
void pwrite_callback(per_file *state);

int main(int argc, char **argv) {
    benchmark_parameters(argc, argv);

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
    }

    queue = dispatch_queue_create("benchmark", DISPATCH_QUEUE_CONCURRENT);

    uint64_t start = mach_absolute_time();

    for (int thread = 0; thread < benchmark_concurrency; ++thread)
        submit_pwrite_request(&state[thread]);

    // This is not a legitimate way to wait for the work to complete, but it is
    // simple and works.
    while (completed < benchmark_concurrency)
        continue;

    uint64_t end = mach_absolute_time();
    benchmark_show_result(start, end);

    return 0;
}

void submit_pwrite_request(per_file *state) {
    dispatch_async_f(queue, state, (dispatch_function_t)pwrite_callback);
}

void pwrite_callback(per_file *state) {
    ssize_t written =
        pwrite(state->fd, state->buffer, benchmark_buffer_size,
               benchmark_offset(state->repetition));
    if (written == -1) {
        perror("pwrite");
        exit(1);
    }
    assert(written == benchmark_buffer_size);

    ++state->repetition;
    if (state->repetition < benchmark_repetitions)
        submit_pwrite_request(state);
    else
        ++completed;   // Wishing this is atomic.
}
