//===-- DSPInstrInfo.cpp - DSP Instruction Information --------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the DSP implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "DSPInstrInfo.h"
#include "DSP.h"
#include "DSPSubtarget.h"
#include "DSPTargetMachine.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/CodeGen/LiveVariables.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineDominators.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/StackMaps.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetOptions.h"
#include <limits>

using namespace llvm;

//#define DEBUG_TYPE "dsp-instr-info"

#define GET_INSTRINFO_CTOR_DTOR
#include "DSPGenInstrInfo.inc"

void DSPInstrInfo::anchor(){}


DSPInstrInfo::DSPInstrInfo(const DSPSubtarget &STI) :Subtarget(STI){};

const DSPInstrInfo *DSPInstrInfo::create(const DSPSubtarget &STI){
	return llvm::createDSPSEInstrInfo(STI);

}
MachineInstr*
DSPInstrInfo::emitFrameIndexDebugValue(MachineFunction &MF, int FrameIx,
uint64_t Offset, const MDNode *MDPtr,
DebugLoc DL) const {
	MachineInstrBuilder MIB = BuildMI(MF, DL, get(DSP::DBG_VALUE))
		.addFrameIndex(FrameIx).addImm(0).addImm(Offset).addMetadata(MDPtr);
	return &*MIB;
}

