#ifndef __HUGEPAGEALLOC_H__
#define __HUGEPAGEALLOC_H__

#include <cstdint>

#include <memory.h>
#include <numa.h>
#include <sys/mman.h>

char *getIP();
inline void *hugePageAlloc(size_t size) {
//  numa_set_preferred(0);
//  void *res = mmap(NULL, size, PROT_READ | PROT_WRITE,
//                   MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, -1, 0);
    int ret = 0;
    void *res = nullptr;

    void *ptr;
    ret = posix_memalign(&res, 1 << 21, size);
    if (ret != 0) {
        Debug::notifyError("Posix alignment failed\n");
    }
    madvise(res, size, MADV_HUGEPAGE);
//  if (res == MAP_FAILED) {
//    Debug::notifyError("%s mmap failed!\n", getIP());
//  }
//  numa_set_localalloc();
  return res;
}

#endif /* __HUGEPAGEALLOC_H__ */
