SHELL = command.x
AS = has060 -e -u
ECHO = echo
LK = lk -e 16
RM = del /y

all:	060turbo.sys

clean:
	-$(RM) *.o
	-$(RM) link.txt

060turbo.sys:	t10head.o t11ramdisk.o t12devpat.o t13sysstat.o t14mmu.o \
		t15memory.o t16scsi.o t17hupat.o t18xclib.o t19himem.o \
		t20dosmem.o t21exec.o t22thread.o t23dma.o t25sp.o \
		t27isp.o t28fpsp.o t29float.o t30main.o t31hupat.o \
		t33copyright.o
	$(ECHO) t10head.o t11ramdisk.o t12devpat.o t13sysstat.o t14mmu.o > link.txt
	$(ECHO) t15memory.o t16scsi.o t17hupat.o t18xclib.o t19himem.o >> link.txt
	$(ECHO) t20dosmem.o t21exec.o t22thread.o t23dma.o t25sp.o >> link.txt
	$(ECHO) t27isp.o t28fpsp.o t29float.o t30main.o t31hupat.o >> link.txt
	$(ECHO) t33copyright.o >> link.txt
	$(LK) -i link.txt -o 060turbo.sys

t10head.o: t10head.s t00iocs.equ t01dos.equ t02const.equ
	$(AS) $<

t11ramdisk.o: t11ramdisk.s
	$(AS) $<

t12devpat.o: t12devpat.s t02const.equ t08debug.equ
	$(AS) $<

t13sysstat.o: t13sysstat.s t01dos.equ t02const.equ t08debug.equ t09version.equ
	$(AS) $<

t14mmu.o: t14mmu.s t02const.equ t08debug.equ
	$(AS) $<

t15memory.o: t15memory.s t01dos.equ t02const.equ t08debug.equ
	$(AS) $<

t16scsi.o: t16scsi.s t00iocs.equ t02const.equ t08debug.equ
	$(AS) $<

t17hupat.o: t17hupat.s t00iocs.equ t01dos.equ t02const.equ t08debug.equ
	$(AS) $<

t18xclib.o: t18xclib.s t01dos.equ t02const.equ
	$(AS) $<

t19himem.o: t19himem.s t02const.equ t08debug.equ t09version.equ
	$(AS) $<

t20dosmem.o: t20dosmem.s t01dos.equ t02const.equ t08debug.equ
	$(AS) $<

t21exec.o: t21exec.s t01dos.equ t02const.equ t08debug.equ
	$(AS) $<

t22thread.o: t22thread.s t01dos.equ t02const.equ t03memory.equ t08debug.equ
	$(AS) $<

t23dma.o: t23dma.s t02const.equ t08debug.equ
	$(AS) $<

t25sp.o: t25sp.s t02const.equ
	$(AS) $<

t27isp.o: t27isp.s
	$(AS) $<

t28fpsp.o: t28fpsp.s
	$(AS) $<

t29float.o: t29float.s t02const.equ t06float.equ
	$(AS) $<

t30main.o: t30main.s t00iocs.equ t01dos.equ t02const.equ t08debug.equ t09version.equ
	$(AS) $<

t31hupat.o: t31hupat.s t02const.equ
	$(AS) $<

t33copyright.o: t33copyright.s
	$(AS) $<
