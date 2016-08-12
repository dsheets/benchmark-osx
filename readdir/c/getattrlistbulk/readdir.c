#include <sys/attr.h>
#include <sys/vnode.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <mach/mach_time.h>

typedef struct val_attrs {
  uint32_t length;
  attribute_set_t returned;
  uint32_t error;
  attrreference_t name_info;
  char * name;
  fsobj_type_t obj_type;
  uint64_t file_id;
} val_attrs_t;

double list(const char * path) {
  int dirfd;
  int sum = 0;
  struct attrlist attr_list;
  char attr_buf[4096];
  char * entry_start;
  uint64_t now, later;
  mach_timebase_info_data_t scale;

  mach_timebase_info(&scale);

  now = mach_absolute_time();

  attr_list.bitmapcount = ATTR_BIT_MAP_COUNT;
  attr_list.commonattr =
    ATTR_CMN_RETURNED_ATTRS |
    ATTR_CMN_NAME |
    ATTR_CMN_ERROR |
    ATTR_CMN_OBJTYPE |
    ATTR_CMN_FILEID;

  dirfd = open(path, O_RDONLY, 0);
  if (dirfd < 0) {
    perror("open");
    exit(1);
  }

  for (;;) {
    int retcount;

    retcount = getattrlistbulk(dirfd, &attr_list, &attr_buf[0],
                               sizeof(attr_buf), 0);
    if (retcount < 0) {
      perror("getattrlistbulk");
      exit(1);
    } else if (retcount == 0) break;
    else {
      int index;
      uint32_t total_length;
      char * field;

      entry_start = &attr_buf[0];
      total_length = 0;
      for (index = 0; index < retcount; index++) {
        val_attrs_t attrs = {0};

        sum++;

        field = entry_start;
        attrs.length = *(uint32_t *)field;
        total_length += attrs.length;
        field += sizeof(uint32_t);

        entry_start += attrs.length;

        attrs.returned = *(attribute_set_t *)field;
        field += sizeof(attribute_set_t);

        if (attrs.returned.commonattr & ATTR_CMN_ERROR) {
          attrs.error = *(uint32_t *)field;
          field += sizeof(uint32_t);
        }

        if (attrs.returned.commonattr & ATTR_CMN_NAME) {
          attrs.name = field;
          attrs.name_info = *(attrreference_t *)field;
          field += sizeof(attrreference_t);
        }

        if (attrs.error) continue;

        if (attrs.returned.commonattr & ATTR_CMN_OBJTYPE) {
          attrs.obj_type = *(fsobj_type_t *)field;
          field += sizeof(fsobj_type_t);
        }

        if (attrs.returned.commonattr & ATTR_CMN_FILEID) {
          attrs.file_id = *(uint64_t *)field;
          field += sizeof(uint64_t);
        }
      }
    }
  }

  close(dirfd);

  later = mach_absolute_time();

  if (sum != 4096 && sum != 4098) {
    printf("expected sum=%d but instead got sum=%d\n", 4096, sum);
    exit(1);
  }

  return ((later - now) * scale.numer) / scale.denom * 1e-6;
}

int main() {
  for (int i = 0; i < 10; i++) {
    printf("%f\n", list("../../bigdir"));
  }

  return 0;
}
