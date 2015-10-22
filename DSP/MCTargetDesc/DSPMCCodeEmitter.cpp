//===-- DSPMCCodeEmitter.cpp - Convert DSP Code to Machine Code ---------===//
//
// The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the DSPMCCodeEmitter class.
////===----------------------------------------------------------------------===//
//
#include "DSPMCCodeEmitter.h"
#include "MCTargetDesc/DSPBaseInfo.h"
#include "MCTargetDesc/DSPFixupKinds.h"
#include "MCTargetDesc/DSPMCTargetDesc.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/raw_ostream.h"
#include <iostream>
using namespace llvm;

MCCodeEmitter *llvm::createDSPMCCodeEmitterEB(const MCInstrInfo &MCII,
	const MCRegisterInfo &MRI,
	const MCSubtargetInfo &STI,
	MCContext &Ctx)
{
	return new DSPMCCodeEmitter(MCII, Ctx, false);
}
MCCodeEmitter *llvm::createDSPMCCodeEmitterEL(const MCInstrInfo &MCII,
	const MCRegisterInfo &MRI,
	const MCSubtargetInfo &STI,
	MCContext &Ctx)
{
	return new DSPMCCodeEmitter(MCII, Ctx, true);
}

void DSPMCCodeEmitter::EmitByte(unsigned char C, raw_ostream &OS) const {
	OS << (char)C;
}
void DSPMCCodeEmitter::EmitInstruction(uint64_t Val, unsigned Size, raw_ostream &OS) const {
	// Output the instruction encoding in little endian byte order.
	for (unsigned i = 0; i < Size; ++i) {
		unsigned Shift = IsLittleEndian ? i * 8 : (Size - 1 - i) * 8;
		EmitByte((Val >> Shift) & 0xff, OS);
	}
}

/// EncodeInstruction - Emit the instruction.
/// Size the instruction (currently only 4 bytes)
void DSPMCCodeEmitter::
EncodeInstruction(const MCInst &MI, raw_ostream &OS,
SmallVectorImpl<MCFixup> &Fixups,
const MCSubtargetInfo &STI) const
{
	uint32_t Binary = getBinaryCodeForInstr(MI, Fixups, STI);
	// Check for unimplemented opcodes.
	// Unfortunately in DSP both NOT and SLL will come in with Binary == 0
	// so we have to special check for them.
	unsigned Opcode = MI.getOpcode();
	std::cout << "opcode is " << Opcode << std::endl;
	if ((Opcode != DSP::NOP) && (Opcode != DSP::SHL) && !Binary)
		llvm_unreachable("unimplemented opcode in EncodeInstruction()");
	const MCInstrDesc &Desc = MCII.get(MI.getOpcode());
	uint64_t TSFlags = Desc.TSFlags;
	std::cout << "TS Flag is" << TSFlags << std::endl;
	// Pseudo instructions don¡¯t get encoded and shouldn¡¯t be here
	// in the first place!

	//if ((TSFlags & DSPII::FrmMask) == DSPII::Pseudo)
		//llvm_unreachable("Pseudo opcode found in EncodeInstruction()");


	// For now all instructions are 4 bytes
	int Size = 4; // FIXME: Have Desc.getSize() return the correct value!
	EmitInstruction(Binary, Size, OS);
}

/// getBranch16TargetOpValue - Return binary encoding of the branch
/// target operand. If the machine operand requires relocation,
/// record the relocation and return zero.
unsigned DSPMCCodeEmitter::
getBranch16TargetOpValue(const MCInst &MI, unsigned OpNo,
SmallVectorImpl<MCFixup> &Fixups,
const MCSubtargetInfo &STI) const {
	return 0;
}
/// getBranch24TargetOpValue - Return binary encoding of the branch
/// target operand. If the machine operand requires relocation,
/// record the relocation and return zero.
unsigned DSPMCCodeEmitter::
getBranch24TargetOpValue(const MCInst &MI, unsigned OpNo,
SmallVectorImpl<MCFixup> &Fixups,
const MCSubtargetInfo &STI) const {
	return 0;
}
/// getJumpTargetOpValue - Return binary encoding of the jump
/// target operand, such as JSUB.
/// If the machine operand requires relocation,
/// record the relocation and return zero.
unsigned DSPMCCodeEmitter::
getJumpTargetOpValue(const MCInst &MI, unsigned OpNo,
SmallVectorImpl<MCFixup> &Fixups,
const MCSubtargetInfo &STI) const {
	return 0;
}


unsigned DSPMCCodeEmitter::
getExprOpValue(const MCExpr *Expr, SmallVectorImpl<MCFixup> &Fixups,
const MCSubtargetInfo &STI) const {
	MCExpr::ExprKind Kind = Expr->getKind();
	if (Kind == MCExpr::Binary) {
		Expr = static_cast<const MCBinaryExpr*>(Expr)->getLHS();
		Kind = Expr->getKind();
	}
	assert(Kind == MCExpr::SymbolRef);
	// All of the information is in the fixup.
	return 0;
}
/// getMachineOpValue - Return binary encoding of operand. If the machine
/// operand requires relocation, record the relocation and return zero.
unsigned DSPMCCodeEmitter::
getMachineOpValue(const MCInst &MI, const MCOperand &MO,
SmallVectorImpl<MCFixup> &Fixups,
const MCSubtargetInfo &STI) const {
	if (MO.isReg()) {
		unsigned Reg = MO.getReg();
		unsigned RegNo = getDSPRegisterNumbering(Reg);
		return RegNo;
	}
	else if (MO.isImm()) {
		return static_cast<unsigned>(MO.getImm());
	}
	else if (MO.isFPImm()) {
		return static_cast<unsigned>(APFloat(MO.getFPImm())
			.bitcastToAPInt().getHiBits(32).getLimitedValue());
	}
	// MO must be an Expr.
	assert(MO.isExpr());
	return getExprOpValue(MO.getExpr(), Fixups, STI);
}

/// getMemEncoding - Return binary encoding of memory related operand.
/// If the offset operand requires relocation, record the relocation.
unsigned
DSPMCCodeEmitter::getMemEncoding(const MCInst &MI, unsigned OpNo,
SmallVectorImpl<MCFixup> &Fixups,
const MCSubtargetInfo &STI) const {
	// Base register is encoded in bits 20-16, offset is encoded in bits 15-0.
	assert(MI.getOperand(OpNo).isReg());
	unsigned RegBits = getMachineOpValue(MI, MI.getOperand(OpNo), Fixups, STI) << 16;
	unsigned OffBits = getMachineOpValue(MI, MI.getOperand(OpNo + 1), Fixups, STI);
	return (OffBits & 0xFFFF) | RegBits;
}

#include "DSPGenMCCodeEmitter.inc"