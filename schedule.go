package main

import (
    "unsafe"
)

type domain struct {
    next *domain

    pid uint32
    numThreads uint32
    nextTid uint32

    Segments SegmentList
    MemorySpace MemSpace

    runningThreads threadList
    blockedThreads threadList
}

func (d *domain) AddThread(t *thread) {
    t.domain = d
    d.runningThreads.Enqueue(t)
    t.tid = d.nextTid
    d.nextTid++
    d.numThreads++
}

func (d *domain) RemoveThread(t *thread) {
    if t.domain != d {
        return
    }
    if t.isBlocked {
        d.blockedThreads.Dequeue(t)
    } else {
        d.runningThreads.Dequeue(t)
    }
    t.isRemoved = true
    d.numThreads--
}

type thread struct {
    next *thread
    prev *thread

    domain *domain
    tid uint32
    StackStart uintptr

    isRemoved bool
    // Currently ignored '^^ I don't have to do it thanks to spurious wakeups
    isBlocked bool
    waitAddress *uint32

    // Infos to stall a thread when switching
    info InterruptInfo
    regs RegisterState

    // TLS
    tlsSegments [GDT_ENTRIES]GdtEntry

    // fxsave and fxrstor need 512 bytes but 16 byte aligned
    // need space to force alignment if array not aligned
    fpOffset uintptr // should be between 0-15
    fpState [512+16]byte
}

type threadList struct {
    thread *thread
}

func (l *threadList) Next() *thread {
    if l.thread == nil {
        return nil
    }
    l.thread = l.thread.next
    return l.thread
}

func (l *threadList) Enqueue(t *thread) {
    if l.thread == nil {
        l.thread = t
        t.next = t
        t.prev = t
    } else {
        t.next = l.thread
        t.prev = l.thread.prev
        l.thread.prev.next = t
        l.thread.prev = t
    }
}

func (l *threadList) Dequeue(t *thread) {
    if t == l.thread && t.next == t {
        l.thread = nil
    }
    t.prev.next = t.next
    t.next.prev = t.prev
}

type domainList struct {
    head *domain
    tail *domain
}

func (l *domainList) Append(domain *domain) {
    if domain == nil {
        return
    }
    if l.head == nil {
        l.head = domain
        l.tail = l.head
        l.head.next = l.tail
    } else {
        domain.next = l.head
        l.tail.next = domain
        l.tail = domain
    }
    domain.pid = largestPid
    largestPid++
}

func (l *domainList) Remove(d *domain) {
    if d == l.head {
        if d == l.tail {
            l.head = nil
            l.tail = nil
        } else {
            l.head = d.next
            l.tail.next = l.head
        }
        return
    }
    for e := l.head; e.next != l.head; e = e.next {
        if e.next == d {
            e.next = d.next
            if d == l.tail {
                l.tail = e
            }
            break
        }
    }
}

var (
    currentThread *thread = nil
    currentDomain *domain = nil
    allDomains domainList = domainList{head:nil, tail: nil}
    largestPid uint32 = 0x0
)

func backupFpRegs(buffer uintptr)
func restoreFpRegs(buffer uintptr)


func AddDomain(d *domain) {
    allDomains.Append(d)
    if currentDomain == nil || currentThread == nil {
        currentDomain = allDomains.head
        currentThread = currentDomain.runningThreads.thread
    }
}

func ExitDomain(d *domain) {
    allDomains.Remove(d)

    if allDomains.head == nil {
        currentDomain = nil
    }
    // TODO: Do I have to test for the current Thread?
}

func ExitThread(t *thread) {
    t.domain.RemoveThread(t)
    if t.domain.numThreads <= 0 {
        ExitDomain(t.domain)
    }
}

func BlockThread(t *thread) {
    t.isBlocked = true
    t.domain.runningThreads.Dequeue(t)
    t.domain.blockedThreads.Enqueue(t)
}

func Schedule() {
    // TODO: Currently assumes it is called after every syscall
    if currentDomain == nil {
        kernelPanic("No Domains to schedule")
    }
    nextDomain := currentDomain.next
    newThread := nextDomain.runningThreads.Next()
    if newThread == nil {
        for newDomain := nextDomain.next; newDomain != nextDomain; newDomain = newDomain.next {
            newThread = newDomain.runningThreads.Next()
            if newThread != nil {
                break
            }
            kernelPanic("debug")
        }
    }
    //text_mode_print("next domain: ")
    //text_mode_print_hex32(nextDomain.pid)
    //text_mode_println("")
    //l := allDomains //l  for lazy
    //for a := l.head; a != l.tail; a = a.next {
    //    text_mode_print_hex32(a.pid)
    //    text_mode_print(" ")
    //}
    //text_mode_print_hex32(l.tail.pid)
    //text_mode_println("")

    if newThread == nil {
        // All threads blocked or no threads exist anymore.
        Hlt()
        kernelPanic("TODO: What do I do here?")
    }
    currentDomain = nextDomain
    if newThread == currentThread {
        return
    }

    switchToThread(newThread)

}

func switchToThread(t *thread) {
    // Save state of current thread
    addr := uintptr(unsafe.Pointer(&(currentThread.fpState)))
    offset := 16 - (addr % 16)
    currentThread.fpOffset = offset

    backupFpRegs(addr + offset)

    // Load next thread

    currentThread = t

    addr = uintptr(unsafe.Pointer(&(currentThread.fpState)))
    offset = currentThread.fpOffset
    if offset != 0xffffffff {
        if (addr + offset) % 16 != 0 {
            text_mode_print_hex32(uint32(addr))
            text_mode_print(" ")
            text_mode_print_hex32(uint32(offset))
            kernelPanic("Cannot restore FP state. Not aligned. Did array move?")
        }
        restoreFpRegs(addr + offset)
    }

    // Load TLS
    FlushTlsTable(t.tlsSegments[:])
}

func InitScheduling() {

}
