//===-- DSP.h - Top-level interface for DSP representation ----*- C++ -*-===//
//
// The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in
// the LLVM DSP back-end.
//
//===----------------------------------------------------------------------===//
#ifndef TARGET_DSP_H
#define TARGET_DSP_H
#include "MCTargetDesc/DSPMCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"
namespace llvm {
class DSPTargetMachine;
class FunctionPass;
FunctionPass *createDSPISelDag(DSPTargetMachine &TM);

} // end namespace llvm;
#endif