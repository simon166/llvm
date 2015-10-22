//===-- DSPFixupKinds.h - DSP Specific Fixup Entries ----------*- C++ -*-===//
//
// The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef LLVM_DSP_DSPFIXUPKINDS_H
#define LLVM_DSP_DSPFIXUPKINDS_H

#include "llvm/MC/MCFixup.h"
namespace llvm {
	namespace DSP{
		enum Fixups{
			// Pure upper 32 bit fixup resulting in - R_DSP_32.
			fixup_DSP_32 = FirstTargetFixupKind,
			// Pure upper 16 bit fixup resulting in - R_DSP_HI16.
			fixup_DSP_HI16,
			// Pure lower 16 bit fixup resulting in - R_DSP_LO16.
			fixup_DSP_LO16,
			// Pure lower 16 bit fixup resulting in - R_DSP_GPREL16.
			fixup_DSP_GPREL16,
			// Global symbol fixup resulting in - R_DSP_GOT16.
			fixup_DSP_GOT_Global,
			// Local symbol fixup resulting in - R_DSP_GOT16.
			fixup_DSP_GOT_Local,
			// resulting in - R_DSP_GOT_HI16
			fixup_DSP_GOT_HI16,
			// resulting in - R_DSP_GOT_LO16
			fixup_DSP_GOT_LO16,
			// Marker
			LastTargetFixupKind,
			NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind

		};
	}

}
#endif