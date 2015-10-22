//===-- DSPISelDAGToDAG.cpp - A dag to dag inst selector for DSP ------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines an instruction selector for the DSP target.
//
//===----------------------------------------------------------------------===//


#include "DSPSEISelDAGToDAG.h"
#include "DSP.h"
#include "DSPISelDAGToDAG.h"
#include "DSPRegisterInfo.h"
#include "DSPMachineFunction.h"
#include "MCTargetDesc/DSPBaseInfo.h"
#include "DSPTargetMachine.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Type.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/CodeGen/SelectionDAGNodes.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

#define DEBUG_TYPE "dsp-isel"
//===----------------------------------------------------------------------===//
// Instruction Selector Implementation
//===----------------------------------------------------------------------===//
//===----------------------------------------------------------------------===//
// DSPDAGToDAGISel - DSP specific code to select DSP machine
// instructions for SelectionDAG operations.
//===----------------------------------------------------------------------===//

bool DSPDAGToDAGISel::runOnMachineFunction(MachineFunction &MF) {
	bool Ret = SelectionDAGISel::runOnMachineFunction(MF);
	return Ret;
}

/// ComplexPattern used on DSPInstrInfo
/// Used on DSP Load/Store instructions
bool DSPDAGToDAGISel::
SelectAddr(SDNode *Parent, SDValue Addr, SDValue &Base, SDValue &Offset) {
	DEBUG(dbgs() << "select addrmode" << "\n");
	EVT ValTy = Addr.getValueType();
	// If Parent is an unaligned f32 load or store, select a (base + index)
	// floating point load/store instruction (luxc1 or suxc1).
	const LSBaseSDNode* LS = 0;
	DEBUG(dbgs() << "233333333" << "\n");
	if (Parent && (LS = dyn_cast<LSBaseSDNode>(Parent))) {
		EVT VT = LS->getMemoryVT();
		if (VT.getSizeInBits() / 8 > LS->getAlignment()) {
			assert(getTargetLowering()->allowsUnalignedMemoryAccesses(VT) &&
				"Unaligned loads/stores not supported for this type.");
			if (VT == MVT::f32)
				return false;
		}
	}
	DEBUG(dbgs() << "133333333" << "\n");
	// if Address is FI, get the TargetFrameIndex.
	if (FrameIndexSDNode *FIN = dyn_cast<FrameIndexSDNode>(Addr)) {
		Base = CurDAG->getTargetFrameIndex(FIN->getIndex(), ValTy);
		Offset = CurDAG->getTargetConstant(0, ValTy);
		return true;
	}
	Base = Addr;
	Offset = CurDAG->getTargetConstant(0, ValTy);
	return true;
}




/// Select instructions not customized! Used for
/// expanded, promoted and normal instructions
SDNode* DSPDAGToDAGISel::Select(SDNode *Node) {
	unsigned Opcode = Node->getOpcode();
	// Dump information about the Node being selected
	DEBUG(errs() << "Selecting: "; Node->dump(CurDAG); errs() << "\n");
	DEBUG(dbgs() << "this is select " << "\n");
	// If we have a custom node, we already have selected!
	if (Node->isMachineOpcode()) {
		DEBUG(errs() << "== "; Node->dump(CurDAG); errs() << "\n"); Node->setNodeId(-1);
		return nullptr;
	}
	DEBUG(dbgs() << "433333333" << "\n");
	// See if subclasses can handle this node.
	std::pair<bool, SDNode*> Ret = selectNode(Node);
	if (Ret.first)
		return Ret.second;
	// Select the default instruction
	SDNode *ResNode = SelectCode(Node);
	DEBUG(errs() << "=> ");
	if (ResNode == NULL || ResNode == Node)
		DEBUG(Node->dump(CurDAG));
	else
		DEBUG(ResNode->dump(CurDAG));
	DEBUG(errs() << "\n");
	DEBUG(dbgs() << "533333333" << "\n");
	return ResNode;
}
/// createDSPISelDag - This pass converts a legalized DAG into a
/// DSP-specific DAG, ready for instruction scheduling.
FunctionPass *llvm::createDSPISelDag(DSPTargetMachine &TM) {
	return llvm::createDSPSEISelDag(TM);
}