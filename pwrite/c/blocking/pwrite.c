#include <assert.h>
#include <fcntl.h>
#include <unistd.h>

#include "../benchmark_osx_pwrite.h"

// Buffers are "deallocated" and fds closed by process exit.
typedef struct {
    char *buffer;
    int fd;
} per_file;

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
    }

    uint64_t start = mach_absolute_time();

    for (int repetition = 0; repetition < benchmark_repetitions; ++repetition) {
        for (int thread = 0; thread < benchmark_concurrency; ++thread) {
            ssize_t written =
                pwrite(state[thread].fd, state[thread].buffer,
                       benchmark_buffer_size, benchmark_offset(repetition));
            if (written == -1) {
                perror("pwrite");
                exit(1);
            }
            assert(written == benchmark_buffer_size);
        }
    }

    uint64_t end = mach_absolute_time();
    benchmark_show_result(start, end);

    return 0;
}
