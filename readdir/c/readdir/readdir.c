#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

#include <mach/mach_time.h>
#include <dirent.h>

int main(int argc, char * argv[]) {
  DIR * dh;
  struct dirent * dirent;
  int sum, trials;
  uint64_t now, later;
  mach_timebase_info_data_t scale;

  if (argc > 1) trials = atoi(argv[1]);
  else trials = 10;

  mach_timebase_info(&scale);

  for (int i = 0; i < trials; i++) {
    sum = 0;

    now = mach_absolute_time();

    dh = opendir("../../bigdir");
    if (dh == NULL) {
      perror("opendir");
      exit(1);
    }

    while (1) {
      errno = 0;
      dirent = readdir(dh);
      if (dirent == NULL) {
        if (errno == 0) {
          if (sum == 4096 || sum == 4098) {
            break;
          } else {
            printf("expected sum=%d but instead got sum=%d\n", 4096, sum);
            exit(1);
          }
        } else {
          perror("readdir");
          exit(1);
        }
      } else {
        sum++;
      }
    }

    closedir(dh);

    later = mach_absolute_time();

    printf("%f\n", ((later - now) * scale.numer) / scale.denom * 1e-6);
  }

  return 0;
}
