;========================================================================================
;  optime.s
;  Copyright (C) 2003-2023 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	optime.x
;		���ߗ�̎��s���Ԃ��v�����܂��B
;
;	�ŏI�X�V
;		2023-09-17
;
;	����
;		has060 -i include -o optime.o -w optime.s
;		lk -o optime.x optime.o
;
;	�g����
;		-a �A�Z���u��
;			�A�Z���u�����w�肵�܂��B
;			�w�肪�Ȃ����has060���g���܂��B
;		-f �t�@�C����
;			���s���Ԃ��v�����������ߗ���������t�@�C�����w�肵�܂��B
;			���s�Ŗ��߂���؂�܂��B
;		-i "���ߗ�"
;			���s���Ԃ��v�����������ߗ��"�`"�ň͂�Ŏw�肵�܂��B
;			�Z�~�R�����Ŗ��߂���؂�܂��B
;			���߂��Ӗ�����Z�~�R�����͏����܂���B
;		-s
;			���ߗ��SRAM�ɏ�������Ōv�����܂��B
;			DRAM�̃��t���b�V���ɂ��덷���o�ɂ����Ȃ�܂��B
;			X68000�ł�1���[�h������1�T�C�N���̃E�F�C�g���ǉ�����܂��B
;			SRAM���g�p���̂Ƃ��v�����邩�₢���킹�܂��B
;		-sn
;			-s�Ɠ��l�ł���SRAM���g�p���̂Ƃ��͌v�����܂���B
;		-sy
;			-s�Ɠ��l�ł���SRAM���g�p���̂Ƃ����v�����܂��B
;		-t �f�B���N�g����
;			�e���|�����f�B���N�g�����w�肵�܂��B
;			�w�肪�Ȃ���Ί��ϐ�temp��ǂݏo���܂��B
;			���ϐ�temp���Ȃ���΃J�����g�f�B���N�g�����g���܂��B
;		-v
;			�璷�ɏo�͂��܂��B
;		���ߗ�
;			�������v���ł�����s���Ԃ̏����12.799ms�ł��B
;			���ߗ�̒����̏����32766�o�C�g�ł��B
;			�Z�N�V�����̕ύX�͂ł��܂���B
;			���򖽗߂������܂����o���͖��ߗ�̖����ɂȂ���΂Ȃ�܂���B
;			d7/a5-a7��ύX����Ƃ��͕ۑ��ƕ������s���Ă��������B
;			-268(a5)�`-1(a5)��268�o�C�g�͓ǂݏ������R�̋󂫗̈�ł��B
;			���ߗ�̓X�[�p�[�o�C�U���[�h�ŌĂяo����܂��B
;			���ߗ�͊��荞�݂��֎~���ꂽ��ԂŌĂяo����܂��B
;
;	�X�V����
;		2023-01-19
;			���J�B
;		2023-01-21
;			-v�̂Ƃ��^�C�g���ƃo�[�W������\������B
;			�G���[���b�Z�[�W�̕\���ɕW���G���[�o�͂��g��Ȃ��B
;			�e���|�����f�B���N�g�����̖�����':'�̂Ƃ�'\'��ǉ����Ȃ��B
;			�A�Z���u���̃p�����[�^��-w���w�肵�Čx����}������B
;			�A�Z���u���̃��b�Z�[�W���B���Ȃ��B
;			-v�̂Ƃ��A�Z���u���̏I���R�[�h��\������B
;		2023-09-17
;			"�`"�܂���'�`'�����Ă��Ȃ��Ɣ������o��o�O���C���B
;
;----------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sram.equ

TITLE_STRING	reg	'optime.x (2023-09-17)'

ERROR_OUTPUT	equ	0		;1=�G���[���b�Z�[�W�̕\���ɕW���G���[�o�͂��g��
WARNING_OPTION	equ	1		;1=�A�Z���u���̃p�����[�^��-w���w�肵�Čx����}������
HIDE_ASSEMBLER	equ	0		;1=�A�Z���u���̃��b�Z�[�W���B��

	.text

;----------------------------------------------------------------
;�v���O�����J�n
program_start::

;----------------------------------------------------------------
;�X�^�b�N�G���A��ݒ肷��
	lea.l	stack_area_end,sp	;�X�^�b�N�G���A�̖���

	.stack
	.even
		.ds.b	65536		;�X�^�b�N�G���A
stack_area_end::
	.text

;----------------------------------------------------------------
;�������u���b�N��Z������
;	�q�v���Z�X���N�����邽��
;	*.r�`���͔�Ή�
;<a0.l:�������Ǘ��|�C���^
;<a1.l:�g�p�����̖���
	lea.l	16(a0),a0		;�������u���b�N�̐擪
	suba.l	a0,a1			;�g�p�����̒���
	move.l	a1,-(sp)
	move.l	a0,-(sp)
	DOS	_SETBLOCK
	addq.l	#8,sp

;----------------------------------------------------------------
;�I�v�V�������m�F����
;<a2.l:�R�}���h���C���BLASCIIZ
	clr.b	assembler_arg		;-a �A�Z���u��
	clr.b	file_arg		;-f �t�@�C����
	clr.b	inst_arg		;-i ���ߗ�
	clr.b	sram_flag		;-s SRAM�t���O�B1=-s,2=-sn,3=-sy
	clr.b	temp_arg		;-t �f�B���N�g����
	clr.b	verbose_flag		;-v �璷�t���O
	lea.l	1(a2),a1
	dostart
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,usage_exit	;-,/�ȊO
		addq.l	#1,a1
		move.b	(a1)+,d0
		goto	eq,usage_exit		;-,/�̌�ɕ������Ȃ�
		bsr	tolower
		if	<cmp.b #'a',d0>,eq	;-a
			lea.l	assembler_arg,a0	;-a �A�Z���u��
			bsr	argcpy
			goto	eq,usage_exit		;-a�̌�ɕ������Ȃ�
		elif	<cmp.b #'f',d0>,eq	;-f
			lea.l	file_arg,a0		;-f �t�@�C����
			bsr	argcpy
			goto	eq,usage_exit		;-f�̌�ɕ������Ȃ�
		elif	<cmp.b #'i',d0>,eq	;-i
			lea.l	inst_arg,a0		;-i ���ߗ�
			bsr	argcpy
			goto	eq,usage_exit		;-i�̌�ɕ������Ȃ�
		elif	<cmp.b #'s',d0>,eq
			move.b	(a1)+,d0
			bsr	tolower
			if	<cmpi.b #'n',d0>,eq	;-sn
				move.b	#2,sram_flag		;-s SRAM�t���O�B1=-s,2=-sn,3=-sy
			elif	<cmpi.b #'y',d0>,eq	;-sy
				move.b	#3,sram_flag		;-s SRAM�t���O�B1=-s,2=-sn,3=-sy
			else
				subq.l	#1,a1
				move.b	#1,sram_flag		;-s SRAM�t���O�B1=-s,2=-sn,3=-sy
			endif
		elif	<cmp.b #'t',d0>,eq	;-t
			lea.l	temp_arg,a0		;-t �f�B���N�g����
			bsr	argcpy
			goto	eq,usage_exit		;-t�̌�ɕ������Ȃ�
		elif	<cmp.b #'v',d0>,eq	;-v
			st.b	verbose_flag		;-v �璷�t���O
		else				;���̑�
			goto	usage_exit
		endif
	start
		exg.l	a0,a1
		bsr	nonspace
		exg.l	a0,a1
	while	ne
	gotoand	<tst.b file_arg>,eq,<tst.b inst_arg>,eq,usage_exit	;-f��-i�������Ȃ�
	gotoand	<tst.b file_arg>,ne,<tst.b inst_arg>,ne,usage_exit	;-f��-i����������
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'> optime.x',a1
		bsr	strcpy
		if	<tst.b assembler_arg>,ne
			leastrdata	' -a ',a1
			bsr	strcpy
			lea.l	assembler_arg,a1	;-a �A�Z���u��
			bsr	strcpy
		endif
		if	<tst.b file_arg>,ne
			leastrdata	' -f ',a1
			bsr	strcpy
			lea.l	file_arg,a1		;-f �t�@�C����
			bsr	strcpy
		endif
		if	<tst.b inst_arg>,ne
			leastrdata	' -i ',a1
			bsr	strcpy
			move.b	#'"',(a0)+
			lea.l	inst_arg,a1		;-i ���ߗ�
			bsr	strcpy
			move.b	#'"',(a0)+
		endif
		if	<tst.b sram_flag>,ne
			if	<cmpi.b #2,sram_flag>,lo	;-s SRAM�t���O
				leastrdata	' -s',a1
			elif	eq
				leastrdata	' -sn',a1
			else
				leastrdata	' -sy',a1
			endif
			bsr	strcpy
		endif
		if	<tst.b temp_arg>,ne
			leastrdata	' -t ',a1
			bsr	strcpy
			lea.l	temp_arg,a1		;-t �f�B���N�g����
			bsr	strcpy
		endif
	;	if	<tst.b verbose_flag>,ne
			leastrdata	' -v',a1
			bsr	strcpy
	;	endif
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
		bsr	print
	endif

	.bss
assembler_arg::
	.ds.b	1024			;-a �A�Z���u��
file_arg::
	.ds.b	1024			;-f �t�@�C����
inst_arg::
	.ds.b	1024			;-i ���ߗ�
sram_flag::
	.ds.b	1			;-s SRAM�t���O
temp_arg::
	.ds.b	1024			;-t �f�B���N�g����
verbose_flag::
	.ds.b	1			;-v �璷�t���O
string_buffer::
	.ds.b	4096			;������o�b�t�@
	.text

;----------------------------------------------------------------
;���ߗ���\�[�X�R�[�h�ɕϊ�����
	if	<tst.b inst_arg>,ne
		lea.l	inst_arg,a1		;-i ���ߗ�
		lea.l	source_code,a0		;�\�[�X�R�[�h
		dostart
			if	<cmpi.b #'@',(a1)>,ne
				move.b	#9,(a0)+
			endif
			docontinue
				move.b	(a1)+,(a0)+
			whileand	<tst.b (a1)>,ne,<cmpi.b #';',(a1)>,ne
			move.b	#13,(a0)+
			move.b	#10,(a0)+
		start
			docontinue
				addq.l	#1,a1
			whileor	<cmpi.b #' ',(a1)>,eq,<cmpi.b #9,(a1)>,eq,<cmpi.b #';',(a1)>,eq
		while	<tst.b (a1)>,ne
		clr.b	(a0)
		if	<tst.b verbose_flag>,ne
			leastrdata	<'source code:',13,10>,a0
			bsr	print
			lea.l	source_code,a0		;�\�[�X�R�[�h
			bsr	print
		endif
	endif

	.bss
source_code::
	.ds.b	1024			;�\�[�X�R�[�h
	.text

;----------------------------------------------------------------
;�e���|�����f�B���N�g�������擾����
;	������':'��'/'��'\'�̂�����ł��Ȃ��Ƃ�'\'��ǉ�����
;	'.'��2�o�C�g������2�o�C�g�ڂłȂ����Ƃ̊m�F�͏ȗ�����
	if	<tst.b temp_arg>,ne
		lea.l	temp_directory,a0	;�e���|�����f�B���N�g����
		lea.l	temp_arg,a1		;-t �f�B���N�g����
		bsr	strcpy
	else
		clr.b	temp_directory		;�e���|�����f�B���N�g����
		pea.l	temp_directory		;�e���|�����f�B���N�g����
		clr.l	-(sp)
		peastrdata	'temp'		;���ϐ�temp��ǂݏo��
		DOS	_GETENV
		lea.l	12(sp),sp
	endif
	lea.l	temp_directory,a0	;�e���|�����f�B���N�g����
	if	<tst.b (a0)>,ne
		bsr	strchr0
		ifand	<cmpi.b #':',-1(a0)>,ne,<cmpi.b #'/',-1(a0)>,ne,<cmpi.b #'\',-1(a0)>,ne
			move.b	#'\',(a0)+
			clr.b	(a0)
		endif
	endif
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'temporary directory: ',a1
		bsr	strcpy
		lea.l	temp_directory,a1	;�e���|�����f�B���N�g����
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
		bsr	print
	endif

	.bss
temp_directory::
	.ds.b	1024			;�e���|�����f�B���N�g����
	.text

;----------------------------------------------------------------
;�X�[�p�[�o�C�U���[�h�ֈڍs����
	supervisormode

;----------------------------------------------------------------
;ssp��usp��ۑ�����
	move.l	sp,saved_ssp		;�ۑ����ꂽssp
	move.l	usp,a0
	move.l	a0,saved_usp		;�ۑ����ꂽusp

	.data
	.even
saved_ssp::
	.dc.l	0			;�ۑ����ꂽssp
saved_usp::
	.dc.l	0			;�ۑ����ꂽusp
	.text

;----------------------------------------------------------------
;�A�{�[�g�x�N�^��ۑ�����
	move.w	#_CTRLVC,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	move.l	d0,saved_ctrlvc		;�ۑ����ꂽ_CTRLVC
	move.w	#_ERRJVC,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	move.l	d0,saved_errjvc		;�ۑ����ꂽ_ERRJVC

	.data
	.even
saved_ctrlvc::
	.dc.l	0			;�ۑ����ꂽ_CTRLVC
saved_errjvc::
	.dc.l	0			;�ۑ����ꂽ_ERRJVC
	.text

;----------------------------------------------------------------
;�A�{�[�g�x�N�^��ύX����
	pea.l	abort			;���~
	move.w	#_CTRLVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	pea.l	abort			;���~
	move.w	#_ERRJVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp

;----------------------------------------------------------------
;SRAM�̎g�p��Ԃ��m�F����
	if	<tst.b sram_flag>,ne
		if	<tst.b SRAM_SRAM_USAGE>,ne
			if	<cmp.b #2,sram_flag>,lo
				leastrdata	'SRAM in use. Continue? (y/n) ',a0
				bsr	yesno
			elif	eq
				moveq.l	#'n',d0
			else
				moveq.l	#'y',d0
			endif
			goto	<cmp.b #'y',d0>,ne,abort	;���~
		endif
	endif

;----------------------------------------------------------------
;�\�[�X�t�@�C�������
	bsr	create_source		;�\�[�X�t�@�C�������

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C���������
;	�\�[�X�t�@�C�����̐擪�������Ō��'.'�̈ʒu�Ȃ���Ζ�����'.o'������
;	'.'��2�o�C�g������2�o�C�g�ڂłȂ����Ƃ̊m�F�͏ȗ�����
	lea.l	object_file,a0		;�I�u�W�F�N�g�t�@�C����
	lea.l	source_file,a1		;�\�[�X�t�@�C����
	bsr	strcpy
	movea.l	a0,a2			;����
	lea.l	object_file,a1		;�擪
	dostart
		if	<cmpi.b #'.',(a0)>,eq
			movea.l	a0,a2			;�Ō��'.'�̈ʒu
			break
		endif
	start
		subq.l	#1,a0
	while	<cmpa.l a1,a0>,hi	;�擪������
	move.b	#'.',(a2)+
	move.b	#'o',(a2)+
	clr.b	(a2)
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'object file: ',a1
		bsr	strcpy
		lea.l	object_file,a1		;�I�u�W�F�N�g�t�@�C����
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
		bsr	print
	endif

	.bss
object_file::
	.ds.b	1024			;�I�u�W�F�N�g�t�@�C����
	.text

;----------------------------------------------------------------
;�R�}���h���C�������
	lea.l	command_line,a0		;�R�}���h���C���A�R�}���h
	lea.l	assembler_arg,a1	;�A�Z���u��
	if	<tst.b (a1)>,eq
		leastrdata	'has060',a1
	endif
	bsr	strcpy
  .if WARNING_OPTION
	leastrdata	' -w -o ',a1
  .else
	leastrdata	' -o ',a1
  .endif
	bsr	strcpy
	lea.l	object_file,a1		;�I�u�W�F�N�g�t�@�C����
	bsr	strcpy
	move.b	#' ',(a0)+
	lea.l	source_file,a1		;�\�[�X�t�@�C����
	bsr	strcpy
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'command line: ',a1
		bsr	strcpy
		lea.l	command_line,a1		;�R�}���h���C���A�R�}���h
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
		bsr	print
	endif

	.bss
command_line::
	.ds.b	1024			;�R�}���h���C���A�R�}���h
	.text

;----------------------------------------------------------------
;�R�}���h���C�����R�}���h�ƈ����ɕ�����
	clr.l	-(sp)
	pea.l	command_args		;����
	pea.l	command_line		;�R�}���h���C���A�R�}���h
	move.w	#2,-(sp)
	DOS	_EXEC
	lea.l	14(sp),sp
	if	<tst.l d0>,mi
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'cannot find ',a1
		bsr	strcpy
		lea.l	command_line,a1		;�R�}���h���C���A�R�}���h
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
  .if ERROR_OUTPUT
		bsr	eprint
  .else
		bsr	print
  .endif
		goto	abort			;���~
	endif
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'command: ',a1
		bsr	strcpy
		lea.l	command_line,a1		;�R�}���h���C���A�R�}���h
		bsr	strcpy
		bsr	crlf
		leastrdata	'arguments: ',a1
		bsr	strcpy
		lea.l	command_args+1,a1	;����
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
		bsr	print
	endif

	.bss
command_args::
	.ds.b	1024			;����
	.text

  .if HIDE_ASSEMBLER

;----------------------------------------------------------------
;NUL���J��
	bsr	open_nul		;NUL���J��

;----------------------------------------------------------------
;�W���n���h����ۑ�����
	bsr	save_std		;�W���n���h����ۑ�����

;----------------------------------------------------------------
;�W���n���h����NUL�փ��_�C���N�g����
;	�A�Z���u���̕\�����B��
	clr.w	-(sp)			;�W�����̓n���h��
	move.w	nul_in_handle,-(sp)	;NUL���̓n���h��
	DOS	_DUP2
	addq.l	#4,sp
	move.w	#1,-(sp)		;�W���o�̓n���h��
	move.w	nul_out_handle,-(sp)	;NUL�o�̓n���h��
	DOS	_DUP2
	addq.l	#4,sp
	move.w	#2,-(sp)		;�W���G���[�o�̓n���h��
	move.w	nul_out_handle,-(sp)	;NUL�o�̓n���h��
	DOS	_DUP2
	addq.l	#4,sp

  .endif ;HIDE_ASSEMBLER

;----------------------------------------------------------------
;�R�}���h�����s����
	clr.l	-(sp)
	pea.l	command_args		;����
	pea.l	command_line		;�R�}���h���C���A�R�}���h
	clr.w	-(sp)
	DOS	_EXEC
	lea.l	14(sp),sp
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'exit code: ',a1
		bsr	strcpy
		bsr	utos
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
		bsr	print
	endif
	if	<tst.l d0>,mi
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'cannot execute ',a1
		bsr	strcpy
		lea.l	command_line,a1		;�R�}���h���C���A�R�}���h
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
  .if ERROR_OUTPUT
		bsr	eprint
  .else
		bsr	print
  .endif
		goto	abort			;���~
	endif
	st.b	object_created		;-1=�I�u�W�F�N�g�t�@�C���쐬�ς�

	.data
object_created::
	.dc.b	0			;-1=�I�u�W�F�N�g�t�@�C���쐬�ς�
	.text

  .if HIDE_ASSEMBLER

;----------------------------------------------------------------
;�W���n���h���𕜌�����
	bsr	restore_std		;�W���n���h���𕜌�����

;----------------------------------------------------------------
;NUL�����
	bsr	close_nul		;NUL�����

  .endif ;HIDE_ASSEMBLER

;----------------------------------------------------------------
;�\�[�X�t�@�C��������
	bsr	delete_source		;�\�[�X�t�@�C��������

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C�����J��
	bsr	open_object		;�I�u�W�F�N�g�t�@�C�����J��

;----------------------------------------------------------------
;SRAM�̓��e��ۑ�����
	bsr	save_sram		;SRAM�̓��e��ۑ�����

;----------------------------------------------------------------
;�R�[�h�̐擪�A�h���X�����߂�
	if	<tst.b sram_flag>,ne
		lea.l	SRAM_PROGRAM_START,a0	;SRAM�풓�v���O�����̐擪
	else
		lea.l	code_buffer,a0		;�R�[�h�o�b�t�@
	endif
	move.l	a0,d0
	add.l	#256-1,d0		;256�̔{���ɐ؂�グ��
	and.w	#-256,d0
	movea.l	d0,a0
	move.l	a0,free_start		;�󂫗̈�̐擪�A�h���X
	lea.l	268(a0),a0
	move.l	a0,code_start		;�R�[�h�̐擪�A�h���X
	addq.l	#4,a0
	move.l	a0,loop_start		;���[�v�̐擪�A�h���X
	lea.l	32766(a0),a0
	if	<tst.b sram_flag>,ne
		if	<cmpa.l #SRAM_END-6,a0>,hi
			lea.l	SRAM_END-6,a0		;SRAM�̖���-6
		endif
	endif
	move.l	a0,loop_end_limit	;���[�v�̖����A�h���X�̏��
;	addq.l	#6,a0
;	move.l	a0,code_end_limit	;�R�[�h�̖����A�h���X�̏��


	.bss
	.even
free_start::
	.ds.l	1			;�󂫗̈�̐擪�A�h���X
code_start::
	.ds.l	1			;�R�[�h�̐擪�A�h���X
loop_start::
	.ds.l	1			;���[�v�̐擪�A�h���X
loop_end_limit::
	.ds.l	1			;���[�v�̖����A�h���X�̏��
;code_end_limit::
;	.ds.l	1			;�R�[�h�̖����A�h���X�̏��
code_buffer::
	.ds.b	256+268+4+32766+6	;�R�[�h�o�b�t�@
	.text

;----------------------------------------------------------------
;�󂫗̈���[���N���A����
	if	<tst.b sram_flag>,ne
		unlocksram			;SRAM�������݋���
	endif
	movea.l	free_start,a0		;�󂫗̈�̐擪�A�h���X
	movea.l	code_start,a1		;�R�[�h�̐擪�A�h���X
	moveq.l	#0,d0
	do
		move.l	d0,(a0)+
	while	<cmpa.l a1,a0>,lo
;	if	<tst.b sram_flag>,ne
;		locksram			;SRAM�������݋֎~
;	endif

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C����ǂݍ���Ŗ��ߗ񃋁[�v�����
;	if	<tst.b sram_flag>,ne
;		unlocksram			;SRAM�������݋���
;	endif
	movea.l	code_start,a0		;�R�[�h�̐擪�A�h���X
	move.l	#$3E3C0000,(a0)+	;move.w #1-1,d7
	movea.l	a0,a3			;loop_start
	moveq.l	#0,d3			;0=���s,1=����
	do
		bsr	object_word
		break	mi
		if	eq			;�I��
			move.w	#$51CF,(a0)+		;dbra d7,(loop_start)
			move.w	a3,d0
			sub.w	a0,d0
			move.w	d0,(a0)+
			move.w	#$4E75,(a0)+		;rts
		;	bsr	cache_flush		;�L���b�V���t���b�V��
			move.l	a0,code_end		;�R�[�h�̖����A�h���X
			moveq.l	#1,d3			;����
			break
		elifand	<cmp.w #$1000,d0>,hs,<cmp.w #$10FF,d0>,ls	;.dc�܂��͖���
			and.w	#$00FF,d0
			addq.w	#1,d0			;����
			lea.l	(a0,d0.w),a1		;����
			break	<cmpa.l loop_end_limit,a1>,hi	;text�Z�N�V��������ꂽ�B���s
			do
				bsr	object_byte
				break2	mi
				move.b	d0,(a0)+
			while	<cmpa.l a1,a0>,lo
			move.w	a1,d0
			if	<btst.l #0,d0>,ne	;�������
				bsr	object_byte
				break	mi
			endif
		elif	<cmp.w #$2001,d0>,eq	;text�Z�N�V����
			bsr	object_long
			break	mi
		elif	<cmp.w #$2002,d0>,eq	;data�Z�N�V����
			break	t			;data�Z�N�V����������B���s
		elif	<cmp.w #$2003,d0>,eq	;bss�Z�N�V����
			break	t			;bss�Z�N�V����������B���s
		elif	<cmp.w #$2004,d0>,eq	;stack�Z�N�V����
			break	t			;stack�Z�N�V����������B���s
		elif	<cmp.w #$3000,d0>,eq	;.ds
			bsr	object_long		;����
			break	mi
			lea.l	(a0,d0.l),a1		;����
			break	<cmpa.l loop_end_limit,a1>,hi	;text�Z�N�V��������ꂽ�B���s
			do
				clr.b	(a0)+
			while	<cmpa.l a1,a0>,lo
		elif	<cmp.w #$4201,d0>,eq	;text�Z�N�V�����̐擪����̃I�t�Z�b�g
			bsr	object_long		;�I�t�Z�b�g
			break	mi
			lea.l	4(a0),a1		;����
			break	<cmpa.l loop_end_limit,a1>,hi	;text�Z�N�V��������ꂽ�B���s
			add.l	a3,d0			;�����P�[�g�����A�h���X
			moveq.l	#4-1,d1
			for	d1
				rol.l	#8,d0
				move.b	d0,(a0)+
			next
		elif	<cmp.w #$C001,d0>,eq	;text�Z�N�V�����̏��
			bsr	object_long		;text�Z�N�V�����̒���
			break	mi
			break	eq			;text�Z�N�V�������Ȃ��B���s
			bsr	object_string
			break	mi
		elif	<cmp.w #$C002,d0>,eq	;.data�̏��
			bsr	object_long		;.data�̒���
			break	mi
			break	ne			;.data������B���s
			bsr	object_string
			break	mi
		elif	<cmp.w #$C003,d0>,eq	;.bss�̏��
			bsr	object_long		;.bss�̒���
			break	mi
			break	ne			;.bss������B���s
			bsr	object_string
			break	mi
		elif	<cmp.w #$C004,d0>,eq	;.stack�̏��
			bsr	object_long		;.stack�̒���
			break	mi
			break	ne			;.stack������B���s
			bsr	object_string
			break	mi
		elif	<cmp.w #$D000,d0>,eq	;�t�@�C�����
			bsr	object_long
			break	mi
			bsr	object_string
			break	mi
		else				;���̑�
			break	t			;���s
		endif
	while	t
	if	<tst.b sram_flag>,ne
		locksram			;SRAM�������݋֎~
	endif
	if	<tst.l d3>,eq		;���s
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'cannot process ',a1
		bsr	strcpy
	;	lea.l	object_file,a1		;�I�u�W�F�N�g�t�@�C����
		if	<tst.b inst_arg>,ne
			move.b	#'"',(a0)+
			lea.l	inst_arg,a1		;-i ���ߗ�
			bsr	strcpy
			move.b	#'"',(a0)+
		else
			lea.l	file_arg,a1		;-f �t�@�C����
			bsr	strcpy
		endif
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
  .if ERROR_OUTPUT
		bsr	eprint
  .else
		bsr	print
  .endif
		goto	abort			;���~
	endif

	.bss
	.even
code_end::
	.ds.l	1			;�R�[�h�̖����A�h���X
	.text

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C�������
	bsr	close_object		;�I�u�W�F�N�g�t�@�C�������

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C��������
	bsr	delete_object		;�I�u�W�F�N�g�t�@�C��������

;----------------------------------------------------------------
;���ߗ񃋁[�v���v������
	move.l	#1,repeat_count		;�J��Ԃ���
	do
		if	<tst.b verbose_flag>,ne
			lea.l	string_buffer,a0	;������o�b�t�@
			leastrdata	'repeat count: ',a1
			bsr	strcpy
			move.l	repeat_count,d0		;�J��Ԃ���
			bsr	utos
			bsr	crlf
			lea.l	string_buffer,a0	;������o�b�t�@
			bsr	print
		endif
		if	<tst.b sram_flag>,ne
			unlocksram			;SRAM�������݋���
		endif
		move.l	repeat_count,d0		;�J��Ԃ���
		subq.w	#1,d0			;�J��Ԃ���-1
		movea.l	code_start,a0		;�R�[�h�̐擪�A�h���X
		move.w	d0,2(a0)		;DBRA������������
		bsr	cache_flush		;�L���b�V���t���b�V��
		if	<tst.b sram_flag>,ne
			locksram			;SRAM�������݋֎~
		endif
		if	<tst.b verbose_flag>,ne
			leastrdata	<'instructions loop:',13,10>,a0
			bsr	print
			bsr	dump_code		;�R�[�h���_���v����
		endif
		if	<tst.b sram_flag>,ne
			unlocksram			;SRAM�������݋���
		endif
		movea.l	code_start,a0		;�R�[�h�̐擪�A�h���X
		bsr	optime			;�v��
		move.l	d0,inst_loop_time	;���ߗ񃋁[�v�̏��v����
		if	<tst.b sram_flag>,ne
			locksram			;SRAM�������݋֎~
		endif
		if	<tst.b verbose_flag>,ne
			lea.l	string_buffer,a0	;������o�b�t�@
			leastrdata	'instructions loop time: ',a1
			bsr	strcpy
			move.l	inst_loop_time,d0	;���ߗ񃋁[�v�̏��v����
			moveq.l	#1,d1
			bsr	time_to_string
			bsr	crlf
			lea.l	string_buffer,a0	;������o�b�t�@
			bsr	print
		endif
		break	<cmpi.l #1200,inst_loop_time>,hs	;1200us�ȏ�Ȃ�ΏI��
		break	<cmpi.l #10000,repeat_count>,eq	;10000��Ȃ�ΏI��
		move.l	repeat_count,d0
		mulu.w	#10,d0			;�񐔂�10�{�ɂ���
		move.l	d0,repeat_count
	while	t

	.bss
	.even
repeat_count::
	.ds.l	1			;�J��Ԃ���
inst_loop_time::
	.ds.l	1			;���ߗ񃋁[�v�̏��v����
	.text

;----------------------------------------------------------------
;�󃋁[�v�����
	if	<tst.b sram_flag>,ne
		unlocksram			;SRAM�������݋���
	endif
	movea.l	code_start,a0		;�R�[�h�̐擪�A�h���X
	move.w	#$3E3C,(a0)+		;move.w #��-1,d7
	move.l	repeat_count,d0
	subq.w	#1,d0
	move.w	d0,(a0)+
	move.l	#$51CFFFFE,(a0)+	;dbra d7,(loop_start)
	move.w	#$4E75,(a0)+		;rts
	bsr	cache_flush		;�L���b�V���t���b�V��
	move.l	a0,code_end
	if	<tst.b sram_flag>,ne
		locksram			;SRAM�������݋֎~
	endif
	if	<tst.b verbose_flag>,ne
		leastrdata	<'null loop:',13,10>,a0
		bsr	print
		bsr	dump_code		;�R�[�h���_���v����
	endif

;----------------------------------------------------------------
;�󃋁[�v���v������
	movea.l	code_start,a0		;�R�[�h�̐擪�A�h���X
	bsr	optime			;�v��
	move.l	d0,null_loop_time	;�󃋁[�v�̏��v����
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'null loop time: ',a1
		bsr	strcpy
		move.l	null_loop_time,d0	;�󃋁[�v�̏��v����
		moveq.l	#1,d1
		bsr	time_to_string
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
		bsr	print
	endif

	.bss
	.even
null_loop_time::
	.ds.l	1			;�󃋁[�v�̏��v����
	.text

;----------------------------------------------------------------
;SRAM�̓��e�𕜌�����
	bsr	restore_sram		;SRAM�̓��e�𕜌�����

;----------------------------------------------------------------
;�R�[�h�̏��v���Ԃ�\������
	lea.l	string_buffer,a0	;������o�b�t�@
	if	<tst.b inst_arg>,ne
		move.b	#'"',(a0)+
		lea.l	inst_arg,a1		;-i ���ߗ�
		bsr	strcpy
		move.b	#'"',(a0)+
	else
		lea.l	file_arg,a1		;-f �t�@�C����
		bsr	strcpy
	endif
	move.b	#9,(a0)+
	move.l	inst_loop_time,d0	;���ߗ񃋁[�v�̏��v����
	sub.l	null_loop_time,d0	;���ߗ񃋁[�v�̏��v����-�󃋁[�v�̏��v����=���ߗ�̏��v����
	if	lt
		moveq.l	#0,d0
	endif
	move.l	repeat_count,d1
	bsr	time_to_string
	bsr	crlf
	lea.l	string_buffer,a0	;������o�b�t�@
	bsr	print

;----------------------------------------------------------------
;����I��
	clr.w	exit_code		;�I���R�[�h

	.data
	.even
exit_code::
	.dc.w	1			;�I���R�[�h
	.text

;----------------------------------------------------------------
;���~
abort::

;----------------------------------------------------------------
;ssp��usp�𕜌�����
	if	<tst.l saved_ssp>,ne
		movea.l	saved_ssp,sp		;�ۑ����ꂽssp
		clr.l	saved_ssp		;�ۑ����ꂽssp
	endif
	if	<tst.l saved_usp>,ne
		move.l	saved_usp,a0		;�ۑ����ꂽusp
		move.l	a0,usp
		clr.l	saved_usp		;�ۑ����ꂽusp
	endif

;----------------------------------------------------------------
;�A�{�[�g�x�N�^�𕜌�����
	if	<tst.l saved_ctrlvc>,ne
		move.l	saved_ctrlvc,-(sp)	;�ۑ����ꂽ_CTRLVC
		move.w	#_CTRLVC,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp
		clr.l	saved_ctrlvc		;�ۑ����ꂽ_CTRLVC
	endif
	if	<tst.l saved_errjvc>,ne
		move.l	saved_errjvc,-(sp)	;�ۑ����ꂽ_ERRJVC
		move.w	#_ERRJVC,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp
		clr.l	saved_errjvc		;�ۑ����ꂽ_ERRJVC
	endif

;----------------------------------------------------------------
;�^�C�}�𕜌�����
	bsr	restore_timer		;�^�C�}�𕜌�����

  .if HIDE_ASSEMBLER

;----------------------------------------------------------------
;�W���n���h���𕜌�����
	bsr	restore_std		;�W���n���h���𕜌�����

;----------------------------------------------------------------
;NUL�����
	bsr	close_nul		;NUL�����

  .endif ;HIDE_ASSEMBLER

;----------------------------------------------------------------
;�\�[�X�t�@�C��������
	bsr	delete_source		;�\�[�X�t�@�C��������

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C�������
	bsr	close_object		;�I�u�W�F�N�g�t�@�C�������

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C��������
	bsr	delete_object		;�I�u�W�F�N�g�t�@�C��������

;----------------------------------------------------------------
;SRAM�̓��e�𕜌�����
	bsr	restore_sram		;SRAM�̓��e�𕜌�����

;----------------------------------------------------------------
;���[�U���[�h�֕��A����
	usermode

;----------------------------------------------------------------
;�I������
	move.w	exit_code,-(sp)		;�I���R�[�h
	DOS	_EXIT2


;----------------------------------------------------------------
;�^�C�g���Ǝg�p�@��\�����ďI������
usage_exit::
	lea.l	title_usage,a0		;�^�C�g���Ǝg�p�@
  .if ERROR_OUTPUT
	bsr	eprint
  .else
	bsr	print
  .endif
	move.w	#1,-(sp)
	DOS	_EXIT2

	.data
title_usage::
	.dc.b	TITLE_STRING,13,10
	.dc.b	'Measure the execution time of instructions',13,10
	.dc.b	'  -a has060  Assembler',13,10
	.dc.b	'  -f nop.s   File containing instructions',13,10
	.dc.b	'  -i "nop"   Semicolon-delimited instructions',13,10
	.dc.b	'  -s         Measure in SRAM. Ask when SRAM in use',13,10
	.dc.b	'  -sn        Same as -s but not measure when SRAM in use',13,10
	.dc.b	'  -sy        Same as -s but measure even when SRAM in use',13,10
	.dc.b	'  -t %temp%  Temporary directory',13,10
	.dc.b	'  -v         Output verbose messages',13,10
	.dc.b	0			;�^�C�g���Ǝg�p�@
	.text


;----------------------------------------------------------------
;1��̎��Ԃ𕶎���ɕϊ�����
;<d0.l:����(us)�B0�`12799
;<d1.w:�񐔁B1,10,100,1000,10000�̂����ꂩ
;<a0.l:�o�b�t�@
;>a0.l:������̖�����0�̈ʒu
time_to_string::
	push	d0-d3/a1-a2
	movea.l	a0,a1
;<a1.l:�擪
	bsr	utos
;<a0.l:����
	move.w	a0,d0
	sub.w	a1,d0
;<d0.w:�S�̂̌����B0us��1��
	moveq.l	#0,d2
	moveq.l	#1,d3
	docontinue
		addq.w	#1,d2
		mulu.w	#10,d3
	while	<cmp.w d3,d1>,hi
;<d2.w:�������̌����B0�ȏ�
	move.w	d0,d1
	sub.w	d2,d1
;<d1.w:�������̌���
	moveq.l	#'u',d3
	if	<cmp.w #3,d1>,gt	;us�̐�������4���ȏ゠��Bms�ɂ���
		addq.w	#3,d2
		subq.w	#3,d1
		moveq.l	#'m',d3
	endif
;<d3.b:�P�ʁB'u'�܂���'m'
	if	<tst.w	d1>,le		;���������Ȃ��B(a1)��'0.'��'0'��-d1�}������
		neg.w	d1
		lea.l	2(a1,d1.w),a2		;(a1)�̈ړ���
		lea.l	(a2,d0.w),a0		;�V��������
		for	d0
			move.b	(a1,d0.w),(a2,d0.w)	;������0�ƑS�̂����炷
		next
		move.b	#'0',(a1)+
		move.b	#'.',(a1)+
		forcontinue	d1
			move.b	#'0',(a1)+
		next
	elif	<tst.w	d2>,gt		;������������B(a1,d1.w)��'.'��}������
		adda.w	d1,a1			;'.'��}������ʒu
		lea.l	1(a1),a2		;(a1)�̈ړ���
		addq.l	#1,a0			;�V��������
		for	d2
			move.b	(a1,d2.w),(a2,d2.w)	;������0�Ə����������炷
		next
		move.b	#'.',(a1)+
	endif
	move.b	#' ',(a0)+
	move.b	d3,(a0)+
	move.b	#'s',(a0)+
	clr.b	(a0)
	pop
	rts


  .if HIDE_ASSEMBLER

;----------------------------------------------------------------
;�W���n���h����ۑ�����
save_std::
	clr.w	-(sp)			;�W�����̓n���h��
	DOS	_DUP
	addq.l	#2,sp
	move.w	d0,saved_stdin		;�ۑ����ꂽ�W�����̓n���h��
	move.w	#1,-(sp)		;�W���o�̓n���h��
	DOS	_DUP
	addq.l	#2,sp
	move.w	d0,saved_stdout		;�ۑ����ꂽ�W���o�̓n���h��
	move.w	#2,-(sp)		;�W���G���[�o�̓n���h��
	DOS	_DUP
	addq.l	#2,sp
	move.w	d0,saved_stderr		;�ۑ����ꂽ�W���G���[�o�̓n���h��
	rts

	.data
	.even
saved_stdin::
	.dc.w	-1			;�ۑ����ꂽ�W�����̓n���h��
saved_stdout::
	.dc.w	-1			;�ۑ����ꂽ�W���o�̓n���h��
saved_stderr::
	.dc.w	-1			;�ۑ����ꂽ�W���G���[�o�̓n���h��
	.text

;----------------------------------------------------------------
;�W���n���h���𕜌�����
restore_std::
	if	<cmpi.w #-1,saved_stdin>,ne
		clr.w	-(sp)			;�W�����̓n���h��
		move.w	saved_stdin,-(sp)	;�ۑ����ꂽ�W�����̓n���h��
		DOS	_DUP2
		DOS	_CLOSE
		addq.l	#4,sp
		move.w	#-1,saved_stdin		;�ۑ����ꂽ�W�����̓n���h��
	endif
	if	<cmpi.w #-1,saved_stdout>,ne
		move.w	#1,-(sp)		;�W���o�̓n���h��
		move.w	saved_stdout,-(sp)	;�ۑ����ꂽ�W���o�̓n���h��
		DOS	_DUP2
		DOS	_CLOSE
		addq.l	#4,sp
		move.w	#-1,saved_stdout	;�ۑ����ꂽ�W���o�̓n���h��
	endif
	if	<cmpi.w #-1,saved_stderr>,ne
		move.w	#2,-(sp)		;�W���G���[�o�̓n���h��
		move.w	saved_stderr,-(sp)	;�ۑ����ꂽ�W���G���[�o�̓n���h��
		DOS	_DUP2
		DOS	_CLOSE
		addq.l	#4,sp
		move.w	#-1,saved_stderr	;�ۑ����ꂽ�W���G���[�o�̓n���h��
	endif
	rts

;----------------------------------------------------------------
;NUL���J��
open_nul::
	clr.w	-(sp)			;����
	peastrdata	'nul'
	DOS	_OPEN
	addq.l	#6,sp
	move.w	d0,nul_in_handle	;NUL���̓n���h��
	move.w	#1,-(sp)		;�o��
	peastrdata	'nul'
	DOS	_OPEN
	addq.l	#6,sp
	move.w	d0,nul_out_handle	;NUL�o�̓n���h��
	rts

	.data
	.even
nul_in_handle::
	.dc.w	-1			;NUL���̓n���h��
nul_out_handle::
	.dc.w	-1			;NUL�o�̓n���h��
	.text

;----------------------------------------------------------------
;NUL�����
close_nul::
	if	<cmpi.w #-1,nul_in_handle>,ne
		move.w	nul_in_handle,-(sp)		;NUL���̓n���h��
		DOS	_CLOSE
		addq.l	#2,sp
		move.w	#-1,nul_in_handle		;NUL���̓n���h��
	endif
	if	<cmpi.w #-1,nul_out_handle>,ne
		move.w	nul_out_handle,-(sp)		;NUL�o�̓n���h��
		DOS	_CLOSE
		addq.l	#2,sp
		move.w	#-1,nul_out_handle		;NUL�o�̓n���h��
	endif
	rts

  .endif ;HIDE_ASSEMBLER

;----------------------------------------------------------------
;�\�[�X�t�@�C�������
create_source::
	if	<tst.b inst_arg>,ne
		lea.l	source_file,a0		;�\�[�X�t�@�C����
		lea.l	temp_directory,a1	;�e���|�����f�B���N�g����
		bsr	strcpy
		leastrdata	'opti????.s',a1
		bsr	strcpy
		move.w	#$0020,-(sp)
		pea.l	source_file		;�\�[�X�t�@�C����
		DOS	_MAKETMP
		addq.l	#6,sp
		move.l	d0,d1
		if	mi
			lea.l	string_buffer,a0	;������o�b�t�@
			leastrdata	'cannot create ',a1
			bsr	strcpy
			lea.l	source_file,a1		;�\�[�X�t�@�C����
			bsr	strcpy
			bsr	crlf
			lea.l	string_buffer,a0	;������o�b�t�@
  .if ERROR_OUTPUT
			bsr	eprint
  .else
			bsr	print
  .endif
			goto	abort			;���~
		endif
		st.b	source_created		;�\�[�X�t�@�C���쐬�ς݃t���O
		move.w	d1,-(sp)
		pea.l	source_code		;�\�[�X�R�[�h
		DOS	_FPUTS
		addq.l	#6,sp
		move.w	d1,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
	else
		lea.l	source_file,a0		;�\�[�X�t�@�C����
		lea.l	file_arg,a1		;-f �t�@�C����
		bsr	strcpy
	endif
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'source file: ',a1
		bsr	strcpy
		lea.l	source_file,a1		;�\�[�X�t�@�C����
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
		bsr	print
	endif
	rts

	.data
source_created::
	.dc.b	0			;�\�[�X�t�@�C���쐬�ς݃t���O
	.bss
source_file::
	.ds.b	1024			;�\�[�X�t�@�C����
	.text

;----------------------------------------------------------------
;�\�[�X�t�@�C��������
delete_source::
	if	<tst.b source_created>,ne
		pea.l	source_file		;�\�[�X�t�@�C����
		DOS	_DELETE
		addq.l	#4,sp
		sf.b	source_created		;�\�[�X�t�@�C���쐬�ς݃t���O
	endif
	rts

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C�����J��
open_object::
	clr.w	-(sp)
	pea.l	object_file		;�I�u�W�F�N�g�t�@�C����
	DOS	_OPEN
	addq.l	#6,sp
	if	<tst.l d0>,mi
		lea.l	string_buffer,a0	;������o�b�t�@
		leastrdata	'cannot open ',a1
		bsr	strcpy
		lea.l	object_file,a1		;�I�u�W�F�N�g�t�@�C����
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;������o�b�t�@
  .if ERROR_OUTPUT
		bsr	eprint
  .else
		bsr	print
  .endif
		goto	abort			;���~
	endif
	move.w	d0,object_handle
	rts

	.data
	.even
object_handle::
	.dc.w	-1			;�I�u�W�F�N�g�t�@�C���n���h��
	.text

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C�������
close_object::
	if	<cmpi.w #-1,object_handle>,ne
		move.w	object_handle,-(sp)	;�I�u�W�F�N�g�t�@�C���n���h��
		DOS	_CLOSE
		addq.l	#2,sp
		move.w	#-1,object_handle	;�I�u�W�F�N�g�t�@�C���n���h��
	endif
	rts

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C��������
delete_object::
	if	<tst.b object_created>,ne
		pea.l	object_file		;�I�u�W�F�N�g�t�@�C����
		DOS	_DELETE
		addq.l	#4,sp
		sf.b	object_created		;-1=�I�u�W�F�N�g�t�@�C���쐬�ς�
	endif
	rts

;----------------------------------------------------------------
;SRAM�̓��e��ۑ�����
save_sram::
	if	<tst.b sram_flag>,ne
		lea.l	sram_data,a0		;�ۑ����ꂽSRAM�f�[�^
		lea.l	$00ED0100,a1
		move.w	#$3F00/4-1,d0
		for	d0
			move.l	(a1)+,(a0)+
		next
		st.b	sram_saved		;SRAM�ۑ��ς݃t���O
	endif
	rts

	.data
sram_saved::
	.dc.b	0			;SRAM�ۑ��ς݃t���O
	.bss
	.even
sram_data::
	.ds.l	$3F00/4			;�ۑ����ꂽSRAM�f�[�^
	.text

;----------------------------------------------------------------
;SRAM�̓��e�𕜌�����
restore_sram::
	if	<tst.b sram_saved>,ne
		unlocksram			;SRAM�������݋���
		lea.l	$00ED0100,a0
		lea.l	sram_data,a1		;�ۑ����ꂽSRAM�f�[�^
		move.w	#$3F00/4-1,d0
		for	d0
			move.l	(a1)+,(a0)+
		next
		locksram			;SRAM�������݋֎~
		sf.b	sram_saved		;SRAM�ۑ��ς݃t���O
	endif
	rts


;----------------------------------------------------------------
;�R�[�h���_���v����
dump_code::
	push	d0/a0-a4
	movea.l	code_start,a3		;�R�[�h�̐擪�A�h���X
	move.l	a3,d0
	and.w	#-16,d0			;16�̔{���ɐ؂�̂Ă�
	movea.l	d0,a1			;�\���J�n�A�h���X
	movea.l	code_end,a4		;�R�[�h�̖����A�h���X
	move.l	a4,d0
	add.l	#16-1,d0		;16�̔{���ɐ؂�グ��
	and.w	#-16,d0
	movea.l	d0,a2			;�\���I���A�h���X
	docontinue
		move.l	a1,d0
		and.w	#16-1,d0
		if	eq
			lea.l	string_buffer,a0	;������o�b�t�@
			move.l	a1,d0
			bsr	h8tos
			move.b	#' ',(a0)+
		endif
		move.b	#' ',(a0)+
		ifand	<cmpa.l a3,a1>,hs,<cmpa.l a4,a1>,lo	;�R�[�h�͈͓̔�
			move.w	(a1),d0
			bsr	h4tos
		else				;�R�[�h�͈̔͊O
			move.b	#'.',(a0)+
			move.b	#'.',(a0)+
			move.b	#'.',(a0)+
			move.b	#'.',(a0)+
		endif
		addq.l	#2,a1
		move.l	a1,d0
		and.w	#16-1,d0
		if	eq
			bsr	crlf
			lea.l	string_buffer,a0	;������o�b�t�@
			bsr	print
		endif
	while	<cmpa.l a2,a1>,lo
	pop
	rts


;----------------------------------------------------------------
;�v���T�u���[�`��
;	�X�[�p�[�o�C�U���[�h�ŌĂяo������
;<a0.l:�v������T�u���[�`���Bd0-d7/a0-a4�����R�Ɏg����
;>d0.l:���v����(us)�B0�`12799
optime::
	push	d1-d7/a0-a6
	movea.l	a0,a5
aTCDCR	reg	a6
	lea.l	MFP_TCDCR,aTCDCR
;���荞�݋֎~
	di
;�^�C�}�ۑ�
	lea.l	timer_ierb(pc),a0
	move.b	MFP_IERB-MFP_TCDCR(aTCDCR),(a0)	;timer_ierb
	move.b	MFP_IMRB-MFP_TCDCR(aTCDCR),-(a0)	;timer_imrb
	move.b	MFP_TCDCR-MFP_TCDCR(aTCDCR),-(a0)	;timer_tcdcr
	st.b	-(a0)			;timer_saved
;�^�C�}�ݒ�
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IERB-MFP_TCDCR(aTCDCR)	;Timer-C/D���荞�ݒ�~
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IMRB-MFP_TCDCR(aTCDCR)	;Timer-C/D���荞�݋֎~
	move.b	#0,(aTCDCR)		;Timer-C/D�J�E���g��~
	do
	while	<tst.b (aTCDCR)>,ne	;���S�ɒ�~����܂ő҂�
;���n�[�T���Ɩ{��
	clr.b	-(sp)			;$00=���n�[�T��,$FF=�{��
	do
	;�J�E���g�J�n
		move.b	#0,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-C�J�E���^�N���A
		move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-D�J�E���^�N���A
		move.b	#MFP_50US<<4|MFP_1US,(aTCDCR)	;Timer-C/D�J�E���g�J�n
						;Timer-C��1/200�v���X�P�[��(50us)
						;Timer-D��1/4�v���X�P�[��(1us)
	;�v��
		jsr	(a5)
	;�J�E���g��~
		move.b	#0,(aTCDCR)		;Timer-C/D�J�E���g��~
		do
		while	<tst.b (aTCDCR)>,ne	;���S�ɒ�~����܂ő҂�
		not.b	(sp)
	while	ne
	tst.b	(sp)+
;�^�C�}�擾
	moveq.l	#0,d0
	moveq.l	#0,d1
	sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;Timer-C�J�E���g��
	sub.b	MFP_TDDR-MFP_TCDCR(aTCDCR),d1	;Timer-D�J�E���g��(�I�[�o�[�t���[����)
;�^�C�}����
	lea.l	timer_saved(pc),a0
	move.b	#200,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-C�J�E���^����
	move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-D�J�E���^�N���A
	sf.b	(a0)+				;timer_saved
	move.b	(a0)+,(aTCDCR)			;timer_tcdcr
	move.b	(a0)+,MFP_IMRB-MFP_TCDCR(aTCDCR)	;timer_imrb
	move.b	(a0),MFP_IERB-MFP_TCDCR(aTCDCR)	;timer_ierb
;���荞�݋���
	ei
;�J�E���^����
	mulu.w	#50,d0
	if	<cmp.b d1,d0>,hi
		add.w	#256,d0
	endif
	move.b	d1,d0
	move.l	d0,d1
;�I��
	move.l	d1,d0
	pop
	rts

;�^�C�}�𕜌�����
restore_timer::
	push	a0/a6
	lea.l	MFP_TCDCR,aTCDCR
	lea.l	timer_saved(pc),a0
	if	<tst.b (a0)>,ne
		di
		move.b	#200,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-C�J�E���^����
		move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-D�J�E���^�N���A
		sf.b	(a0)+				;timer_saved
		move.b	(a0)+,(aTCDCR)			;timer_tcdcr
		move.b	(a0)+,MFP_IMRB-MFP_TCDCR(aTCDCR)	;timer_imrb
		move.b	(a0),MFP_IERB-MFP_TCDCR(aTCDCR)	;timer_ierb
		ei
	endif
	pop
	rts

	.data
timer_saved::
	.dc.b	0			;-1=�ȉ��ۑ��ς�
timer_tcdcr::
	.dc.b	0			;�ۑ����ꂽTCDCR
timer_imrb::
	.dc.b	0			;�ۑ����ꂽIMRB
timer_ierb::
	.dc.b	0			;�ۑ����ꂽIERB
	.text


;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C���̕������ǂݔ�΂�
;>d0.l:�ǂݔ�΂����o�C�g���B0���܂ށB����
object_string::
	push	d1
	moveq.l	#0,d1
	do
		do
			addq.l	#1,d1
			bsr	object_byte
			break2	mi
		while	ne
		if	<btst.l #0,d1>,ne
			addq.l	#1,d1
			bsr	object_byte
			break	mi
		endif
		move.l	d1,d0
	while	f
	pop
	tst.l	d0
	rts

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C������1�����O���[�h�ǂݏo��
;>d0.l:�ǂݏo�����f�[�^
object_long::
	clr.l	-(sp)
	do
		bsr	object_byte
		break	mi
		move.b	d0,(sp)
		bsr	object_byte
		break	mi
		move.b	d0,1(sp)
		bsr	object_byte
		break	mi
		move.b	d0,2(sp)
		bsr	object_byte
		break	mi
		move.b	d0,3(sp)
		move.l	(sp),d0
	while	f
	addq.l	#4,sp
	rts

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C������1���[�h�ǂݏo��
;>d0.l:�ǂݏo�����f�[�^
object_word::
	clr.l	-(sp)
	do
		bsr	object_byte
		break	mi
		move.b	d0,2(sp)
		bsr	object_byte
		break	mi
		move.b	d0,3(sp)
		move.l	(sp),d0
	while	f
	addq.l	#4,sp
	rts

;----------------------------------------------------------------
;�I�u�W�F�N�g�t�@�C������1�o�C�g�ǂݏo��
;>d0.l:�ǂݏo�����f�[�^
object_byte::
	move.w	object_handle,-(sp)
	DOS	_FGETC
	addq.l	#2,sp
	if	<tst.l d0>,pl
		and.l	#$000000FF,d0
	endif
	rts


;----------------------------------------------------------------
;�������R�s�[����
;	�󔒂�ǂݔ�΂��Ă��玟�̋󔒂̎�O�܂ŃR�s�[����
;	"�`"�܂���'�`'�ň͂ނƈ����ɋ󔒂��܂߂邱�Ƃ��ł���
;	""�܂���''�Ə����ƒ�����0�̈�����^���邱�Ƃ��ł���
;<a0.l:�R�s�[��̃o�b�t�@�̐擪
;<a1.l:�R�s�[���̕�����̐擪
;>d0.l:0=�������Ȃ�,1=����������
;>a0.l:�R�s�[��̕�����̖�����0�̈ʒu
;>a1.l:�R�s�[���̈����̒���B�Ȃ���΃R�s�[���̕�����̖�����0�̈ʒu
;>eq=�������Ȃ�,ne=����������
argcpy::
	exg.l	a0,a1
	bsr	nonspace		;�󔒂�ǂݔ�΂�
	exg.l	a0,a1
	if	eq			;�������Ȃ�
		clr.b	(a0)
		moveq.l	#0,d0
		rts
	endif
	dostart
		if	<cmp.b #'"',d0>,eq	;"�`"
			dostart
				move.b	d0,(a0)+		;��������
			start
				move.b	(a1)+,d0		;���̕���
				break2	eq			;�������I�����
			while	<cmp.b #'"',d0>,ne
		elif	<cmp.b #39,d0>,eq	;'�`'
			dostart
				move.b	d0,(a0)+		;��������
			start
				move.b	(a1)+,d0		;���̕���
				break2	eq			;�������I�����
			while	<cmp.b #$39,d0>,ne
		else
			move.b	d0,(a0)+		;��������
		endif
	start
		move.b	(a1)+,d0		;���̕���
		break	eq			;�������I�����
		breakand	<cmp.b #9,d0>,hs,<cmp.b #13,d0>,ls	;\t\n\v\f\r�Ȃ�ΏI��
	while	<cmp.b #' ',d0>,ne	;�󔒂łȂ���ΌJ��Ԃ�
	subq.l	#1,a1			;�i�݉߂������߂�
	clr.b	(a0)
	moveq.l	#1,d0
	rts

;----------------------------------------------------------------
;�L���b�V���t���b�V��
cache_flush::
	push	d0-d1
	if	<is68000 d0>,ne
		moveq.l	#3,d1
		IOCS	_SYS_STAT
	endif
	pop
	rts

;----------------------------------------------------------------
;���s���R�s�[����
;<a0.l:�R�s�[��
;>a0.l:�R�s�[���0�̈ʒu
crlf::
	move.b	#13,(a0)+
	move.b	#10,(a0)+
	clr.b	(a0)
	rts

  .if ERROR_OUTPUT
;----------------------------------------------------------------
;��������G���[�\������
;<a0.l:������̐擪
;>a0.l:������̐擪
eprint::
	push	d0
	bsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#2,-(sp)
	DOS	_WRITE
	lea.l	(10,sp),sp
	pop
	rts
  .endif

;----------------------------------------------------------------
;�����Ȃ�������16�i��4���̕�����ɕϊ�����
;<d0.w:�����Ȃ�����
;<a0.l:�o�b�t�@
;>a0.l:�o�b�t�@��0�̈ʒu
h4tos::
	push	d1-d2
	moveq.l	#4-1,d1
	for	d1
		rol.w	#4,d0
		moveq.l	#15,d2
		and.w	d0,d2
		move.b	h8tos_hex(pc,d2.w),(a0)+
	next
	clr.b	(a0)
	pop
	rts

;----------------------------------------------------------------
;�����Ȃ�������16�i��8���̕�����ɕϊ�����
;<d0.l:�����Ȃ�����
;<a0.l:�o�b�t�@
;>a0.l:�o�b�t�@��0�̈ʒu
h8tos::
	push	d1-d2
	moveq.l	#8-1,d1
	for	d1
		rol.l	#4,d0
		moveq.l	#15,d2
		and.w	d0,d2
		move.b	h8tos_hex(pc,d2.w),(a0)+
	next
	clr.b	(a0)
	pop
	rts

h8tos_hex:
	.dc.b	'0123456789ABCDEF'
	.even

;----------------------------------------------------------------
;�󔒈ȊO�̕����܂œǂݔ�΂�
;<a0.l:������
;>d0.l:�󔒈ȊO�̕����܂���0
;>a0.l:�󔒈ȊO�̕����܂���0�̈ʒu
;>z:eq=0
nonspace::
	moveq.l	#0,d0
	do
		move.b	(a0)+,d0		;���̕���
		redoand	<cmp.b #9,d0>,hs,<cmp.b #13,d0>,ls	;\t\n\v\f\r�Ȃ�ΌJ��Ԃ�
	while	<cmp.b #' ',d0>,eq	;�󔒂Ȃ�ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�
	tst.l	d0
	rts

;----------------------------------------------------------------
;�������\������
;<a0.l:������̐擪
;>a0.l:������̐擪
print::
	push	d0
	bsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	(10,sp),sp
	pop
	rts

;----------------------------------------------------------------
;������𖖔��܂œǂݔ�΂�
;<a0.l:������̐擪
;>a0.l:������̖�����0�̈ʒu
strchr0::
	do
		tst.b	(a0)+
	while	ne
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;��������R�s�[����
;<a0.l:�R�s�[��
;<a1.l:�R�s�[��
;>a0.l:�R�s�[���0�̈ʒu
;>a1.l:�R�s�[����0�̎��̈ʒu
strcpy::
	do
		move.b	(a1)+,(a0)+
	while	ne			;0�łȂ���ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�
	rts

;----------------------------------------------------------------
;������̒����𐔂���
;<a0.l:������
;>d0.l:����
strlen::
	move.l	a0,d0			;d0=�擪
	do
		tst.b (a0)+
	while	ne			;0�łȂ���ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�Ba0=����
	exg.l	d0,a0			;d0=����,a0=�擪
	sub.l	a0,d0			;d0=����-�擪=����
	rts

;----------------------------------------------------------------
;�������ɂ���
;<d0.b:����
;>d0.b:����
tolower::
	ifand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls	;�啶��
		add.b	#'a'-'A',d0		;�������ɂ���
	endif
	rts

;----------------------------------------------------------------
;�����Ȃ�������10�i���̕�����ɕϊ�����
;<d0.l:�����Ȃ�����
;<a0.l:�o�b�t�@
;>a0.l:�o�b�t�@��0�̈ʒu
utos::
	push	d0-d2/a1
	if	<tst.l d0>,eq
		move.b	#'0',(a0)+
	else
		lea.l	utos_table(pc),a1
		do
			move.l	(a1)+,d1
		while	<cmp.l d1,d0>,lo	;������Ƃ���܂Ői��
		do
			moveq.l	#'0'-1,d2
			do
				addq.b	#1,d2
				sub.l	d1,d0
			while	hs			;������񐔂𐔂���
			move.b	d2,(a0)+
			add.l	d1,d0			;�������������������߂�
			move.l	(a1)+,d1
		while	ne
	endif
	clr.b	(a0)
	pop
	rts

utos_table::
	.dc.l	1000000000
	.dc.l	100000000
	.dc.l	10000000
	.dc.l	1000000
	.dc.l	100000
	.dc.l	10000
	.dc.l	1000
	.dc.l	100
	.dc.l	10
	.dc.l	1
	.dc.l	0

;----------------------------------------------------------------
;y/n���͑҂�
;	���b�Z�[�W��\������y�܂���n�����͂����܂ő҂��ĉ��s����
;	^C�Œ��f�ł���
;<a0.l:���b�Z�[�W
;>d0.l:'y'=yes,'n'=no
yesno::
	push	a0
	bsr	print
	do
		DOS	_GETCHAR		;�W�����͂���1�o�C�g����(�W���o�͂ɃG�R�[�o�b�N����)
		bsr	tolower
	whileand	<cmp.b #'y',d0>,ne,<cmp.b #'n',d0>,ne
	leastrdata	<13,10>,a0
	bsr	print
	pop
	rts

;----------------------------------------------------------------
;�v���O�����I��
	.end	program_start
