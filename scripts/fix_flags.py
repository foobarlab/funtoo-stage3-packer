#!/usr/bin/python3

# 2021-06-21
# https://forums.funtoo.org/topic/4962-fixes-for-abi-riscv-lp64d-rebuild-issues/
# This script will remove "abi_riscv_lp64" and "abi_riscv_lp64d" from IUSE and IUSE_EFFECTIVE in /var/db/pkg entries, eliminating the "urge" for Portage to rebuild everything.

import os

bad_flags = {"abi_riscv_lp64", "abi_riscv_lp64d"}
for dp, dn, fn in os.walk("/var/db/pkg"):
    for targ_fn in [ "IUSE", "IUSE_EFFECTIVE" ]:
        if targ_fn not in fn:
            continue
        usep = os.path.join(dp, targ_fn)
        with open(usep, "r") as usef:
            old_dat = usef.read()
            old_flags = set(old_dat.split())
            new_flags = old_flags - bad_flags
        if old_flags == new_flags:
            continue
        with open(usep + ".bak", "w") as usef:
            usef.write(old_dat)
        with open(usep, "w") as usef:
            usef.write(" ".join(sorted(list(new_flags))))
