#include <assert.h>
#include <uv.h>

#include "../benchmark_osx_pwrite.h"

// Buffers are "deallocated" and fds closed by process exit.
typedef struct {
    uv_buf_t buffer;
    uv_file fd;
    uv_fs_t request;
    int repetition;
} per_file;

void submit_pwrite_request(uv_fs_t *request);
void pwrite_callback(uv_fs_t *request);

int main(int argc, char **argv) {
    benchmark_parameters(argc, argv);

    setenv("UV_THREADPOOL_SIZE", "128", 0);

    per_file *state =
        benchmark_malloc(sizeof(per_file) * benchmark_concurrency);
    for (int thread = 0; thread < benchmark_concurrency; ++thread) {
        state[thread].buffer.base = benchmark_malloc(benchmark_buffer_size);
        state[thread].buffer.len = benchmark_buffer_size;

        uv_fs_t open_request;
        state[thread].fd =
            uv_fs_open(NULL, &open_request, benchmark_file(thread),
                       O_WRONLY | O_CREAT | O_TRUNC, 0644, NULL);
        if (state[thread].fd < 0) {
            fprintf(stderr, "Failed: uv_fs_open: %s\n",
                    uv_strerror(state[thread].fd));
            exit(1);
        }
        uv_fs_req_cleanup(&open_request);

        state[thread].request.data = &state[thread];
        state[thread].repetition = 0;
    }

    uint64_t start = mach_absolute_time();

    for (int thread = 0; thread < benchmark_concurrency; ++thread)
        submit_pwrite_request(&state[thread].request);
    uv_run(uv_default_loop(), UV_RUN_DEFAULT);

    uint64_t end = mach_absolute_time();
    benchmark_show_result(start, end);

    return 0;
}

void submit_pwrite_request(uv_fs_t *request) {
    per_file *state = (per_file*)request->data;

    int result =
        uv_fs_write(uv_default_loop(), request, state->fd, &state->buffer, 1,
                    benchmark_offset(state->repetition), pwrite_callback);
    if (result != 0) {
        // If the result is not zero, the request was not submitted.
        fprintf(stderr, "Failed: uv_fs_write: %s\n", uv_strerror(result));
        exit(1);
    }
}

void pwrite_callback(uv_fs_t *request) {
    if (request->result < 0) {
        fprintf(stderr, "Failed: uv_fs_write: %s\n",
                uv_strerror(request->result));
        exit(1);
    }
    assert(request->result == benchmark_buffer_size);

    uv_fs_req_cleanup(request);

    per_file *state = (per_file*)request->data;

    ++state->repetition;
    if (state->repetition < benchmark_repetitions)
        submit_pwrite_request(request);
}
