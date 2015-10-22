
//===- DSPInstrInfo.td - Target Description for DSP Target -*- tablegen -*-=//
//
// The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the DSP implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//
//===----------------------------------------------------------------------===//
// DSP profiles and nodes
//===----------------------------------------------------------------------===//


def SDT_DSPRet : SDTypeProfile<0, 1, [SDTCisInt<0>]>;
def SDT_DSPVec : SDTypeProfile<1, 4,[SDTCisSameAs<4,1>,SDTCisSameAs<3,1>,SDTCisSameAs<2,1>,SDTCisInt<1>,SDTCisVec<0>]>;

def SDTDSPVecOp : SDTypeProfile<1,2,[SDTCisVec<1>,SDTCisVec<0>]>;
def SDT_DSPWrapper :SDTypeProfile<1,1,[SDTCisSameAs<0,1>,SDTCisPtrTy<0>]>;

def SDT_DSPJmpLink      : SDTypeProfile<0, 1, [SDTCisVT<0, iPTR>]>;

def SDT_DSPCallSeqStart : SDCallSeqStart<[SDTCisVT<0, i32>]>;
def SDT_DSPCallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;

// Call
def DSPJmpLink : SDNode<"DSPISD::JmpLink",SDT_DSPJmpLink,
                         [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue,
                          SDNPVariadic]>;

//def DSPTailCall : SDNode<"DSPISD::TailCall", SDT_DSPJmpLink,
//                          [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// Return
def DSPRet : SDNode<"DSPISD::RET", SDTNone,
[SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_DSPCallSeqStart,
                           [SDNPHasChain, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END", SDT_DSPCallSeqEnd,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def DSPV4 : SDNode<"DSPISD::BUILDVECTOR4",SDT_DSPVec,[SDNPVariadic]>;


def DSPMAX : SDNode<"DSPISD::MAX",SDTIntBinOp,[SDNPCommutative]>;
def DSPMIN : SDNode<"DSPISD::MIN",SDTIntBinOp,[SDNPCommutative]>;


def DSPVMAX10 : SDNode<"DSPISD::VMAX10",SDTDSPVecOp,[SDNPCommutative]>;
def DSPVMAX20 : SDNode<"DSPISD::VMAX20",SDTDSPVecOp,[SDNPCommutative]>;
def DSPVMAX40 : SDNode<"DSPISD::VMAX40",SDTDSPVecOp,[SDNPCommutative]>;
def DSPVMIN10 : SDNode<"DSPISD::VMIN10",SDTDSPVecOp,[SDNPCommutative]>;
def DSPVMIN20 : SDNode<"DSPISD::VMIN20",SDTDSPVecOp,[SDNPCommutative]>;
def DSPVMIN40 : SDNode<"DSPISD::VMIN40",SDTDSPVecOp,[SDNPCommutative]>;
def DSPVSUM : SDNode<"DSPISD::VSUM",SDTDSPVecOp,[SDNPCommutative]>;

def DSPHi : SDNode<"DSPISD::Hi",SDTIntUnaryOp>;
def DSPLo : SDNode<"DSPISD::Lo",SDTIntUnaryOp>;
def DSPGPRel : SDNode<"DSPISD::GPRel",SDTIntUnaryOp>;
def DSPWrapper : SDNode<"DSPISD::Wrapper",SDT_DSPWrapper>;


//class IsTailCall {
 // bit isCall = 1;
 // bit isTerminator = 1;
 // bit isReturn = 1;
 // bit isBarrier = 1;
 // bit hasExtraSrcRegAllocReq = 1;
  //bit isCodeGenOnly = 1;
//}


//===----------------------------------------------------------------------===//
// Instruction format superclass
//===----------------------------------------------------------------------===//
include "DSPInstrFormats.td"

//===----------------------------------------------------------------------===//
// DSP Operand, Complex Patterns and Transformations Definitions.
//===----------------------------------------------------------------------===//
// Instruction operand types
// Signed Operand
def simm16 : Operand<i32> {
let DecoderMethod= "DecodeSimm16";
}
def calltarget  : Operand<iPTR> {
  let EncoderMethod = "getJumpTargetOpValue";
}
def jmptarget    : Operand<OtherVT> {
  let EncoderMethod = "getJumpTargetOpValue";
  let OperandType = "OPERAND_PCREL";
  let DecoderMethod = "DecodeJumpRelativeTarget";
}
def simm5 :Operand<i32> {
let DecoderMethod= "DecodeSimm5";
}
def simm9 :Operand<i32> {
let DecoderMethod= "DecodeSimm9";
}
// Address operand
def mem : Operand<i32> {
let PrintMethod = "printMemOperandEA";
let MIOperandInfo = (ops CPURegs, simm16);
let EncoderMethod = "getMemEncoding";
}

def brtarget : Operand<OtherVT>{
let OperandType = "OPERAND_PCREL";
}




// Node immediate fits as 16-bit sign extended on target immediate.
// e.g. addi, andi
def immSExt16 : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;
def immSExt9 : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;
def immSExt5 : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;

def shamt : Operand<i32>;
// Unsigned Operand
def uimm16 : Operand<i32> {
let PrintMethod = "printUnsignedImm";
}




// DSP Address Mode! SDNode frameindex could possibily be a match
// since load and store instructions from stack used it.
def addr : ComplexPattern<iPTR, 2, "SelectAddr", [frameindex], [SDNPWantParent]>;

class AlignedLoad<PatFrag Node> :
PatFrag<(ops node:$ptr), (Node node:$ptr), [{
LoadSDNode *LD = cast<LoadSDNode>(N);
return LD->getMemoryVT().getSizeInBits()/8 <= LD->getAlignment();
}]>;
class AlignedStore<PatFrag Node> :
PatFrag<(ops node:$val, node:$ptr), (Node node:$val, node:$ptr), [{
StoreSDNode *SD = cast<StoreSDNode>(N);
return SD->getMemoryVT().getSizeInBits()/8 <= SD->getAlignment();
}]>;
// Load/Store PatFrags.
def load_a : AlignedLoad<load>;
def store_a : AlignedStore<store>;



class DSPInstAlias<string Asm, dag Result, bit Emit = 0b1> :
InstAlias<Asm, Result, Emit>;



// Transformation Function - get the lower 16 bits.
def LO16 : SDNodeXForm<imm, [{
return getImm(N, N->getZExtValue() & 0xffff);
}]>;
// Transformation Function - get the higher 16 bits.
def HI16 : SDNodeXForm<imm, [{
return getImm(N, (N->getZExtValue() >> 16) & 0xffff);
}]>;

// Node immediate fits as 16-bit zero extended on target immediate.
// The LO16 param means that only the lower 16 bits of the node
// immediate are caught.
// e.g. addiu, sltiu
def immZExt16 : PatLeaf<(imm), [{
if (N->getValueType(0) == MVT::i32)
return (uint32_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
else
return (uint64_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
}], LO16>;
// Immediate can be loaded with LUi (32-bit int with lower 16-bit cleared).
def immLow16Zero : PatLeaf<(imm), [{
int64_t Val = N->getSExtValue();
return isInt<32>(Val) && !(Val & 0xffff);
}]>;

// shamt field must fit in 5 bits.
def immZExt5 : ImmLeaf<i32, [{return Imm == (Imm & 0x1f);}]>;



//===----------------------------------------------------------------------===//
// Instructions specific format
//===----------------------------------------------------------------------===//

class shift_rotate_imm<bits<3> typeop,bits <3> op,bits<8> inner_op, bits<4> isRotate, string instr_asm,
SDNode OpNode, PatFrag PF, Operand ImmOpnd,
RegisterClass RC>:
R3<typeop,op,inner_op, (outs GPROut:$ra), (ins RC:$rb, ImmOpnd:$shamt),
!strconcat(instr_asm, "\t$ra, $rb, $shamt"),
[(set GPROut:$ra, (OpNode RC:$rb, PF:$shamt))], IIAlu> {
let rt = 0;
}
// 32-bit shift instructions.
class shift_rotate_imm32<bits<3> typeop, bits<3> op,bits<8> inner_op, bits<4> isRotate, string instr_asm,
SDNode OpNode>:
shift_rotate_imm<typeop, op, inner_op,isRotate, instr_asm, OpNode, immZExt5, shamt, CPURegs>;


// Arithmetic and logical instructions with 2 register operands.
class ArithLogicI<bits<3> typeop, bits<3> op, bits<4> inner_op,string instr_asm, SDNode OpNode,
Operand Od, PatLeaf imm_type, RegisterClass RC> :
R1<typeop,op,inner_op, (outs GPROut:$ra), (ins RC:$rb, Od:$imm16),
!strconcat(instr_asm, "\t$ra, $rb, $imm16"),
[(set GPROut:$ra, (OpNode RC:$rb, imm_type:$imm16))],IIAlu> {
let isReMaterializable = 1;
}

//Arithmetic and logical instructions with 2 reg
class ArithLogicR2i5<bits<3> typeop, bits<3> op, bits<5> inner_op,string instr_asm, PatFrag OpNode,
InstrItinClass itin, RegisterClass RC, bit isComm = 0>:
R2i5<typeop,op,inner_op, (outs GPROut:$ra), (ins RC:$rb, RC:$rc),
!strconcat(instr_asm, "\t$ra, $rb, $rc"),
[(set GPROut:$ra, (OpNode RC:$rb, RC:$rc))], itin> 
{
let imm = 0b11111111;
//let isCommutable = isComm; // e.g. add rb rc = add rc rb
let isReMaterializable = 1;
}

// Arithmetic and logical instructions with 3 register operands.
class ArithLogicR<bits<3> typeop, bits<3> op, bits<8> inner_op,string instr_asm, SDNode OpNode,
InstrItinClass itin, RegisterClass RC, bit isComm = 0>:
R3<typeop,op,inner_op, (outs GPROut:$ra), (ins RC:$rb, RC:$rc),
!strconcat(instr_asm, "\t$ra, $rb, $rc"),
[(set GPROut:$ra, (OpNode RC:$rb, RC:$rc))], itin> {
let isCommutable = isComm; // e.g. add rb rc = add rc rb
let isReMaterializable = 1;
}

// Arithmetic and logical instructions with 3 register operands.
class VArithLogicR<bits<3> typeop, bits<3> op, bits<8> inner_op,string instr_asm, SDNode OpNode,
InstrItinClass itin, RegisterClass RC, bit isComm = 0>:
R3<typeop,op,inner_op, (outs RC:$ra), (ins RC:$rb, RC:$rc),
!strconcat(instr_asm, "\t$ra, $rb, $rc"),
[(set RC:$ra, (OpNode RC:$rb, RC:$rc))], itin> {
let isCommutable = isComm; // e.g. add rb rc = add rc rb
let isReMaterializable = 1;
}


class Mult<bits<3> typeop,bits<3> op,bits<8> inner_op, string instr_asm, InstrItinClass itin,
RegisterClass RC, list<Register> DefRegs>:
R3<typeop, op,inner_op, (outs), (ins RC:$ra, RC:$rb),
!strconcat(instr_asm, "\t$ra, $rb"), [], itin> {
let isCommutable = 1;
let Defs = DefRegs;
let neverHasSideEffects = 1;
}
class Mult32<bits<3> typeop,bits<3> op,bits<8> inner_op, string instr_asm, InstrItinClass itin>:
Mult<typeop, op,inner_op, instr_asm, itin, CPURegs, [HI, LO]>;


// Load Upper Imediate
class LoadUpper<bits<3> typeop, bits<3> op,bits<5> inner_op, string instr_asm, RegisterClass RC, Operand Imm>:
R2i5<typeop, op,inner_op, (outs RC:$ra), (ins Imm:$imm16),
!strconcat(instr_asm, "\t$ra, $imm16"), [], IIAlu> {
let rs = 0;
let neverHasSideEffects = 1;
let isReMaterializable = 1;
}


class FMem<bits<3> typeop, bits<3> op, bits<5> inner_op,dag outs, dag ins, string asmstr, list<dag> pattern,
InstrItinClass itin>: R2i5<typeop,op,inner_op, outs, ins, asmstr, pattern, itin> {
bits<20> addr;
let Inst{19-16} = addr{19-16};
let Inst{15-0} = addr{15-0};
let DecoderMethod = "DecodeMem";
}

// Memory Load/Store
let canFoldAsLoad = 1 in
class LoadM<bits<3> typeop,bits<3> op,bits<5> inner_op, string instr_asm, PatFrag OpNode, RegisterClass RC,
Operand MemOpnd, bit Pseudo>:
FMem<typeop, op,inner_op, (outs RC:$ra), (ins MemOpnd:$addr),
!strconcat(instr_asm, "\t$ra, $addr"),
[(set RC:$ra, (OpNode addr:$addr))], IILoad> {
let isPseudo = Pseudo;
}
class StoreM<bits<3> typeop, bits<3> op,bits<5> inner_op,  string instr_asm, PatFrag OpNode, RegisterClass RC,
Operand MemOpnd, bit Pseudo>:
FMem<typeop, op,inner_op, (outs), (ins RC:$ra, MemOpnd:$addr),
!strconcat(instr_asm, "\t$ra, $addr"),
[(OpNode RC:$ra, addr:$addr)], IIStore> {
let isPseudo = Pseudo;
}
// 32-bit load.
multiclass LoadM32<bits<3> typeop, bits<3> op,bits<5> inner_op,  string instr_asm, PatFrag OpNode,
bit Pseudo = 0> {
def #NAME# : LoadM<typeop, op,inner_op, instr_asm, OpNode, GPROut, mem, Pseudo>;
}
// 32-bit store.
multiclass StoreM32<bits<3> typeop, bits<3> op,bits<5> inner_op,  string instr_asm, PatFrag OpNode,
bit Pseudo = 0> {
def #NAME# : StoreM<typeop, op,inner_op, instr_asm, OpNode, CPURegs, mem, Pseudo>;
}

let isBranch=1, isTerminator=1, isBarrier=1, hasDelaySlot = 1,
isIndirectBranch = 1 in
class JumpFR<bits<3> typeop,bits<3> op,bits<4> inner_op,  string instr_asm, RegisterClass RC>:
R1<typeop,op,inner_op,(outs), (ins RC:$ra),
!strconcat(instr_asm, "\t$ra"), [(brind RC:$ra)], IIBranch> {

let imm = 0b11111111;
}

//mov

class SMovBase<bits<3> typeop,bits<3> op ,bits<4> inner_op, string instr_asm,RegisterClass RC,InstrItinClass itin>:
R1<typeop, op, inner_op,(outs GPROut:$ra), (ins RC:$rb,simm16:$imm),
!strconcat(instr_asm, "\t$ra,$imm"),[],itin>{
}



class MovBase<bits<3> typeop,bits<3> op ,bits<10> inner_op , string instr_asm,RegisterClass RC,RegisterClass RD,InstrItinClass itin>:
R2i10<typeop, op,inner_op, (outs), (ins RC:$ra,RD:$rs,uimm16:$imm),
!strconcat(instr_asm, "\t$ra,$rs,$imm"),[],itin>{
}

class RMovBase<bits<3> typeop,bits<3> op ,bits<10> inner_op, string instr_asm,RegisterClass RC,RegisterClass RD,InstrItinClass itin>:
R2i10<typeop, op,inner_op, (outs), (ins RC:$ra,RD:$rs),
!strconcat(instr_asm, "\t$ra,$rs"),[],itin>{
}


// Return instruction
class RetBase<RegisterClass RC>: JumpFR<0,3,9, "ret", RC> {
let isReturn = 1;
let isCodeGenOnly = 1;
let hasCtrlDep = 1;
let hasExtraSrcRegAllocReq = 1;
}


//Unconditional branch 
class UncondBranch<bits<3> typeop,bits<3> op, bits<5> inner_op, string instr_asm>:
R0<typeop,op,inner_op, (outs), (ins brtarget:$addr),
!strconcat(instr_asm, "\t$addr"), [(br bb:$addr)], IIBranch> {
let isBranch = 1;
let isTerminator = 1;
let isBarrier = 1;
let hasDelaySlot = 1;
}

class CBranch<bits<3> typeop, bits<3> op, bits<5> inner_op, string instr_asm>:
R0<typeop,op,inner_op, (outs), (ins CPURegs:$rt, brtarget:$addr),
!strconcat(instr_asm, "\t$addr"), [], IIBranch> {
let isBranch = 1;
let isTerminator = 1;
let isBarrier = 1;
let hasDelaySlot = 1;
}

//Intrinsic function base

class MMBase<bits<3> typeop,bits<3> op, bits<8> inner_op, string instr_asm, SDNode OpNode ,InstrItinClass itin, RegisterClass RC>
:R3<typeop,op,inner_op,(outs GPROut:$ra), (ins RC:$rb, RC:$rt),
!strconcat(instr_asm, "\t$ra, $rb, $rt"),
[(set GPROut:$ra, (OpNode RC:$rb, RC:$rt))],itin>{
let isCommutable = 1;
}

class VMMBase<bits<3> typeop,bits<3> op, bits<8> inner_op, string instr_asm, SDNode OpNode, InstrItinClass itin, RegisterClass RC>
:R3<typeop,op,inner_op,(outs VPR4Out:$ra), (ins RC:$rb, RC:$rt),
!strconcat(instr_asm, "\t$ra, $rb, $rt"),
[(set VPR4Out:$ra, (OpNode RC:$rb, RC:$rt))],itin>{
let isCommutable = 1;
}
//Logic formats

class SetCC_R<bits<3> typeop,bits<3> op, bits<8> inner_op, string instr_asm, PatFrag cond_op , RegisterClass RC>
:R3<typeop,op,inner_op,(outs GPROut:$ra), (ins RC:$rb, RC:$rt),
!strconcat(instr_asm, "\t$ra, $rb, $rt"),
[(set GPROut:$ra, (cond_op RC:$rb, RC:$rt))],IIAlu>{
let isCommutable = 1;
}

class SetCC_I<bits<3> type_op,bits<3> op, bits<5> inner_op, string instr_asm, PatFrag cond_op ,
 Operand Od, PatLeaf imm_type,RegisterClass RC>
:F_1Reg_imm9<type_op,op,inner_op,(outs GPROut:$ra), (ins RC:$rb, Od:$imm9),
!strconcat(instr_asm, "\t$ra, $rb, $imm9"),
[(set GPROut:$ra, (cond_op RC:$rb, imm_type:$imm9))],IIAlu>{
let isCommutable = 0;
}



// Memory Load/Store
/*
let canFoldAsLoad = 1 in
class Mem128<bits<3> typeop,bits<3> op, string instr_asm, SDNode OpNode,InstrItinClass itin, RegisterClass RC,
Operand MemOpnd, bit Pseudo>:
FMem<typeop, op, (outs), (ins RC:$ra ,MemOpnd:$addr),
!strconcat(instr_asm, "\t$ra, $addr"),
[ (OpNode RC:$ra, addr:$addr)], itin> {
let isPseudo = Pseudo;
}
*/

class StoreM128<bits<3> typeop,bits<3> op,bits<5> inner_op, string instr_asm, PatFrag OpNode,
 bit Pseudo =0>:StoreM<typeop, op,inner_op, instr_asm, OpNode, VPR4Out, mem, Pseudo>;

 let canFoldAsLoad = 1 in
class LoadM128<bits<3> typeop,bits<3> op,bits<5> inner_op, string instr_asm, PatFrag OpNode,
 bit Pseudo =0>:LoadM<typeop, op,inner_op, instr_asm, OpNode, VPR4Out, mem, Pseudo>;

class StoreM128_16<bits<3> typeop,bits<3> op,bits<5> inner_op, string instr_asm, PatFrag OpNode,
 bit Pseudo =0>:StoreM<typeop, op,inner_op, instr_asm, OpNode, VPR8Out, mem, Pseudo>;

 let canFoldAsLoad = 1 in
class LoadM128_16<bits<3> typeop,bits<3> op,bits<5> inner_op, string instr_asm, PatFrag OpNode,
 bit Pseudo =0>:LoadM<typeop, op,inner_op, instr_asm, OpNode, VPR8Out, mem, Pseudo>;

 class StoreM128_8<bits<3> typeop,bits<3> op,bits<5> inner_op, string instr_asm, PatFrag OpNode,
 bit Pseudo =0>:StoreM<typeop, op,inner_op, instr_asm, OpNode, VPR16Out, mem, Pseudo>;

 let canFoldAsLoad = 1 in
class LoadM128_8<bits<3> typeop,bits<3> op,bits<5> inner_op, string instr_asm, PatFrag OpNode,
 bit Pseudo =0>:LoadM<typeop, op,inner_op, instr_asm, OpNode, VPR16Out, mem, Pseudo>;





//def calltarget : Operand<iPTR>{
	//let EncodeMethod = "getJumpTargetOpValue";
//}

// Jump and Link (Call)
let isCall=1, hasDelaySlot=1 in {
  class JumpLink<bits<3> typeop, bits<3>op, bits<5> funct, string instr_asm>:
    F_Special_imm21<typeop, op, funct, (outs), (ins calltarget:$target, variable_ops),
       !strconcat(instr_asm, "\t$target"), [(DSPJmpLink imm:$target)],
       IIBranch> {
       }

  class JumpLinkReg<bits<3> typeop, bits<3>op, bits<8> funct, string instr_asm,
                    RegisterClass RC>:
    F_Special_1Reg_1<typeop, op, funct, (outs), (ins RC:$rs, variable_ops),
       !strconcat(instr_asm, "\t$rs"), [(DSPJmpLink RC:$rs)], IIBranch> {
  }
}

//let isCall = 1, isTerminator = 1, isReturn = 1, isBarrier = 1, hasDelaySlot = 1,
//    hasExtraSrcRegAllocReq = 1, Defs = [AT] in {
//  class TailCall<Instruction JumpInst> :
//    PseudoSE<(outs), (ins calltarget:$target), [], IIBranch>,
//    PseudoInstExpansion<(JumpInst jmptarget:$target)>;

//  class TailCallReg<RegisterClass RO, Instruction JRInst,
//                    RegisterClass ResRO = RO> :
//    PseudoSE<(outs), (ins RO:$rs), [(DSPTailCall RO:$rs)], IIBranch>,
//    PseudoInstExpansion<(JRInst ResRO:$rs)>;
//}

//specific DSP instructions
//******************************************specail instruction *************************************//
/// No operation
let imm=0 in
def NOP : R0<0,0,0, (outs), (ins), "nop", [],IIAlu>;


//***************************************************************************************************//

//*****************************************control instruction***************************************//

let isReturn=1, isTerminator=1, hasDelaySlot=1, isBarrier=1, hasCtrlDep=1 in
def RetLR : DSPPseudo<(outs), (ins), "", [(DSPRet)]>;
def Ret : RetBase<GPROut>;
def Jmp : UncondBranch<0,6,0b000000,"jmp">;
def JNC : CBranch<0,0,0b01001, "jnc">;


//def TAILCALL : TailCall<Jmp>;
//def TAILCALL_R : TailCallReg<GPROut, JmpR>;


//call callr
def CALL : JumpLink<0, 0, 0b01101, "call">;
def CALLR : JumpLinkReg<0, 0, 0b111, "callr", GPROut>;
//***************************************************************************************************//

//*****************************************data translation instruction******************************//
def MovVR : DSPPseudo<(outs VPR4Out:$ra), (ins GPROut:$imm16,GPROut:$imm2,GPROut:$imm3,GPROut:$imm4), "", [(set VPR4Out:$ra,(DSPV4 GPROut:$imm16,GPROut:$imm2,GPROut:$imm3,GPROut:$imm4))]>;
def MovGR : DSPPseudo<(outs GPROut:$ra), (ins CPURegs:$rs,simm16:$in), "", [(set GPROut:$ra, (add CPURegs:$rs, immSExt16:$in)) ]>;

def MovG2V40 : MovBase<0,3,0b00101,"movg2v40",VPR4Out,GPROut,IIVMax>;
def MovIGH : SMovBase<0,7,0b0000,"movigh",GPROut,IIAlu>;
def MovIGL : SMovBase<0,7,0b0001,"movigl",GPROut,IIAlu>;
def VMovG2V40 : RMovBase<0,5,0b10110,"vmovrg2v40",VPR4Out,GPROut,IIVMax>;
//***************************************************************************************************//



//**********************************************A&L instruction**************************************//
def ADDiu :ArithLogicI<0,1,0b00000001,"addi",add,simm16,immSExt16, CPURegs>;

def ADDu : ArithLogicR<0,1,0b00000000, "add", add, IIAlu, CPURegs, 1>;
def SUBu : ArithLogicR<0,1,0b00000010, "sub", sub, IIAlu, CPURegs, 1>;
def MUL : ArithLogicR<0,1,0b00001100,"mul32", mul, IIImul,CPURegs,1>;
//def ORi : ArithLogicI<0,1,0b00000101, "or", or, uimm16, immZExt16, CPURegs>;
def ORu :ArithLogicR<0,1,0b00000101,"or",or,IIAlu,CPURegs,1>;
def SHL : shift_rotate_imm32<0,1,0b00001001, 0x00, "sl", shl>;
def AND : ArithLogicR<0,1,0b00000100,"and", and, IIAlu,CPURegs,1>;
def XORu : ArithLogicR<0,1,0b00000110, "xor", xor, IIAlu, CPURegs,1>;


//def NOT  : ArithLogicR2i5<0,4,0b00111,"not",not,IIAlu,CPURegs,0>;
def EQ   :SetCC_R<0,4,0b000000000,"eq",seteq,CPURegs>;
def NEQ   :SetCC_R<0,4,0b00000001,"neq",setne,CPURegs>;
def GT   :SetCC_R<0,4,0b00000010,"gt",setgt,CPURegs>;
def GTU   :SetCC_R<0,4,0b00001010,"gtu",setugt,CPURegs>;
def GE   :SetCC_R<0,4,0b00000100,"ge",setge,CPURegs>;
def GEU   :SetCC_R<0,4,0b00001100,"geu",setuge,CPURegs>;
def LT   :SetCC_R<0,4,0b00000011,"lt",setlt,CPURegs>;
def LTU   :SetCC_R<0,4,0b00001011,"ltu",setult,CPURegs>;
def LE   :SetCC_R<0,4,0b00000101,"le",setle,CPURegs>;
def LEU   :SetCC_R<0,4,0b00001101,"leu",setule,CPURegs>;


def EQI   :SetCC_I<0,4,0b000000000,"eqi",seteq,simm9, immSExt9, CPURegs>;

def MAX  :MMBase<0,1,0b00000111,"max",DSPMAX,IIAlu,GPROut>;
def MIN  :MMBase<0,1,0b00001000,"min",DSPMIN,IIAlu,GPROut>;

//***************************************************************************************************//




//**************************************memory instruction*******************************************//
/// Load and Store Instructions
defm LD : LoadM32<0,2,0b00010, "load32", load_a>;
defm ST : StoreM32<0,3,2, "store32", store_a>;
def LUi : LoadUpper<0,2,0b00011, "lui", GPROut, uimm16>;
def LU : DSPPseudo<(outs CPURegs:$ra), (ins uimm16:$in), "", []>;

def VSTORE32 : StoreM128<0,3,0b10101,"vstore32",store_a>;
def VLOAD32 : LoadM128<0,2,0b10001,"vload32",load_a>;
def VSTORE16 : StoreM128_16<0,3,0b10110,"vstore16",store_a>;
def VLOAD16 : LoadM128_16<0,2,0b10010,"vload16",load_a>;
def VSTORE8 : StoreM128_8<0,3,0b10111,"vstore8",store_a>;
def VLOAD8 : LoadM128_8<0,2,0b10011,"vload8",load_a>;
//***************************************************************************************************//

//===----------------------------------------------------------------------===//
// Arbitrary patterns that map to one or more instructions
//===----------------------------------------------------------------------===//
/*def : Pat<(i32 immSExt16:$in),
(ADDiu ZERO, imm:$in)>;*/
def :Pat<(i32 immSExt16:$in),
(MovGR ZERO , imm:$in)>;
def :Pat<(DSPHi tglobaladdr:$in),(MovIGH  ZERO, tglobaladdr:$in)>;
def :Pat<(add CPURegs:$hi, (DSPLo tglobaladdr:$lo)),
		(MovIGL CPURegs:$hi, tglobaladdr:$lo)>;
def :Pat<(add CPURegs:$gp,(DSPGPRel tglobaladdr:$in)),
		(ADDiu CPURegs:$gp, tglobaladdr:$in)>;
def :Pat<(i32(DSPWrapper tconstpool:$dst)),(MovGR ZERO, tconstpool:$dst)>;


// brcond for cmp instruction
multiclass BrcondPatsCmp<RegisterClass RC, Instruction JNEOp, 
Instruction CMPOp, Register ZEROReg> {

def : Pat<(brcond (i32 (setne RC:$lhs, RC:$rhs)), bb:$dst),
          (JNEOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setune RC:$lhs, RC:$rhs)), bb:$dst),
          (JNEOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond RC:$cond, bb:$dst),
          (JNEOp (CMPOp RC:$cond, ZEROReg), bb:$dst)>;
}
defm : BrcondPatsCmp<CPURegs, JNC, EQ, ZERO>;

def : Pat<(DSPJmpLink (i32 tglobaladdr:$dst)),
          (CALL tglobaladdr:$dst)>;
def : Pat<(DSPJmpLink (i32 texternalsym:$dst)),
          (CALL texternalsym:$dst)>;

// Tail call
//def : Pat<(DSPTailCall (iPTR tglobaladdr:$dst)),
//              (TAILCALL tglobaladdr:$dst)>;
//def : Pat<(DSPTailCall (iPTR texternalsym:$dst)),
 //             (TAILCALL texternalsym:$dst)>;


multiclass SeteqPats<RegisterClass RC,Instruction EQ, Instruction NEQ> {
// a == b
def : Pat<(seteq RC:$lhs, RC:$rhs),
(EQ RC:$lhs,RC:$rhs)>;
// a != b
def : Pat<(setne RC:$lhs, RC:$rhs),
(NEQ RC:$lhs,RC:$rhs)>;
}


// a < b
multiclass SetltPats<RegisterClass RC> {
def : Pat<(setlt RC:$lhs, RC:$rhs),
(LT RC:$lhs,RC:$rhs)>;
def : Pat<(setult RC:$lhs, RC:$rhs),
(LTU RC:$lhs,RC:$rhs)>;
}

// a <= b
multiclass SetlePats<RegisterClass RC> {
def : Pat<(setle RC:$lhs, RC:$rhs),
(LE RC:$lhs,RC:$rhs)>;
def : Pat<(setule RC:$lhs, RC:$rhs),
(LEU RC:$lhs,RC:$rhs)>;
}
// a > b
multiclass SetgtPats<RegisterClass RC> {
def : Pat<(setgt RC:$lhs, RC:$rhs),
(GT RC:$lhs,RC:$rhs)>;
def : Pat<(setugt RC:$lhs, RC:$rhs),
(GTU RC:$lhs,RC:$rhs)>;
}

// a >= b
multiclass SetgePats<RegisterClass RC> {
def : Pat<(setge RC:$lhs, RC:$rhs),
(GE RC:$lhs,RC:$rhs)>;
def : Pat<(setuge RC:$lhs, RC:$rhs),
(GEU RC:$lhs,RC:$rhs)>;
}

defm : SeteqPats<CPURegs,EQ,NEQ>;
defm : SetltPats<CPURegs>;
defm : SetlePats<CPURegs>;
defm : SetgtPats<CPURegs>;
defm : SetgePats<CPURegs>;


//===----------------------------------------------------------------------===//
// Pseudo instructions
//===----------------------------------------------------------------------===//


// As stack alignment is always done with addiu, we need a 16-bit immediate
let Defs = [SP], Uses = [SP] in {
def ADJCALLSTACKDOWN : DSPPseudo<(outs), (ins uimm16:$amt),
                                  "!ADJCALLSTACKDOWN $amt",
                                  [(callseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : DSPPseudo<(outs), (ins uimm16:$amt1, uimm16:$amt2),
                                  "!ADJCALLSTACKUP $amt1",
                                  [(callseq_end timm:$amt1, timm:$amt2)]>;
}

// When handling PIC code the assembler needs .cpload and .cprestore
// directives. If the real instructions corresponding these directives
// are used, we have the same behavior, but get also a bunch of warnings
// from the assembler.
let neverHasSideEffects = 1 in
def CPRESTORE : DSPPseudo<(outs), (ins i32imm:$loc, CPURegs:$gp),
                           ".cprestore\t$loc", []>;



//****************************************vector instruction*****************************************//
//Instrinsic function operation

def VMAX10 :VMMBase<0,1,0b01001001,"vmax.10",DSPVMAX10,IIVMax,VPR16Out>;
def VMAX20 :VMMBase<0,1,0b01001001,"vmax.20",DSPVMAX20,IIVMax,VPR8Out>;
def VMAX40 :VMMBase<0,1,0b01001001,"vmax.40",DSPVMAX40,IIVMax,VPR4Out>;
def VMIN10 :VMMBase<0,1,0b01001101,"vmin.10",DSPVMIN10,IIVMax,VPR16Out>;
def VMIN20 :VMMBase<0,1,0b01001101,"vmin.20",DSPVMIN20,IIVMax,VPR8Out>;
def VMIN40 :VMMBase<0,1,0b01001101,"vmin.40",DSPVMIN40,IIVMax,VPR4Out>;

def VADD32 :VArithLogicR<0,1,0b01000001,"vadd.40",add,IIVMax,VPR4Out,1>;
def VADD16 :VArithLogicR<0,1,0b01000010,"vadd.16",add,IIVMax,VPR8Out,1>;
def VADD8 :VArithLogicR<0,1,0b01000011,"vadd.8",add,IIVMax,VPR16Out,1>;
def VSUB32 :VArithLogicR<0,1,0b01000101,"vsub.40",sub,IIVMax,VPR4Out,0>;
def VSUB16 :VArithLogicR<0,1,0b01000110,"vsub.16",sub,IIVMax,VPR8Out,0>;
def VSUB8 :VArithLogicR<0,1,0b01000111,"vsub.8",sub,IIVMax,VPR16Out,0>;
//***************************************************************************************************//



class Abs_Fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, 
                  InstrItinClass itin, RegisterClass RC, bit isComm = 0>:
  F_2Reg_2<type, op, funct, (outs GPROut:$ra), (ins RC:$rb),
     !strconcat(instr_asm, "\t$ra, $rb"),
     [(set GPROut:$ra, (int_dsp_abs_qb RC:$rb))], itin> {
  let isCommutable = isComm;	// e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}

def ABS :Abs_Fmt<0x0,0x4,0x45, "abs", IIAlu, CPURegs, 0>;

class Test_Fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, 
                  InstrItinClass itin, RegisterClass RC, bit isComm = 0>:
  F_2Reg_2<type, op, funct, (outs GPROut:$ra), (ins RC:$rb),
     !strconcat(instr_asm, "\t$rb"),
     [(set GPROut:$ra, (int_dsp_test_qb RC:$rb))], itin> {
  let isReMaterializable = 1;
}
def TEST :Test_Fmt<0x0,0x4,0x46, "test", IIAlu, CPURegs, 0>;

class Testi_Fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, 
                  InstrItinClass itin, RegisterClass RC, bit isComm = 0>:
  F_2Reg_2<type, op, funct, (outs GPROut:$ra), (ins RC:$rb),
     !strconcat(instr_asm, "\t$rb"),
     [(set GPROut:$ra, (int_dsp_testi_qb RC:$rb))], itin> {
  let isReMaterializable = 1;
}
def TESTI :Testi_Fmt<0x0,0x4,0x47, "testi", IIAlu, CPURegs, 0>;

class Cbw_Fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, 
                  InstrItinClass itin, RegisterClass RC, bit isComm = 0>:
  F_2Reg_2<type, op, funct, (outs GPROut:$ra), (ins RC:$rb),
     !strconcat(instr_asm, "\t$ra, $rb"),
     [(set GPROut:$ra, (int_dsp_cbw_qb RC:$rb))], itin> {
  let isReMaterializable = 1;
}
def CBW :Cbw_Fmt<0x0,0x4,0x46, "cbw", IIAlu, CPURegs, 0>;

class Chw_Fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, 
                  InstrItinClass itin, RegisterClass RC, bit isComm = 0>:
  F_2Reg_2<type, op, funct, (outs GPROut:$ra), (ins RC:$rb),
     !strconcat(instr_asm, "\t$ra, $rb"),
     [(set GPROut:$ra, (int_dsp_chw_qb RC:$rb))], itin> {
  let isReMaterializable = 1;
}
def CHW :Chw_Fmt<0x0,0x4,0x47, "chw", IIAlu, CPURegs, 0>;

class bfext_fmt<bits<3> type, bits<3> op, bits<4> funct, string instr_asm, InstrItinClass itin, Operand Od, PatLeaf imm_type, RegisterClass RC, bit isComm = 0>:
	F_2Reg_2imm5<type, op, funct, (outs GPROut:$ra), (ins RC:$rb, Od:$imm5_2, Od:$imm5_1),
	   !strconcat(instr_asm, "\t$ra, $rb, $imm5_2, $imm5_1"),
     [(set GPROut:$ra, (int_dsp_bfext_qb RC:$rb, imm_type:$imm5_2, imm_type:$imm5_1))], itin> {
  
}

def BFEXT : bfext_fmt<0x0, 0x6, 0x1, "bfext", IIAlu, simm5, immSExt5,  CPURegs, 0>;

class bfextu_fmt<bits<3> type, bits<3> op, bits<4> funct, string instr_asm, InstrItinClass itin, Operand Od, PatLeaf imm_type, RegisterClass RC, bit isComm = 0>:
	F_2Reg_2imm5<type, op, funct, (outs GPROut:$ra), (ins RC:$rb, Od:$imm5_2, Od:$imm5_1),
	   !strconcat(instr_asm, "\t$ra, $rb, $imm5_2, $imm5_1"),
     [(set GPROut:$ra, (int_dsp_bfextu_qb RC:$rb, imm_type:$imm5_2, imm_type:$imm5_1))], itin> {
  
}

def BFEXTU : bfextu_fmt<0x0, 0x6, 0x1, "bfextu", IIAlu, simm5, immSExt5,  CPURegs, 0>;

class bfst_fmt<bits<3> type, bits<3> op, bits<4> funct, string instr_asm, InstrItinClass itin, Operand Od, PatLeaf imm_type, RegisterClass RC, bit isComm = 0>:
	F_2Reg_2imm5<type, op, funct, (outs GPROut:$ra), (ins RC:$rb, Od:$imm5_2, Od:$imm5_1),
	   !strconcat(instr_asm, "\t$ra, $rb, $imm5_2, $imm5_1"),
     [(set GPROut:$ra, (int_dsp_bfst_qb RC:$rb, imm_type:$imm5_2, imm_type:$imm5_1))], itin> {
  
}

def BFST : bfst_fmt<0x0, 0x6, 0x1, "bfst", IIAlu, simm5, immSExt5,  CPURegs, 0>;

class veq40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
	F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
	 !strconcat(instr_asm, "\t$ra, $rb, $rc"),
	 [(set RC:$ra, (int_dsp_veq_40 RC:$rb, RC:$rc))], itin> {

	 }

def veq_40 : veq40_fmt<0, 1, 0b00100001, "veq.40", IIAlu, VPR4Out>;

class veq_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_veq_20 RC:$rb, RC:$rc))], itin> {

   }

  def veq_20 : veq_20_fmt<0, 1, 0b00100010, "veq.20", IIAlu, VPR8Out>;

  class veq_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_veq_10 RC:$rb, RC:$rc))], itin> {

   }

  def veq_10 : veq_10_fmt<0, 1, 0b00100011, "veq.10", IIAlu, VPR16Out>;

  class vgt40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vgt_40 RC:$rb, RC:$rc))], itin> {

   }

def vgt_40 : vgt40_fmt<0, 1, 0b00100101, "vgt.40", IIAlu, VPR4Out>;

class vgt_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vgt_20 RC:$rb, RC:$rc))], itin> {

   }

  def vgt_20 : vgt_20_fmt<0, 1, 0b00100110, "vgt.20", IIAlu, VPR8Out>;

  class vgt_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vgt_10 RC:$rb, RC:$rc))], itin> {

   }

  def vgt_10 : vgt_10_fmt<0, 1, 0b00100111, "vgt.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
  class vlt40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vlt_40 RC:$rb, RC:$rc))], itin> {

   }

def vlt_40 : vlt40_fmt<0, 1, 0b00100001, "vlt.40", IIAlu, VPR4Out>;

class vlt_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vlt_20 RC:$rb, RC:$rc))], itin> {

   }

  def vlt_20 : vlt_20_fmt<0, 1, 0b00100010, "vlt.20", IIAlu, VPR8Out>;

  class vlt_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vlt_10 RC:$rb, RC:$rc))], itin> {

   }

  def vlt_10 : vlt_10_fmt<0, 1, 0b00100011, "vlt.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
  class vge40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vge_40 RC:$rb, RC:$rc))], itin> {

   }

def vge_40 : vge40_fmt<0, 1, 0b00100001, "vge.40", IIAlu, VPR4Out>;

class vge_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vge_20 RC:$rb, RC:$rc))], itin> {

   }

  def vge_20 : vge_20_fmt<0, 1, 0b00100010, "vge.20", IIAlu, VPR8Out>;

  class vge_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vge_10 RC:$rb, RC:$rc))], itin> {

   }

  def vge_10 : vge_10_fmt<0, 1, 0b00100011, "vge.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
  class vle40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vle_40 RC:$rb, RC:$rc))], itin> {

   }

def vle_40 : vle40_fmt<0, 1, 0b00100001, "vle.40", IIAlu, VPR4Out>;

class vle_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vle_20 RC:$rb, RC:$rc))], itin> {

   }

  def vle_20 : vle_20_fmt<0, 1, 0b00100010, "vle.20", IIAlu, VPR8Out>;

  class vle_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vle_10 RC:$rb, RC:$rc))], itin> {

   }

  def vle_10 : vle_10_fmt<0, 1, 0b00100011, "vle.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
  class vsl40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsl_40 RC:$rb, RC:$rc))], itin> {

   }

def vsl_40 : vsl40_fmt<0, 1, 0b00100001, "vsl.40", IIAlu, VPR4Out>;

class vsl_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsl_20 RC:$rb, RC:$rc))], itin> {

   }

  def vsl_20 : vsl_20_fmt<0, 1, 0b00100010, "vsl.20", IIAlu, VPR8Out>;

  class vsl_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsl_10 RC:$rb, RC:$rc))], itin> {

   }

  def vsl_10 : vsl_10_fmt<0, 1, 0b00100011, "vsl.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
  class vsls40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsls_40 RC:$rb, RC:$rc))], itin> {

   }

def vsls_40 : vsls40_fmt<0, 1, 0b00100001, "vsls.40", IIAlu, VPR4Out>;

class vsls_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsls_20 RC:$rb, RC:$rc))], itin> {

   }

  def vsls_20 : vsls_20_fmt<0, 1, 0b00100010, "vsls.20", IIAlu, VPR8Out>;

  class vsls_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsls_10 RC:$rb, RC:$rc))], itin> {

   }

  def vsls_10 : vsls_10_fmt<0, 1, 0b00100011, "vsls.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
  class vsra40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsra_40 RC:$rb, RC:$rc))], itin> {

   }

def vsra_40 : vsra40_fmt<0, 1, 0b00100001, "vsra.40", IIAlu, VPR4Out>;

class vsra_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsra_20 RC:$rb, RC:$rc))], itin> {

   }

  def vsra_20 : vsra_20_fmt<0, 1, 0b00100010, "vsra.20", IIAlu, VPR8Out>;

  class vsra_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsra_10 RC:$rb, RC:$rc))], itin> {

   }

  def vsra_10 : vsra_10_fmt<0, 1, 0b00100011, "vsra.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
  class vsrl40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsrl_40 RC:$rb, RC:$rc))], itin> {

   }

def vsrl_40 : vsrl40_fmt<0, 1, 0b00100001, "vsrl.40", IIAlu, VPR4Out>;

class vsrl_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsrl_20 RC:$rb, RC:$rc))], itin> {

   }

  def vsrl_20 : vsrl_20_fmt<0, 1, 0b00100010, "vsrl.20", IIAlu, VPR8Out>;

  class vsrl_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vsrl_10 RC:$rb, RC:$rc))], itin> {

   }

  def vsrl_10 : vsrl_10_fmt<0, 1, 0b00100011, "vsrl.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
  class vabs40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vabs_40 RC:$rb, RC:$rc))], itin> {

   }

def vabs_40 : vabs40_fmt<0, 1, 0b00100001, "vabs.40", IIAlu, VPR4Out>;

class vabs_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vabs_20 RC:$rb, RC:$rc))], itin> {

   }

  def vabs_20 : vabs_20_fmt<0, 1, 0b00100010, "vabs.20", IIAlu, VPR8Out>;

  class vabs_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vabs_10 RC:$rb, RC:$rc))], itin> {

   }

  def vabs_10 : vabs_10_fmt<0, 1, 0b00100011, "vabs.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
  class vfmul40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vfmul_40 RC:$rb, RC:$rc))], itin> {

   }

def vfmul_40 : vfmul40_fmt<0, 1, 0b00100001, "vfmul.40", IIAlu, VPR4Out>;

class vfmul_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vfmul_20 RC:$rb, RC:$rc))], itin> {

   }

  def vfmul_20 : vfmul_20_fmt<0, 1, 0b00100010, "vfmul.20", IIAlu, VPR8Out>;

  class vfmul_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vfmul_10 RC:$rb, RC:$rc))], itin> {

   }

  def vfmul_10 : vfmul_10_fmt<0, 1, 0b00100011, "vfmul.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
  class vfmac40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vfmac_40 RC:$rb, RC:$rc))], itin> {

   }

def vfmac_40 : vfmac40_fmt<0, 1, 0b00100001, "vfmac.40", IIAlu, VPR4Out>;

class vfmac_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vfmac_20 RC:$rb, RC:$rc))], itin> {

   }

  def vfmac_20 : vfmac_20_fmt<0, 1, 0b00100010, "vfmac.20", IIAlu, VPR8Out>;

  class vfmac_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vfmac_10 RC:$rb, RC:$rc))], itin> {

   }

  def vfmac_10 : vfmac_10_fmt<0, 1, 0b00100011, "vfmac.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//
class vcmac_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vcmac_20 RC:$rb, RC:$rc))], itin> {

   }

  def vcmac_20 : vcmac_20_fmt<0, 1, 0b00100010, "vcmac.20", IIAlu, VPR8Out>;

  class vcmac_10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vcmac_10 RC:$rb, RC:$rc))], itin> {

   }

  def vcmac_10 : vcmac_10_fmt<0, 1, 0b00100011, "vcmac.10", IIAlu, VPR16Out>;
  //-----------------------------------------------------------------------------//

class vcmul_20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vcmul_20 RC:$rb, RC:$rc))], itin> {

   }

  def vcmul_20 : vcmul_20_fmt<0, 1, 0b00100010, "vcmul.20", IIAlu, VPR8Out>;

    class vcmulr40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vcmulr_40 RC:$rb, RC:$rc))], itin> {

   }

def vcmulr_40 : vcmulr40_fmt<0, 1, 0b00100001, "vcmulr.40", IIAlu, VPR4Out>;

    class vcmuli40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RC>:
  F_3Reg_001<type, op, funct, (outs RC:$ra), (ins RC:$rb, RC:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RC:$ra, (int_dsp_vcmuli_40 RC:$rb, RC:$rc))], itin> {

   }

def vcmuli_40 : vcmuli40_fmt<0, 1, 0b00100001, "vcmuli.40", IIAlu, VPR4Out>;

class vloadr8_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vloadr_8 RS:$rb, imm_type:$imm9))], itin> {

   }

def vloadr_8 : vloadr8_fmt<2, 0b010, 0b10111, "vloadr.8", IIAlu, VPR16Out, GPROut, simm9, immSExt9>;

class vloadr16_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vloadr_16 RS:$rb, imm_type:$imm9))], itin> {

   }

def vloadr_16 : vloadr16_fmt<2, 0b010, 0b10110, "vloadr.16", IIAlu, VPR8Out, GPROut, simm9, immSExt9>;

class vloadr32_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vloadr_32 RS:$rb, imm_type:$imm9))], itin> {

   }

def vloadr_32 : vloadr32_fmt<2, 0b010, 0b10101, "vloadr.32", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class loadu8_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_loadu_8 RS:$rb, imm_type:$imm9))], itin> {

   }

def loadu_8 : loadu8_fmt<2, 0b010, 0b01000, "loadu.8", IIAlu, GPROut, GPROut, simm9, immSExt9>;

class loadu16_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_loadu_16 RS:$rb, imm_type:$imm9))], itin> {

   }

def loadu_16 : loadu16_fmt<2, 0b010, 0b01001, "loadu.16", IIAlu, GPROut, GPROut, simm9, immSExt9>;

class loadu32_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_loadu_32 RS:$rb, imm_type:$imm9))], itin> {

   }

def loadu_32 : loadu32_fmt<2, 0b010, 0b01010, "loadu.32", IIAlu, GPROut, GPROut, simm9, immSExt9>;

class vloadu8_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vloadu_8 RS:$rb, imm_type:$imm9))], itin> {

   }

def vloadu_8 : vloadu8_fmt<2, 0b010, 0b11011, "vloadu.8", IIAlu, VPR16Out, GPROut, simm9, immSExt9>;

class vloadu16_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vloadu_16 RS:$rb, imm_type:$imm9))], itin> {

   }

def vloadu_16 : vloadu16_fmt<2, 0b010, 0b11010, "vloadu.16", IIAlu, VPR8Out, GPROut, simm9, immSExt9>;

class vloadu32_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vloadu_32 RS:$rb, imm_type:$imm9))], itin> {

   }

def vloadu_32 : vloadu32_fmt<2, 0b010, 0b11001, "vloadu.32", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class vloadur8_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vloadur_8 RS:$rb, imm_type:$imm9))], itin> {

   }

def vloadur_8 : vloadur8_fmt<2, 0b010, 0b11111, "vloadur.8", IIAlu, VPR16Out, GPROut, simm9, immSExt9>;

class vloadur16_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vloadur_16 RS:$rb, imm_type:$imm9))], itin> {

   }

def vloadur_16 : vloadur16_fmt<2, 0b010, 0b11110, "vloadur.16", IIAlu, VPR8Out, GPROut, simm9, immSExt9>;

class vloadur32_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vloadur_32 RS:$rb, imm_type:$imm9))], itin> {

   }

def vloadur_32 : vloadur32_fmt<2, 0b010, 0b11101, "vloadur.32", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class storeu8_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_storeu_8 RS:$rb, imm_type:$imm9))], itin> {

   }

def storeu_8 : storeu8_fmt<2, 0b011, 0b01000, "storeu.8", IIAlu, GPROut, GPROut, simm9, immSExt9>;

class storeu16_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_storeu_16 RS:$rb, imm_type:$imm9))], itin> {

   }

def storeu_16 : storeu16_fmt<2, 0b011, 0b01001, "storeu.16", IIAlu, GPROut, GPROut, simm9, immSExt9>;

class storeu32_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_storeu_32 RS:$rb, imm_type:$imm9))], itin> {

   }

def storeu_32 : storeu32_fmt<2, 0b011, 0b01010, "storeu.32", IIAlu, GPROut, GPROut, simm9, immSExt9>;

class storeu10_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_storeu_10 RS:$rb, imm_type:$imm9))], itin> {

   }

def storeu_10 : storeu10_fmt<2, 0b011, 0b11011, "storeu.10", IIAlu, VPR16Out, GPROut, simm9, immSExt9>;

class storeu20_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_storeu_20 RS:$rb, imm_type:$imm9))], itin> {

   }

def storeu_20 : storeu20_fmt<2, 0b011, 0b11010, "storeu.20", IIAlu, VPR8Out, GPROut, simm9, immSExt9>;

class storeu40_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_storeu_40 RS:$rb, imm_type:$imm9))], itin> {

   }

def storeu_40 : storeu40_fmt<2, 0b011, 0b11001, "storeu.40", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class vstoreu10_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vstoreu_10 RS:$rb, imm_type:$imm9))], itin> {

   }

def vstoreu_10 : vstoreu10_fmt<2, 0b011, 0b11111, "vstoreu.10", IIAlu, VPR16Out, GPROut, simm9, immSExt9>;

class vstoreu20_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vstoreu_20 RS:$rb, imm_type:$imm9))], itin> {

   }

def vstoreu_20 : vstoreu20_fmt<2, 0b011, 0b11110, "vstoreu.20", IIAlu, VPR8Out, GPROut, simm9, immSExt9>;

class vstoreu40_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_vstoreu_40 RS:$rb, imm_type:$imm9))], itin> {

   }

def vstoreu_40 : vstoreu40_fmt<2, 0b011, 0b11101, "vstoreu.40", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class loadvh_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_loadvh RS:$rb, imm_type:$imm9))], itin> {

   }

def loadvh : loadvh_fmt<2, 0b011, 0b10000, "load.vh", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class loadvl_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_loadvl RS:$rb, imm_type:$imm9))], itin> {

   }

def loadvl : loadvl_fmt<2, 0b011, 0b10100, "load.vl", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class storevh_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_storevh RS:$rb, imm_type:$imm9))], itin> {

   }

def storevh : storevh_fmt<2, 0b011, 0b10000, "store.vh", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class storevl_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_storevl RS:$rb, imm_type:$imm9))], itin> {

   }

def storevl : storevl_fmt<2, 0b011, 0b10100, "store.vl", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class loaduvh_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_loaduvh RS:$rb, imm_type:$imm9))], itin> {

   }

def loaduvh : loaduvh_fmt<2, 0b011, 0b11000, "loadu.vh", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class loaduvl_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_loaduvl RS:$rb, imm_type:$imm9))], itin> {

   }

def loaduvl : loaduvl_fmt<2, 0b011, 0b11100, "loadu.vl", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class storeuvh_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_storeuvh RS:$rb, imm_type:$imm9))], itin> {

   }

def storeuvh : storeuvh_fmt<2, 0b011, 0b11000, "storeu.vh", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class storeuvl_fmt<bits<3> type, bits<3> op, bits<5> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS, Operand Od, PatLeaf imm_type>:
  F_LS_2Reg_imm9<type, op, funct, (outs RD:$ra), (ins RS:$rb, Od:$imm9),
   !strconcat(instr_asm, "\t$ra, $rb, $imm9"),
   [(set RD:$ra, (int_dsp_storeuvl RS:$rb, imm_type:$imm9))], itin> {

   }

def storeuvl : storeuvl_fmt<2, 0b011, 0b11100, "storeu.vl", IIAlu, VPR4Out, GPROut, simm9, immSExt9>;

class loado16_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS>:
  F_3Reg_001<type, op, funct, (outs RD:$ra), (ins RS:$rb, RS:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RD:$ra, (int_dsp_loado_16 RS:$rb, RS:$rc))], itin> {

   }

def loado_16 : loado16_fmt<2, 0b001, 0b11000010, "loado.16", IIAlu, GPROut, GPROut>;

class loado32_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS>:
  F_3Reg_001<type, op, funct, (outs RD:$ra), (ins RS:$rb, RS:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RD:$ra, (int_dsp_loado_32 RS:$rb, RS:$rc))], itin> {

   }

def loado_32 : loado32_fmt<2, 0b001, 0b11000001, "loado.32", IIAlu, GPROut, GPROut>;

class vloado8_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS>:
  F_3Reg_001<type, op, funct, (outs RD:$ra), (ins RS:$rb, RS:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RD:$ra, (int_dsp_vloado_8 RS:$rb, RS:$rc))], itin> {

   }

def vloado_8 : vloado8_fmt<2, 0b001, 0b11100011, "vloado.8", IIAlu, VPR16Out, GPROut>;

class vloado16_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS>:
  F_3Reg_001<type, op, funct, (outs RD:$ra), (ins RS:$rb, RS:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RD:$ra, (int_dsp_vloado_16 RS:$rb, RS:$rc))], itin> {

   }

def vloado_16 : vloado16_fmt<2, 0b001, 0b11100010, "vloado.16", IIAlu, VPR8Out, GPROut>;

class vloado32_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS>:
  F_3Reg_001<type, op, funct, (outs RD:$ra), (ins RS:$rb, RS:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RD:$ra, (int_dsp_vloado_32 RS:$rb, RS:$rc))], itin> {

   }

def vloado_32 : vloado32_fmt<2, 0b001, 0b11100001, "vloado.32", IIAlu, VPR4Out, GPROut>;

class storeo16_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS>:
  F_3Reg_001<type, op, funct, (outs RD:$ra), (ins RS:$rb, RS:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RD:$ra, (int_dsp_storeo_16 RS:$rb, RS:$rc))], itin> {

   }

def storeo_16 : storeo16_fmt<2, 0b001, 0b11010010, "storeo.16", IIAlu, GPROut, GPROut>;

class storeo32_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS>:
  F_3Reg_001<type, op, funct, (outs RD:$ra), (ins RS:$rb, RS:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RD:$ra, (int_dsp_storeo_32 RS:$rb, RS:$rc))], itin> {

   }

def storeo_32 : storeo32_fmt<2, 0b001, 0b11010001, "storeo.32", IIAlu, GPROut, GPROut>;

class vstoreo10_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS>:
  F_3Reg_001<type, op, funct, (outs RD:$ra), (ins RS:$rb, RS:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RD:$ra, (int_dsp_vstoreo_10 RS:$rb, RS:$rc))], itin> {

   }

def vstoreo_10 : vstoreo10_fmt<2, 0b001, 0b11110011, "vstoreo.10", IIAlu, VPR16Out, GPROut>;

class vstoreo20_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS>:
  F_3Reg_001<type, op, funct, (outs RD:$ra), (ins RS:$rb, RS:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RD:$ra, (int_dsp_vstoreo_20 RS:$rb, RS:$rc))], itin> {

   }

def vstoreo_20 : vstoreo20_fmt<2, 0b001, 0b11110010, "vstoreo.20", IIAlu, VPR8Out, GPROut>;

class vstoreo40_fmt<bits<3> type, bits<3> op, bits<8> funct, string instr_asm, InstrItinClass itin, RegisterClass RD, RegisterClass RS>:
  F_3Reg_001<type, op, funct, (outs RD:$ra), (ins RS:$rb, RS:$rc),
   !strconcat(instr_asm, "\t$ra, $rb, $rc"),
   [(set RD:$ra, (int_dsp_vstoreo_40 RS:$rb, RS:$rc))], itin> {

   }

def vstoreo_40 : vstoreo40_fmt<2, 0b001, 0b11110001, "vstoreo.40", IIAlu, VPR4Out, GPROut>;


