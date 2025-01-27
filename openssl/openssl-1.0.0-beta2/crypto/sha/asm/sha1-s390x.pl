#!/usr/bin/env perl

# ====================================================================
# Written by Andy Polyakov <appro@fy.chalmers.se> for the OpenSSL
# project. The module is, however, dual licensed under OpenSSL and
# CRYPTOGAMS licenses depending on where you obtain it. For further
# details see http://www.openssl.org/~appro/cryptogams/.
# ====================================================================

# SHA1 block procedure for s390x.

# April 2007.
#
# Performance is >30% better than gcc 3.3 generated code. But the real
# twist is that SHA1 hardware support is detected and utilized. In
# which case performance can reach further >4.5x for larger chunks.

# January 2009.
#
# Optimize Xupdate for amount of memory references and reschedule
# instructions to favour dual-issue z10 pipeline. On z10 hardware is
# "only" ~2.3x faster than software.

$kimdfunc=1;	# magic function code for kimd instruction

$output=shift;
open STDOUT,">$output";

$K_00_39="%r0"; $K=$K_00_39;
$K_40_79="%r1";
$ctx="%r2";	$prefetch="%r2";
$inp="%r3";
$len="%r4";

$A="%r5";
$B="%r6";
$C="%r7";
$D="%r8";
$E="%r9";	@V=($A,$B,$C,$D,$E);
$t0="%r10";
$t1="%r11";
@X=("%r12","%r13","%r14");
$sp="%r15";

$frame=160+16*4;

sub Xupdate {
my $i=shift;

$code.=<<___ if ($i==15);
	lg	$prefetch,160($sp)	### Xupdate(16) warm-up
	lr	$X[0],$X[2]
___
return if ($i&1);	# Xupdate is vectorized and executed every 2nd cycle
$code.=<<___ if ($i<16);
	lg	$X[0],`$i*4`($inp)	### Xload($i)
	rllg	$X[1],$X[0],32
___
$code.=<<___ if ($i>=16);
	xgr	$X[0],$prefetch		### Xupdate($i)
	lg	$prefetch,`160+4*(($i+2)%16)`($sp)
	xg	$X[0],`160+4*(($i+8)%16)`($sp)
	xgr	$X[0],$prefetch
	rll	$X[0],$X[0],1
	rllg	$X[1],$X[0],32
	rll	$X[1],$X[1],1
	rllg	$X[0],$X[1],32
	lr	$X[2],$X[1]		# feedback
___
$code.=<<___ if ($i<=70);
	stg	$X[0],`160+4*($i%16)`($sp)
___
unshift(@X,pop(@X));
}

sub BODY_00_19 {
my ($i,$a,$b,$c,$d,$e)=@_;
my $xi=$X[1];

	&Xupdate($i);
$code.=<<___;
	alr	$e,$K		### $i
	rll	$t1,$a,5
	lr	$t0,$d
	xr	$t0,$c
	alr	$e,$t1
	nr	$t0,$b
	alr	$e,$xi
	xr	$t0,$d
	rll	$b,$b,30
	alr	$e,$t0
___
}

sub BODY_20_39 {
my ($i,$a,$b,$c,$d,$e)=@_;
my $xi=$X[1];

	&Xupdate($i);
$code.=<<___;
	alr	$e,$K		### $i
	rll	$t1,$a,5
	lr	$t0,$b
	alr	$e,$t1
	xr	$t0,$c
	alr	$e,$xi
	xr	$t0,$d
	rll	$b,$b,30
	alr	$e,$t0
___
}

sub BODY_40_59 {
my ($i,$a,$b,$c,$d,$e)=@_;
my $xi=$X[1];

	&Xupdate($i);
$code.=<<___;
	alr	$e,$K		### $i
	rll	$t1,$a,5
	lr	$t0,$b
	alr	$e,$t1
	or	$t0,$c
	lr	$t1,$b
	nr	$t0,$d
	nr	$t1,$c
	alr	$e,$xi
	or	$t0,$t1
	rll	$b,$b,30
	alr	$e,$t0
___
}

$code.=<<___;
.text
.align	64
.type	Ktable,\@object
Ktable: .long	0x5a827999,0x6ed9eba1,0x8f1bbcdc,0xca62c1d6
	.skip	48	#.long	0,0,0,0,0,0,0,0,0,0,0,0
.size	Ktable,.-Ktable
.globl	sha1_block_data_order
.type	sha1_block_data_order,\@function
sha1_block_data_order:
___
$code.=<<___ if ($kimdfunc);
	lghi	%r0,0
	la	%r1,16($sp)
	.long	0xb93e0002	# kimd %r0,%r2
	lg	%r0,16($sp)
	tmhh	%r0,`0x8000>>$kimdfunc`
	jz	.Lsoftware
	lghi	%r0,$kimdfunc
	lgr	%r1,$ctx
	lgr	%r2,$inp
	sllg	%r3,$len,6
	.long	0xb93e0002	# kimd %r0,%r2
	brc	1,.-4		# pay attention to "partial completion"
	br	%r14
.Lsoftware:
___
$code.=<<___;
	lghi	%r1,-$frame
	stg	$ctx,16($sp)
	stmg	%r6,%r15,48($sp)
	lgr	%r0,$sp
	la	$sp,0(%r1,$sp)
	stg	%r0,0($sp)

	larl	$t0,Ktable
	llgf	$A,0($ctx)
	llgf	$B,4($ctx)
	llgf	$C,8($ctx)
	llgf	$D,12($ctx)
	llgf	$E,16($ctx)

	lg	$K_00_39,0($t0)
	lg	$K_40_79,8($t0)

.Lloop:
	rllg	$K_00_39,$K_00_39,32
___
for ($i=0;$i<20;$i++)	{ &BODY_00_19($i,@V); unshift(@V,pop(@V)); }
$code.=<<___;
	rllg	$K_00_39,$K_00_39,32
___
for (;$i<40;$i++)	{ &BODY_20_39($i,@V); unshift(@V,pop(@V)); }
$code.=<<___;	$K=$K_40_79;
	rllg	$K_40_79,$K_40_79,32
___
for (;$i<60;$i++)	{ &BODY_40_59($i,@V); unshift(@V,pop(@V)); }
$code.=<<___;
	rllg	$K_40_79,$K_40_79,32
___
for (;$i<80;$i++)	{ &BODY_20_39($i,@V); unshift(@V,pop(@V)); }
$code.=<<___;

	lg	$ctx,`$frame+16`($sp)
	la	$inp,64($inp)
	al	$A,0($ctx)
	al	$B,4($ctx)
	al	$C,8($ctx)
	al	$D,12($ctx)
	al	$E,16($ctx)
	st	$A,0($ctx)
	st	$B,4($ctx)
	st	$C,8($ctx)
	st	$D,12($ctx)
	st	$E,16($ctx)
	brct	$len,.Lloop

	lmg	%r6,%r15,`$frame+48`($sp)
	br	%r14
.size	sha1_block_data_order,.-sha1_block_data_order
.string	"SHA1 block transform for s390x, CRYPTOGAMS by <appro\@openssl.org>"
___

$code =~ s/\`([^\`]*)\`/eval $1/gem;

print $code;
close STDOUT;
