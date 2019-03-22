/* Quartus Prime Version 18.1.0 Build 625 09/12/2018 SJ Standard Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(EP2AGX95EF29) Path("/home/dewei/WorkSpace/BelleII/MyCode/altera/Arria2/test2/MergerV3_2_2540/U1/output_files/") File("stx_4_1ch.sof") MfrSpec(OpMask(1));
	P ActionCode(Cfg)
		Device PartName(EP2AGX95EF29) Path("/home/dewei/WorkSpace/BelleII/MyCode/altera/Arria2/test2/MergerV3_2_2540/U2/output_files/") File("stx_4_1ch.sof") MfrSpec(OpMask(1));
	P ActionCode(Ign)
		Device PartName(EPM1270) MfrSpec(OpMask(0));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
