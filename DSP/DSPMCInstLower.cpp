//===-- DSPMCInstLower.cpp - Convert DSP MachineInstr to MCInst ---------===//
//
// The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains code to lower DSP MachineInstrs to their corresponding
// MCInst records.
//
//===----------------------------------------------------------------------===//
#include "DSPMCInstLower.h"
#include "DSPAsmPrinter.h"
#include "DSPInstrInfo.h"
#include "MCTargetDesc/DSPBaseInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/IR/Mangler.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/Debug.h"
#include <iostream>

using namespace llvm;


DSPMCInstLower::DSPMCInstLower(DSPAsmPrinter &asmprinter) :AsmPrinter(asmprinter){


}

void DSPMCInstLower::Initialize(MCContext *C){
	Ctx = C;
}

static void CreateMCInst(MCInst &Inst, unsigned Opc, const MCOperand &Opnd0,
	const MCOperand &Opnd1,
	const MCOperand &Opnd2 = MCOperand()){

	Inst.setOpcode(Opc);
	Inst.addOperand(Opnd0);
	Inst.addOperand(Opnd1);
	if (Opnd2.isValid())Inst.addOperand(Opnd2);
}


MCOperand DSPMCInstLower::LowerOperand(const MachineOperand &MO, unsigned offset)const {

	MachineOperandType MOTy = MO.getType();
	std::cout << MOTy << std::endl;
	switch (MOTy)
	{
	default:llvm_unreachable("unknown operand type");
		break;
	case MachineOperand::MO_Register:
		if (MO.isImplicit())break;
		return MCOperand::CreateReg(MO.getReg());
	case MachineOperand::MO_Immediate:
		return MCOperand::CreateImm(MO.getImm() + offset);
	case MachineOperand::MO_RegisterMask:
		break;
	case MachineOperand::MO_GlobalAddress:
		return LowerSymbolOperand(MO, MOTy, offset);
	case MachineOperand::MO_ConstantPoolIndex:
		return LowerSymbolOperand(MO, MOTy, offset);
		break;
	case MachineOperand::MO_MachineBasicBlock:
		return LowerSymbolOperand(MO, MOTy, offset);
	case MachineOperand::MO_JumpTableIndex:
		return LowerSymbolOperand(MO, MOTy, offset);

	}

	return MCOperand();
}

void DSPMCInstLower::Lower(const MachineInstr *MI, MCInst &OutMI)const{
	OutMI.setOpcode(MI->getOpcode());
	for (unsigned i = 0, e = MI->getNumOperands(); i != e; ++i){

		const MachineOperand &MO = MI->getOperand(i);
		MCOperand MCOp = LowerOperand(MO);
		if (MCOp.isValid())
		{
			OutMI.addOperand(MCOp);
		}
	}


}

MCOperand DSPMCInstLower::LowerSymbolOperand(const MachineOperand &MO, MachineOperandType MOTy, unsigned Offset) const {
	MCSymbolRefExpr::VariantKind Kind;
	const MCSymbol *Symbol;
	switch (MO.getTargetFlags())
	{
	default:llvm_unreachable("Invalid target flag!");
		break;
	case DSPII::MO_NO_FLAG: Kind = MCSymbolRefExpr::VK_None; break;
	case DSPII::MO_ABS_HI: Kind = MCSymbolRefExpr::VK_DSP_ABS_HI; break;
	case DSPII::MO_ABS_LO: Kind = MCSymbolRefExpr::VK_DSP_ABS_LO; break;
	case DSPII::MO_GPREL: Kind = MCSymbolRefExpr::VK_DSP_GPREL; break;
	case DSPII::MO_GOT: Kind = MCSymbolRefExpr::VK_DSP_GOT; break;
	}
	switch (MOTy){
	case MachineOperand::MO_GlobalAddress:
		Symbol = AsmPrinter.getSymbol(MO.getGlobal());
		break;
	case MachineOperand::MO_ConstantPoolIndex:
		Symbol = AsmPrinter.GetCPISymbol(MO.getIndex());
		break;
	case MachineOperand::MO_BlockAddress:
		Symbol = AsmPrinter.GetBlockAddressSymbol(MO.getBlockAddress());
		Offset += MO.getOffset();
		break;
	case MachineOperand::MO_JumpTableIndex:
		Symbol = AsmPrinter.GetJTISymbol(MO.getIndex());
		break;
	case MachineOperand::MO_MachineBasicBlock:
		Symbol = MO.getMBB()->getSymbol();
		break;
	default:
		llvm_unreachable("<unknown operand type>"); break;
	}
	const MCSymbolRefExpr *MCSym = MCSymbolRefExpr::Create(Symbol, Kind, *Ctx);

	if (!Offset)
		return MCOperand::CreateExpr(MCSym);
	assert(Offset > 0);
	const MCConstantExpr *OffsetExpr = MCConstantExpr::Create(Offset, *Ctx);
	const MCBinaryExpr *AddExpr = MCBinaryExpr::CreateAdd(MCSym, OffsetExpr, *Ctx);
	return MCOperand::CreateExpr(AddExpr);
}