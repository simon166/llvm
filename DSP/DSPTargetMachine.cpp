//===-- DSPTargetMachine.cpp - Define TargetMachine for DSP -------------===//
//
// The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Implements the info about DSP target spec.
//
//===----------------------------------------------------------------------===//
#include "DSPTargetMachine.h"
#include "DSP.h"
#include "llvm/PassManager.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;
#define DEBUG_TYPE "dsp"
extern "C" void LLVMInitializeDSPTarget() {
	//- Little endian Target Machine
	RegisterTargetMachine<DSPelTargetMachine> X(TheDSPelTarget);
}

// DataLayout --> Big-endian, 32-bit pointer/ABI/alignment
// The stack is always 8 byte aligned
// On function prologue, the stack is created by decrementing
// its pointer. Once decremented, all references are done with positive
// offset from the stack/frame pointer, using StackGrowsUp enables
// an easier handling.
// Using CodeModel::Large enables different CALL behavior.
DSPTargetMachine::
DSPTargetMachine(const Target &T, 
					StringRef TT,
					StringRef CPU, 
					StringRef FS, 
					const TargetOptions &Options,
					Reloc::Model RM, 
					CodeModel::Model CM,
					CodeGenOpt::Level OL,
					bool isLittle)
//- Default is big endian
: LLVMTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL),
Subtarget(nullptr), DefaultSubtarget(TT, CPU, FS, isLittle, RM, this) {
	Subtarget = &DefaultSubtarget;
	initAsmInfo();
}

void DSPelTargetMachine::anchor() { }

DSPelTargetMachine::DSPelTargetMachine(const Target &T, 
										StringRef TT,
										StringRef CPU, 
										StringRef FS, 
										const TargetOptions &Options,
										Reloc::Model RM, 
										CodeModel::Model CM,
										CodeGenOpt::Level OL)
: DSPTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL, true) {}

namespace {
	/// DSP Code Generator Pass Configuration Options.
	class DSPPassConfig : public TargetPassConfig {
	public:
		DSPPassConfig(DSPTargetMachine *TM, PassManagerBase &PM)
			: TargetPassConfig(TM, PM) {}
		DSPTargetMachine &getDSPTargetMachine() const {
			return getTM<DSPTargetMachine>();
		}
		const DSPSubtarget &getDSPSubtarget() const {
			return *getDSPTargetMachine().getSubtargetImpl();
		}

		virtual bool addInstSelector();

	};
	bool DSPPassConfig::addInstSelector(){
		addPass(createDSPISelDag(getDSPTargetMachine()));
		return false;
	}

} // namespace

TargetPassConfig *DSPTargetMachine::createPassConfig(PassManagerBase &PM) {
	return new DSPPassConfig(this, PM);
}