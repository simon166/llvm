//===-- DSPInstPrinter.cpp - Convert DSP MCInst to assembly syntax ------===//
//
// The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an DSP MCInst to a .s file.
//
//===----------------------------------------------------------------------===//
#include "DSPInstPrinter.h"
#include "DSPInstrInfo.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include <iostream>
using namespace llvm;
#define DEBUG_TYPE "asm-printer"
#define PRINT_ALIAS_INSTR
#include "DSPGenAsmWriter.inc"


void DSPInstPrinter::printRegName(raw_ostream &OS, unsigned RegNo) const {
	if (RegNo == DSP::LR)
		OS << "";
	else 
		OS << '$' << StringRef(getRegisterName(RegNo)).upper();

}

void DSPInstPrinter::printInst(const MCInst *MI, raw_ostream &O, StringRef Annot){
	if (!printAliasInstr(MI, O)) printInstruction(MI, O);

	printAnnotation(O, Annot);
}

static void printExpr(const MCExpr *Expr, raw_ostream &OS){
	int offset = 0;
	const MCSymbolRefExpr *SRE;

	if (const MCBinaryExpr *BE = dyn_cast<MCBinaryExpr>(Expr)){
		SRE = dyn_cast<MCSymbolRefExpr>(BE->getLHS());
		const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(BE->getRHS());
		assert(SRE && CE && "Binary expression must be sym+const.");
		offset = CE->getValue();
	}
	else if (!(SRE = dyn_cast<MCSymbolRefExpr>(Expr)))
		assert(false && "Unexpected MCExpr type.");

	MCSymbolRefExpr::VariantKind Kind = SRE->getKind();
	switch (Kind) {
	default: llvm_unreachable("Invalid kind!");
	case MCSymbolRefExpr::VK_None: break;
	case MCSymbolRefExpr::VK_DSP_ABS_HI: OS << "%hi("; break;
	case MCSymbolRefExpr::VK_DSP_ABS_LO: OS << "%lo("; break;
	case MCSymbolRefExpr::VK_DSP_GPREL: OS << "gp_rel("; break;
	case MCSymbolRefExpr::VK_DSP_GOT: OS << "%rip("; break;
	}
	OS << SRE->getSymbol();
	if (offset) {
		if (offset > 0)
			OS << '+ ';
		OS << offset;
	}
	if ((Kind == MCSymbolRefExpr::VK_DSP_GPOFF_HI) ||
		(Kind == MCSymbolRefExpr::VK_DSP_GPOFF_LO))
		OS << ")))";
	else if (Kind != MCSymbolRefExpr::VK_None)
		OS << ')';
	
}

void DSPInstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
	raw_ostream &O) {
	std::cout << "the OpNo is" << OpNo << std::endl;
	const MCOperand &Op = MI->getOperand(OpNo);
	if (Op.isReg()) {
		printRegName(O, Op.getReg());
		return;
	}

	if (Op.isImm()) {
		O << Op.getImm();
		return;
	}
	assert(Op.isExpr() && "unknown operand kind in printOperand");
	printExpr(Op.getExpr(), O);
}

void DSPInstPrinter::printUnsignedImm(const MCInst *MI, int opNum,
	raw_ostream &O) {
	const MCOperand &MO = MI->getOperand(opNum);
	if (MO.isImm())
		O << (unsigned short int)MO.getImm();
	else
		printOperand(MI, opNum, O);
}
void DSPInstPrinter::
printMemOperand(const MCInst *MI, int opNum, raw_ostream &O) {
	// Load/Store memory operands -- imm($reg)
	// If PIC target the target is loaded as the
	// pattern ld $t9,%call16($gp)
	printOperand(MI, opNum + 1, O);
	O << "(";
	printOperand(MI, opNum, O);
	O << ")";
}

void DSPInstPrinter::
printMemOperandEA(const MCInst *MI, int opNum, raw_ostream &O) {
	// when using stack locations for not load/store instructions
	// print the same way as all normal 3 operand instructions.
	printOperand(MI, opNum, O);
	O << ", ";
	printOperand(MI, opNum + 1, O);
	return;
}