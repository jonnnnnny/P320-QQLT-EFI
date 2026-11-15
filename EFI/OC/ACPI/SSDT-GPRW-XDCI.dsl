/*
 * SSDT-GPRW-XDCI - anti instant-wake hotpatch for Lenovo Tiny4 (P320 Tiny / M910q, Q270)
 *
 * Problem : on this platform, devices whose _PRW references GPE 0x6D
 *           (in practice the XHCI "XDCI" USB controller) wake the machine
 *           immediately after entering S3 sleep (community-reported "0D/6D"
 *           wake sources, `pmset -g log` shows XDCI).
 * Fix     : if the original _PRW package's GPE number is 0x0D or 0x6D,
 *           rewrite it to 0x00 so the device can no longer assert a wake.
 *           All other devices keep their original _PRW untouched.
 *
 * REQUIRES a matching ACPI rename patch in config.plist (already present):
 *           Find: 5F505257 ("_PRW")  Replace: 58505257 ("XPRW")
 * VERIFY on the real machine: dump the DSDT (F4 in the OpenCore picker or
 * SSDTTime) and check which device under \_SB.PCI0 actually owns the _PRW
 * returning {0x6D, ...}. If no device matches, this SSDT is a harmless no-op.
 * If sleep is still instant-waking, disable automatic sleep instead
 * (System Settings > Energy Saver) - that is the fallback several M910q
 * builders ended up using.
 */
DefinitionBlock ("", "SSDT", 2, "HACK", "GPRWXDCI", 0x00001000)
{
    External (XPRW, MethodObj)    // 2 Arguments

    Method (_PRW, 2, NotSerialized)  // _PRW: Power Resources for Wake
    {
        If (_OSI ("Darwin"))
        {
            Local0 = XPRW (Arg0, Arg1)
            Local1 = DerefOf (Local0 [One])
            If ((Local1 == 0x0D))
            {
                Local0 [One] = Zero
            }

            If ((Local1 == 0x6D))
            {
                Local0 [One] = Zero
            }

            Return (Local0)
        }
        Else
        {
            Return (XPRW (Arg0, Arg1))
        }
    }
}
