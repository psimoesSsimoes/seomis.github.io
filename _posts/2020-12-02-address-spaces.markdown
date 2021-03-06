---
layout: post
title:  An Overview of Virtual Memory, Part 1.
date: 2020-12-09 09:00:00 +0300
description: Notes on virtual memory. # Add post description (optional)
img: addressspace.png # Add image post (optional)
tags: [OS,Memory,Virtual Memory, Address Spaces, Segmentation, Paging] # add tag
---


**Curiosity is a strange thing**. 
This week i was puzzled by some behaviour of golang memory management. Naturally, i looked up go 1.15 runtime files and as i was reading the Golang Memory allocator( https://github.com/golang/go/blob/release-branch.go1.15/src/runtime/malloc.go ), i had a **realization**: Even thought i interacted with an OS every day, I could not remember **how/what techiques** were employed by the OS to support *memory virtualization* and the intricate details about how the hardware and the OS were interacting. And without it, i would not be able to interpret correctly the source code i was reading.

 With a sense of urgency, i went to the basement searching for my old OS book  hoping i could obtain some answers about Memory Virtualization. ( marvoulous book called **Three Easy Pieces** http://pages.cs.wisc.edu/~remzi/OSTEP/ which i definitely recomend)
 
 This was what i found: 

### If you are using a modern OS, every address generated by a user program is a virtual address.

The OS is just providing an illusion to each process that it has its own large and private memory. With some hardware help, the OS will turn these pretend virtual addresses into real physical addresses and thus is able to locate the desired information.

### Why would we want the OS to provide this illusion?

Mostly ease of use. As a programmer, i never have to worry about things like "*where do i need to store this variable*", because the virtual address space of the program is large and has lots of room for that sort of thing. I could see this being a huge advantage... i definitely don't want to think about difficult problems such as implementing **time sharing** efficiently when i write my code.
Another important factor is **protection**. The OS should make sure to protect processes from one another as well as the OS itself from processes. When one process performs a load, store or an instruction fetch, it should not be able to access or affect in any way the memory contents of another process or the OS itself. Protection enables the **property of isolation** among processes, which again, are details that i would feel safer delegating to another program.

### Hence Address Space.

The address space of a process contains all memory state of each process. I generally think of it as being composed by code ( the instructions of a program ), stack ( to keep track of where it is in the function call chain as well as allocate local variables and pass parameters to and from routines ) and the heap ( used for dynamically-allocated, user managed memory ). 

I knew the stack and the heap were structured in different ways. The stack stores values **in the order it gets them** and removes the values in **opposite order (LIFO)**. All data stored on the stack must have a **known fixed size**. The heap is less organized: when we put data on the heap, **we request a certain amount of space on the heap and receive a pointer which is stored on the stack(**has a fixed, known size). From this notion, it becomes clear that accessing and storing on the stack is faster than on the heap. 

### Address Translation

To use this illusion we'll need some sort of **address translation**, where the virtual address provided by the instruction is changed into a physical address where the desired information is actually located.

One particular form of virtualization is **dynamic relocation** ( also known as base-and-bounds ). Using two hardware registers within the CPU ( **base register and limit/bounds register** ) we are allowed to place the address space anywhere we'd like in physical memory while ensuring that the process only access its own address space.
With this approach, when a process is running, any memory reference generated is translated in the following manner:

 - physical address = virtual address + base

 bounds register is there to help with protection, i.e, the processor will check that the memory reference is within bounds to make sure it is legal. This part of the processor that helps with translation is called MMU (memory management unit).

---
### Strategies for space-management problem : Segmentation

 Dynamic allocation does have inefficiencies. When a process allocates memory, and the stack and heap are not too big, all the space between them is simply wasted. We call this type of waste, **internal fragmentation**.

 In attempt to solve this problem, an idea of **Segmentation** was born. In theory the idea is simple: instead of having just one base and bounds pair in the MMU, why not have a base and bound pair per logical segment of the address space.

 Lets see an example of how this could be implemented.

 Imagine that we have the following address space:

 -- image

 with the following physical memory:

 -- image

 On the MMU, you would have the following segment register values:

    Segment  Base    Size
    Code     32K     2K
    Heap     34K     2K
    Stack    28K     2K

 Now lets do an example translation. Assume a reference is made to virtual address 4200 (heap segment). By adding virtual address 4200 to the base register of the heap (34K) we get the physical address 39016. With segments we need to first extract the offset into the heap, i.e, which byte/s in this segment the address refers to. As the heap starts at 4K (4096), the offset is actually 4200-4096=104. When we add it to the base register we get the desired result: 34K + 104 = 34920.

The stack would use the same logic but with one critical difference: it grows backwards.

The hardware needs therefore to understand that segments can grow in negative and positive directions, and perform translation in a slightly different manner. It will use a bit to know if a segment grows in positive or negative direction( 1 for positive, 0 for negative ).

An updated view of segment register values could be thought as:

    Segment  Base    Size   Grows Positive
    Code     32K     2K     1
    Heap     34K     2K     1
    Stack    28K     2K     0


Let's imagine now we wanted to access virtual address 15K (mapped to physical address 27K). Our virtual address in binary is 11 1100 0000 0000 (hex 0x3C00). The hardware uses the top two bits to designate the segment and the rest (3K) as offset. To obtain the correct negative offset, we must subtract the maximum segment size from 3K. In a case of maximum segment 4K this is equivalent to 3K-4K = -1K. If we add this value to base, we arrive to the correct physical address 27K.

 What would happen if we referred to an illegal address such as 7K? the hardware detects that the address is out of bounds, traps the OS, which will likely origin the infamous segmentation violation or segmentation fault.

Segmentation provides huge savings of physical memory but it also **raises new issues**:

 - OS on a context switch must be able to save and restore segment registers. It must make sure to set up these registers correctly before letting the process run again.
 - OS must manage free space in physical memory. When a new address space is created, the OS has to be able to find space in physical memory for its segments. The general problem that arises is that physical memory quickly becomes full of little holes of free space, making it difficult to allocate new segments or grow existing ones. This is generally referred as **external fragmentation**.

----
### Strategies for space-management problem : Paging.

Other approach is called **Paging**, which consists in dividing process's address space into fixed-sized units, each of which we call a page. Correspondingly, we view physical memory as an array of fixed-sized slots called **page frames**, each of these frames containing a single virtual-memory page. This approach has many advantages over segmentation, as it does not lead to external fragmentation, and it is quite flexible as it enables sparse use of virtual address spaces.

Let's see a simple example to help make this approach clearer. 

Imagine you have a an address space of 64 bytes total size, divided into 4 16-byte pages (0,1,2,3)

-- image -- 

and physical memory consisting of 128-bytes divided in 8 page frames

-- image --

Using this approach, to record where each virtual page of the address space is placed in physical memory, the OS usually keeps a per-process data struct called page table, which stores address translations for each of the virtual pages of the address space.

So for this example the page table would have the following entries:

    VP-0 -> PF-3
    VP-1 -> PF-7
    VP-2 -> PF-5
    VP-3 -> PF-2

to perform a translation of a virtual address a process has generated, we have to split the address into two components:
**Virtual Page Number (VPN)** and **Offset (within the page)**.

Because we are working with a address space of 64bytes, we need 6 bits for our virtual address (2^6 =64)
--image--

Now lets assume the load of a register to virtual address 21:

    mov 21 %eax
    
21 in binary form is:

    01 0101
    
so VPN is 01 refers us to page VP-1, and 0101 offset tells us that the address is on the 5th byte of this page.
Indexing the VPN in our page table, refers us to PFN (physical frame number) 7. Thus we can translate this virtual address into a physical address by replacing VPN with the PFN and maintaining the offset. The physical memory resides in:

    111 0101
 
 Now this approach also raises some questions: Where are the page table of each process **stored**? What are the **contents of each page table** and **how big** are the tables? How do we know where the page-table of the **current running process is located**? **Isn't it slow** to find the correct page-table for the process? Doesn't paging induce **memory waste** as memory gets filled with page tables for processes instead of useful application data? Won't paging lead to a **slower machine** as we have to perform **many extra memory accesses** to access the page table?

### x86 Page Table Entry

--- image

I started with looking up x86 **page table entry**, which i thought would provide useful information about the page table organization. The page table is really just a data structure that is used to map virtual addresses into physical addresses, thus in my head, any data structure could work.
As for the contents of each **PTE**, we have some bits worth understanding at some level:

- **valid bit :**
- **protections bits:**
- **dirty bit:**
- **reference bit:**
- **page frame number bits:**



<!-- /* This blog was originally posted on [Medium](https://medium.com/@seomisw/image-dataset-for-litter-detection-7f1cab9e7fa1){:target="_blank"}--be sure to follow and clap! */ -->
