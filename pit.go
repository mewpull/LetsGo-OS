package main

const (
    PIT_PORT_DATA = 0x40
    PIT_PORT_COMMAND = 0x43
)

func handlePit() {
    PerformSchedule = true
}

func InitPit() {
    Outb(PIT_PORT_DATA, 0x00);		// Low byte
	Outb(PIT_PORT_DATA, 0x01);	// High byte
    RegisterPICHandler(0, handlePit)
    EnableIRQ(0)
}
