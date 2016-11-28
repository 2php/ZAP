#!/usr/bin/perl -w

use strict;
use warnings;

my $ZAP_HOME        = "/proj/ZAP";  # Modify this according to your system configuration. Do not add trailing slash!
my $LOG_FILE_PATH   = "/tmp/zap.log";
my $VVP_PATH        = "/tmp/zap.vvp";
my $VCD_PATH        = "/tmp/zap.vcd";
my $MEMORY_IMAGE    = "/tmp/prog.v";
my $FILELIST        = "/tmp/zap_files.list";
my $PROG_PATH       = $MEMORY_IMAGE;

my $ASM_PATH        = "$ZAP_HOME/sw/asm/prog.s";
my $C_PATH          = "$ZAP_HOME/sw/c/fact.c";

my $LINKER_PATH     = "$ZAP_HOME/scripts/linker.ld";
my $TARGET_BIN_PATH = "/tmp/prog.bin";
my  $rand = int rand(0xffffffff);
check_ivl_version();

print "PROG_PATH = $PROG_PATH\n";
system("rm -fv $LOG_FILE_PATH $VVP_PATH $VCD_PATH $PROG_PATH $TARGET_BIN_PATH $PROG_PATH");
system("date | tee $LOG_FILE_PATH");
system("ls -l | tee -a $LOG_FILE_PATH");
die "*E: Translation Failed!" if system("perl $ZAP_HOME/scripts/do_it.pl $ASM_PATH $C_PATH $LINKER_PATH $TARGET_BIN_PATH $PROG_PATH");
die "*E: Bin2Mem Failed!" if system("perl $ZAP_HOME/scripts/bin2mem.pl $TARGET_BIN_PATH $PROG_PATH");

# Prepare a file list.
system("touch $FILELIST");
open(FH, ">$FILELIST");

print FH 
"+incdir+$ZAP_HOME/includes/
$ZAP_HOME/rtl/zap_alu/zap_alu_main.v
$ZAP_HOME/rtl/zap_predecode/zap_predecode_coproc.v
$ZAP_HOME/rtl/zap_predecode/zap_predecode_main.v
$ZAP_HOME/rtl/zap_predecode/zap_predecode_mem_fsm.v
$ZAP_HOME/rtl/zap_predecode/zap_predecode_thumb.v
$ZAP_HOME/rtl/zap_decode/zap_decode.v
$ZAP_HOME/rtl/zap_decode/zap_decode_main.v
$ZAP_HOME/rtl/zap_fetch/zap_fetch_main.v
$ZAP_HOME/rtl/zap_issue/zap_issue_main.v
$ZAP_HOME/rtl/zap_memory/zap_memory_main.v
$ZAP_HOME/rtl/zap_regf/zap_register_file.v
$ZAP_HOME/rtl/zap_shift/zap_multiply.v
$ZAP_HOME/rtl/zap_shift/zap_shifter_main.v
$ZAP_HOME/rtl/zap_shift/zap_shift_shifter.v
$ZAP_HOME/rtl/zap_shift/mult16x16.v
$ZAP_HOME/rtl/zap_regf/bram.v
$ZAP_HOME/rtl/zap_regf/bram_wrapper.v
$ZAP_HOME/rtl/zap_alu/alu.v
$ZAP_HOME/rtl/zap_predecode/ones_counter.v
$ZAP_HOME/lib/reset_sync.v
$ZAP_HOME/lib/ram_simple.v
$ZAP_HOME/lib/mem_ben_block.v
$ZAP_HOME/lib/mem_inv_block.v
$ZAP_HOME/rtl/zap_mmu/zap_d_mmu_cache.v
$ZAP_HOME/rtl/zap_mmu/zap_i_mmu_cache.v
$ZAP_HOME/rtl/zap_cp15_cb/zap_cp15_cb.v
$ZAP_HOME/rtl/zap_top.v
$ZAP_HOME/rtl/zap_core.v
$ZAP_HOME/testbench/zap_test.v
$ZAP_HOME/models/ram/model_ram.v
";

die "*E: Verilog Compilation Failed!\n" if system("iverilog -v -f $FILELIST -o $VVP_PATH -g2001 -Winfloop -Wall -DSEED=$rand");
die "*E: VVP execution error!\n" if system("vvp $VVP_PATH >> $LOG_FILE_PATH");

# A custom perl script to analyze the output log...
die "*E:process_log.pl not found!\n" if system("perl $ZAP_HOME/debug/process_log.pl $LOG_FILE_PATH");
die "*E: GTKWave file open Error!\n" if system("gtkwave $VCD_PATH &");

sub check_ivl_version {
        my $x = `iverilog -V`;
        
        if ( $x !~ m/^Icarus Verilog version 10.0 \(stable\) \(v10_0\)\n/ )
        {
                print "*W: ZAP has been tested with Icarus Verilog 10.0 set to Verilog-2001 mode. Running on other versions of the compiler in other modes MAY result in differing behavior.\n"        ;
                print "*W: Press a key to continue running the simulation.";
                my $NULL = <STDIN>;
        }
        else
        {
                print "*I: Compiler version check passed!\n";
        }
}


