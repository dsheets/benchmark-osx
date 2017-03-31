#pragma once

#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>

#include <mach/mach_time.h>

size_t benchmark_buffer_size = 4096;
int benchmark_repetitions = 65536;
int benchmark_concurrency = 1;
int benchmark_stride = 1;

int benchmark_parse_integer(const char *s) {
    errno = 0;
    char *end;
    int result = strtol(s, &end, 0);

    if (errno == ERANGE) {
        perror("strtol");
        exit(1);
    }

    if (end == s || *end != '\0') {
        fprintf(stderr, "Failure: strtol\n");
        exit(1);
    }

    return result;
}

const char* benchmark_parameter(int argc, char **argv, int argument_index,
                                const char *environment_variable) {
    if (argc > argument_index)
        return argv[argument_index];
    else
        return getenv(environment_variable);
}

bool benchmark_integer_parameter(int argc, char **argv, int argument_index,
                                 const char *environment_variable,
                                 int *result) {
    const char *value =
        benchmark_parameter(argc, argv, argument_index, environment_variable);
    if (value == NULL)
        return false;

    *result = benchmark_parse_integer(value);
    return true;
}

void benchmark_parameters(int argc, char **argv) {
    int buffer_size;
    bool result =
        benchmark_integer_parameter(argc, argv, 1, "BENCHMARK_BUFFER_SIZE",
                                    &buffer_size);
    if (result)
        benchmark_buffer_size = buffer_size;

    benchmark_integer_parameter(argc, argv, 2, "BENCHMARK_REPETITIONS",
                                &benchmark_repetitions);
    benchmark_integer_parameter(argc, argv, 3, "BENCHMARK_CONCURRENCY",
                                &benchmark_concurrency);

    const char *access_pattern =
        benchmark_parameter(argc, argv, 4, "BENCHMARK_ACCESS_PATTERN");
    if (access_pattern != NULL) {
        if (strcmp(access_pattern, "in-place") == 0)
            benchmark_stride = 0;
    }
}

const char *benchmark_output_directory = "../../scratch_output";

// The benchmarks don't bother deallocating the strings returned from this
// function.
const char* benchmark_file(int n) {
    char *s = malloc(strlen(benchmark_output_directory) + 10);
    sprintf(s, "%s/thread-%i", benchmark_output_directory, n);
    return s;
}

void benchmark_show_result(uint64_t start, uint64_t end) {
    mach_timebase_info_data_t scale;
    mach_timebase_info(&scale);

    double elapsed_ns = (double)(end - start) * scale.numer / scale.denom;
    double bytes =
        benchmark_buffer_size * benchmark_repetitions * benchmark_concurrency;

    double per_byte = elapsed_ns / bytes;
    double per_second = (bytes / 1024 / 1024) / (elapsed_ns / 1e9);

    printf("%9.02f ns/B (%.0f MB/sec)\n", per_byte, per_second);
}

void* benchmark_malloc(size_t size) {
    void *result = malloc(size);
    if (result == NULL) {
        perror("malloc");
        exit(1);
    }
    return result;
}

size_t benchmark_offset(int repetition) {
    return
        (repetition * benchmark_buffer_size * benchmark_stride)
            % (16 * 1024 * 1024);
}
