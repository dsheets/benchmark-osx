#include <assert.h>
#include <dispatch/dispatch.h>

#include "../benchmark_osx_pwrite.h"

// Buffers are "deallocated" and fds closed by process exit.
typedef struct {
    dispatch_data_t data;
    dispatch_io_t channel;
    int repetition;
} per_file;

int completed = 0;
uint64_t start;

void submit_pwrite_request(per_file *state);

int main(int argc, char **argv) {
    benchmark_parameters(argc, argv);

    per_file *state =
        benchmark_malloc(sizeof(per_file) * benchmark_concurrency);
    for (int thread = 0; thread < benchmark_concurrency; ++thread) {
        char *buffer = benchmark_malloc(benchmark_buffer_size);
        state[thread].data =
            dispatch_data_create(buffer, benchmark_buffer_size, NULL,
                                 DISPATCH_DATA_DESTRUCTOR_FREE);

        // Using an intermediate fd because dispatch_io_create_with_path does
        // not support relative paths.
        int fd =
            open(benchmark_file(thread), O_WRONLY | O_CREAT | O_TRUNC, 0644);
        state[thread].channel =
            dispatch_io_create(DISPATCH_IO_RANDOM, fd,
                               dispatch_get_main_queue(), ^(int errno_) {
                if (errno_ != 0) {
                    errno = errno_;
                    perror("dispatch_io_create");
                    exit(1);
                }
            });

        state[thread].repetition = 0;
    }

    start = mach_absolute_time();

    for (int thread = 0; thread < benchmark_concurrency; ++thread)
        submit_pwrite_request(&state[thread]);

    dispatch_main();

    // This should be unreachable.
    return 0;
}

void submit_pwrite_request(per_file *state) {
    dispatch_io_write(state->channel, benchmark_offset(state->repetition),
                      state->data, dispatch_get_main_queue(),
                      ^(bool done, dispatch_data_t remaining, int errno_) {
        if (errno_ != 0) {
            errno = errno_;
            perror("dispatch_io_write");
            exit(1);
        }
        assert(done);
        assert(remaining == NULL);

        ++state->repetition;
        if (state->repetition < benchmark_repetitions)
            submit_pwrite_request(state);
        else {
            ++completed;
            if (completed >= benchmark_concurrency) {
                uint64_t end = mach_absolute_time();
                benchmark_show_result(start, end);
                exit(0);
            }
        }
    });
}
