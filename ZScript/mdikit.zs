//-------------------------------------------------
// Medikit
//-------------------------------------------------
class PortableMedikit:HDPickup{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Medikit"
		//$Sprite "PMEDA0"

		-hdpickup.droptranslation
		inventory.pickupmessage "Picked up a medikit.";
		inventory.icon "MEDIA0";
		scale 0.4;
		hdpickup.bulk ENC_MEDIKIT;
		tag "medikit";
		hdpickup.refid HDLD_MEDIKIT;
		+inventory.ishealth
	}
	states{
	spawn:
		MEDI A -1;
		stop;
	use:
		TNT1 A 0{
			if(
				!FindInventory("HDMedikitter")
				||player.cmd.buttons&BT_USE
			){
				let mdk=HDMedikitter(spawn("HDMedikitter",pos));
				mdk.actualpickup(self,true);
				if(A_JumpIfInventory("PortableStimpack",0,"null"))A_DropItem("PortableStimpack");
				else A_GiveInventory("PortableStimpack");
				if(A_JumpIfInventory("SecondBlood",0,"null"))A_DropItem("SecondBlood");
				else A_GiveInventory("SecondBlood");
				A_TakeInventory("PortableMedikit",1);
			}else{
				A_Log("You pull out the medikit you've already unwrapped.",true);
			}
			if(!hdplayerpawn(self)||!hdplayerpawn(self).incapacitated)A_SelectWeapon("HDMedikitter");
			A_StartSound("weapons/pocket",9);
		}
		fail;
	}
}

enum MediNums{
	MEDIKIT_FLESHGIVE=5,
	MEDIKIT_MAXFLESH=42,
	MEDIKIT_NOTAPLAYER=MAXPLAYERS+1,
	
	MEDS_SECONDFLESH=1,
	MEDS_USEDON=2,
	MEDS_ACCURACY=3,
	MEDS_BLOOD=4,
	MEDS_WOUND=5,

	CHECKCOV_ONLYFULL=1,
	CHECKCOV_CHECKBODY=2,
	CHECKCOV_CHECKFACE=4,
}
class HDMedikitter:HDWoundFixer{
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	default{
		-weapon.no_auto_switch
		+inventory.invbar
		-nointeraction
		weapon.selectionorder 1001;
		weapon.slotnumber 9;
		scale 0.3;
		tag "Second Flesh applicator";
		hdweapon.refid HDLD_FINJCTR;
	}
	override void initializewepstats(bool idfa){
		weaponstatus[MEDS_SECONDFLESH]=MEDIKIT_MAXFLESH;
		weaponstatus[MEDS_USEDON]=-1;
		patientname="** UNKNOWN **";
	}
	override double weaponbulk(){
		return ENC_MEDIKIT;
	}
	override string,double getpickupsprite(){
		return (weaponstatus[MEDS_USEDON]<0)?"MEDIB0":"MEDIC0",0.6;
	}
	string patientname;
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		let ww=hdmedikitter(hdw);
		int of=0;
		let bwnd=hdbleedingwound.findbiggest(hpl);
		if(
			bwnd
			&&(weaponstatus[MEDS_USEDON]<0||weaponstatus[MEDS_USEDON]==hpl.playernumber())
		){
			of=clamp(int(bwnd.width*0.1),1,3);
			if(hpl.flip)of=-of;
		}
		sb.drawrect(-29,-17+of,2,6);
		sb.drawrect(-31,-15+of,6,2);

		int usedon=weaponstatus[MEDS_USEDON];
		if(usedon>=0){
			int upn=weaponstatus[MEDS_USEDON];
			string pn=
				upn>=0
				&&upn<MAXPLAYERS
				&&playeringame[upn]
				?players[upn].getusername()
				:patientname
			;
			sb.DrawString(sb.psmallfont,pn,(-53,-8),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT|sb.DI_TEXT_ALIGN_RIGHT,
				Font.CR_RED,scale:(0.3,0.5)
			);
			sb.drawimage(
				"BLUDB0",(-7,-12),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_VCENTER|sb.DI_ITEM_RIGHT,
				0.2+min(0.4,0.01*ww.weaponstatus[MEDS_BLOOD]),scale:(1.5,1.5)*(1+0.02*ww.weaponstatus[MEDS_BLOOD])
			);
		}

		int btn=hpl.player.cmd.buttons;
		if(!(btn&BT_FIREMODE)){
			sb.drawwepnum(ww.weaponstatus[MEDS_SECONDFLESH],MEDIKIT_MAXFLESH);

			let targetwound=ww.targetwound;
			if(!!targetwound){
				double tgtwsc=1.4+targetwound.width*0.1;
				double tgtwa=0;
				if(tgtwsc>3.){
					tgtwa=3.-tgtwsc;
					tgtwsc=3.;
				}
				sb.drawimage(
					"BLUDC0",(-15,!!targetwound.width&&hpl.flip?-8:-7),
					sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT,
					0.01+targetwound.depth*0.1+tgtwa,scale:(1,1)*tgtwsc
				);
			}
		}
	}
	override string gethelptext(){
		LocalizeHelp();
		int usedon=weaponstatus[MEDS_USEDON];
		return
		WEPHELP_RELOAD..StringTable.Localize("$SFAWH_RELOAD")
		..WEPHELP_INJECTOR
		..StringTable.Localize("$SFAWH_WPRESS")
		..StringTable.Localize("$SFAWH_NOTHING")..WEPHELP_RGCOL..StringTable.Localize("$SFAWH_FIRE")
		.."  "..WEPHELP_ZOOM..StringTable.Localize("$SFAWH_ZOOM")
		.."  "..WEPHELP_FIREMODE..StringTable.Localize("$SFAWH_FMODE")
		;
	}
	action void A_MedikitReady(){
		A_WeaponReady(WRF_NOFIRE|WRF_ALLOWUSER1|WRF_ALLOWUSER3);
		if(!player)return;
		int bt=player.cmd.buttons;

		if(
			invoker.icon==invoker.default.icon
			&&invoker.weaponstatus[MEDS_USEDON]>=0
		)invoker.icon=texman.checkfortexture("BLUDIKIT",TexMan.Type_MiscPatch);

		//don't do the other stuff if holding reload
		//LET THE RELOAD STATE HANDLE EVERYTHING ELSE
		if(bt&BT_RELOAD){
			setweaponstate("reload");
			return;
		}

		//wait for the player to decide what they're doing
		if(bt&BT_ATTACK&&bt&BT_ALTATTACK)return;

		//just gotta let go
		if(!(bt&(BT_ATTACK|BT_ALTATTACK)))invoker.targetwound=null;

		//use on someone else
		if(bt&BT_ALTATTACK){
			if(
				(bt&BT_FIREMODE)
				&&!(bt&BT_ZOOM)
			)setweaponstate("diagnoseother");
			else if(invoker.weaponstatus[MEDS_SECONDFLESH]<1){
					A_WeaponMessage(Stringtable.Localize("$MEDIKIT_NOSUTURES"));
				setweaponstate("nope");
			}else setweaponstate("fireother");
			return;
		}

		//self
		if(bt&BT_ATTACK){
			invoker.bwimpy_weapon=false;  //uncloak

			//radsuit, etc. blocks everything
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				A_TakeOffFirst(blockinv.gettag());
				setweaponstate("nope");
				return;
			}
			if(pitch<min(player.maxpitch,80)){
				//move downwards
				let hdp=hdplayerpawn(self);
				if(hdp)hdp.gunbraced=false;
				A_MuzzleClimb(0,5,0,5);
			}else{
				bool scanning=bt&BT_FIREMODE;
				//armour blocks everything except scan
				let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKBODY);
				if(
					!scanning
					&&blockinv
				){
					A_TakeOffFirst(blockinv.gettag());
					setweaponstate("nope");
					return;
				}
				//diagnose
				if(scanning){
					setweaponstate("diagnose");
					return;
				}
				//act upon flesh
				if(invoker.weaponstatus[MEDS_SECONDFLESH]<1){
					A_WeaponMessage(Stringtable.Localize("$MEDIKIT_NOSUTURES"));
					setweaponstate("nope");
					return;
				}
				if(bt&BT_ZOOM){
					//treat burns
					let a=HDPlayerPawn(self);
					if(a){
						if(a.burncount<1){
							A_WeaponMessage(Stringtable.Localize("$MEDIKIT_NOBURNS"));
							setweaponstate("nope");
						}else setweaponstate("patchburns");
						return;
					}
				}else{
					//treat wounds
					if(!hdbleedingwound.findbiggest(self,HDBW_FINDPATCHED)){
						A_WeaponMessage(Stringtable.Localize("$MEDIKIT_NOWOUNDS"));
						setweaponstate("nope");
					}else setweaponstate("patchup");
					return;
				}
			}
		}
		invoker.bwimpy_weapon=true;
		int mbl=invoker.weaponstatus[MEDS_BLOOD];
		if(mbl>random(5,64)){
			invoker.weaponstatus[MEDS_BLOOD]--;
			if(mbl>random(0,255))A_SpawnItemEx(bloodtype,
				frandom(0,3),frandom(-0.3,0.3)*radius,
				height*frandom(0.,0.3),
				flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
			);
		}
	}
	states{
	death:
		#### A 0 A_OverLay(26,"None");
		#### # 0 A_OverLay(-10,"None");
		---- A 0 A_GunBounce();
		goto spawn;
	deselect:
		1HLS C 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELS C 0;
		#### A 0 A_OverLay(26,"None");
		#### # 0 A_OverLay(-10,"None");
		#### # 0 A_StartDeselect();
	deselect0:
		#### # 0 A_Lower();
		wait;
	select:
		TNT1 A 10{
			if(!DoHelpText()) return;
			A_WeaponMessage(Stringtable.Localize("$MEDIKIT_FIRETOHEAL"),175);
		}
		goto super::select;
	ready:
		1HLS C 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELS C 0;
		#### A 0 A_OverLay(26,"None");
		#### # 0 A_OverLay(-10,"None");
		#### A 1 A_MedikitReady();
		goto readyend;
	flashstaple:
		TNT1 A 1{
			A_StartSound("medikit/staple",CHAN_WEAPON);
			A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			invoker.weaponstatus[MEDS_BLOOD]+=random(0,2);
			if(hdplayerpawn(self)){
				HDF.Give(self,"SecondFlesh",1);
			}else givebody(3);
		}goto flashend;
	flashnail:
		TNT1 A 1{
			A_StartSound("medikit/stopper",CHAN_WEAPON,CHANF_OVERLAP);
			A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			invoker.weaponstatus[MEDS_BLOOD]+=random(1,2);
		}goto flashend;
	flashend:
		TNT1 A 1{
			givebody(1);
			damagemobj(invoker,self,1,"staples");
			A_ZoomRecoil(0.9);
			A_ChangeVelocity(frandom(-0.2,0.03),frandom(-0.2,0.2),0.4,CVF_RELATIVE);
		}
		stop;
	altfire:
	althold:
	fireother:
		TNT1 A 0 A_JumpIf(pressingfiremode()&&!pressingzoom(),"diagnoseother");
		1HLF C 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELF C 0;
		#### B 2;
		#### K 2{
			flinetracedata mediline;
			linetrace(
				angle,radius*4,pitch,
				offsetz:height*0.8,
				data:mediline
			);
			let patient=HDPlayerPawn(mediline.hitactor);
			if(!patient){
				//resolve where the target is not an HD player
				if(
					mediline.hitactor
					&&mediline.hitactor.bsolid
					&&!mediline.hitactor.bnoblood
					&&!mediline.hitactor.bspecialfiredamage  //must see wounds to staple them
					&&(
						mediline.hitactor.bloodtype=="HDMasterBlood"
						||mediline.hitactor.bloodtype=="Blood"
					)
					&&(
						mediline.hitactor is "HDHumanoid"
					)
				){
					let mb=hdmobbase(mediline.hitactor);
					if(
						mediline.hitactor.health<mediline.hitactor.spawnhealth()
						||(
							mb
							&&mb.bodydamage>0
						)
					){
						if(invoker.weaponstatus[MEDS_SECONDFLESH]<1){
							A_WeaponMessage(Stringtable.Localize("$MEDIKIT_NOSUTURES"));
							return resolvestate("nope");
						}
						invoker.target=mediline.hitactor;
						return resolvestate("patchupother");
					}else{
						A_WeaponMessage(Stringtable.Localize("$MEDIKIT_OTHERWOUNDS"));
						return resolvestate("nope");
					}
				}else{
					if(DoHelpText())A_WeaponMessage(Stringtable.Localize("$MEDIKIT_NOTHINGTOBEDONE"),150);
					return resolvestate("nope");
				}
			}
			if(
				patient.player
				&&invoker.weaponstatus[MEDS_USEDON]>=0
				&&invoker.weaponstatus[MEDS_USEDON]!=patient.playernumber()
			){
				if(DoHelpText(patient))HDWeapon.ForceWeaponMessage(patient,string.format(Stringtable.Localize("$MEDIKIT_USEDSYRINGE"),player.getusername()));
				if(DoHelpText())A_WeaponMessage(Stringtable.Localize("$MEDIKIT_ATTACKUSED"));
			}else if(IsMoving.Count(patient)>4){
				if(DoHelpText(patient))HDWeapon.ForceWeaponMessage(patient,string.format(Stringtable.Localize("$MEDIKIT_OTHERUSEONYOU"),player.getusername()));
				if(DoHelpText())A_WeaponMessage(Stringtable.Localize("$MEDIKIT_STAYSTILL"));
				return resolvestate("nope");
			}
			let blockinv=HDWoundFixer.CheckCovered(patient,CHECKCOV_CHECKBODY);
			if(
				!patient.player.bot
				&&blockinv
			){
				if(DoHelpText())A_WeaponMessage(Stringtable.Localize("$MEDIKIT_TAKEOFF1")..blockinv.gettag()..Stringtable.Localize("$MEDIKIT_TAKEOFF2"),100);
				return resolvestate("nope");
			}
			if(
				!(getplayerinput(MODINPUT_BUTTONS)&BT_ZOOM)
				&&!hdbleedingwound.findbiggest(patient,HDBW_FINDPATCHED)
			){
				A_WeaponMessage(Stringtable.Localize("$MEDIKIT_OTHERNOWOUNDS"));
				return resolvestate("nope");
			}
			if(
				getplayerinput(MODINPUT_BUTTONS)&BT_ZOOM
				&&patient.burncount<1
			){
				A_WeaponMessage(Stringtable.Localize("$MEDIKIT_OTHERNOBURNS"));
				return resolvestate("nope");
			}
			if(invoker.weaponstatus[MEDS_SECONDFLESH]<1){
				A_WeaponMessage(Stringtable.Localize("$MEDIKIT_NOSUTURES"));
				return resolvestate("nope");
			}
			invoker.target=patient;
			return resolvestate("patchupother");
		}
		#### B 3;
		goto nope;
	patchupother:
		HELF K 0{
			if(
				invoker.target
				&&invoker.target.player
			)invoker.weaponstatus[MEDS_USEDON]=invoker.target.playernumber();
			else invoker.weaponstatus[MEDS_USEDON]=MEDIKIT_NOTAPLAYER;
			invoker.patientname=invoker.target.gettag();
		}
		HELF K 0 A_JumpIf(pressingzoom(),"patchburnsother");
		HELF K 4{
			invoker.weaponstatus[MEDS_SECONDFLESH]--;
			if(invoker.target){
				invoker.target.A_StartSound("medikit/stopper",CHAN_WEAPON,CHANF_OVERLAP);
				invoker.target.A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			}
		}
		1HLF LMNMN 2{
			let itg=invoker.target;
			
			if(
				!itg
				||absangle(angle,angleto(itg))>60
				||distance3dsquared(itg)>(radius*radius*16)
			){
				invoker.target=null;
				A_WeaponMessage(Stringtable.Localize("$MEDIKIT_TARGETNOPED"),15);
				setweaponstate("PatchOtherEnd");
				return;
			}
			A_StartSound("medikit/staple",CHAN_WEAPON);
			invoker.weaponstatus[MEDS_BLOOD]+=random(0,1);

			itg.A_StartSound("misc/smallslop",CHAN_BODY,CHANF_OVERLAP);
			if(!random(0,3))invoker.setstatelabel("patchupend");
			itg.givebody(1);
			itg.damagemobj(invoker,null,1,"staples",DMG_FORCED);

			if(hdplayerpawn(itg)){
				HDF.Give(itg,"SecondFlesh",1);
			}else{
				if(hdmobbase(itg))hdmobbase(itg).bodydamage-=3;
				itg.givebody(3);
				hdmobbase.forcepain(itg);
			}
		}
		1HLF K 4{
			let itg=invoker.target;
			if(itg){
				let tgw=invoker.targetwound;
				if(
					!tgw
					||tgw.bleeder!=itg
				){
					tgw=hdbleedingwound.findbiggest(itg,HDBW_FINDPATCHED);
					invoker.targetwound=tgw;
				}
				if(
					tgw
					&&!tgw.depth
					&&!tgw.patched
				){
					invoker.targetwound=null;
					A_WeaponMessage(Stringtable.Localize("$MEDIKIT_WOUNDSEALED"),70);
					A_SpawnItemEx(bloodtype,
			frandom(0,3),frandom(-0.3,0.3)*radius,
			height*frandom(0.,0.3),
			flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
		);
					//setweaponstate("patchdone");
					//return;
				}
				if(
					tgw
					&&tgw.patch(frandom(0.8,1.2),true)
				){
					tgw.depth+=tgw.patched;
					tgw.patched=0;
				}
			}
		}
		1HLS B 4;
		TNT1 A 0 A_ClearRefire();
		goto ready;
	PatchUpRHand:
		2HLF A 0 A_JumpIf(Invoker.WeaponStatus[MEDS_WOUND]>0,2);
		2HLF C 0;
		2HLF # 0;
		2HLF # 1 A_OverLayOffset(-10, 30, 40);
		2HLF # 1 A_OverLayOffset(-10, 20, 30);
		2HLF # 1 A_OverLayOffset(-10, 10, 20);
		2HLF # 1 A_OverLayOffset(-10, 0, 0);
		2HLF # 1 A_OverLayOffset(-10, 10, 20);
		2HLF # 1 A_OverLayOffset(-10, 20, 30);
		2HLF # 1 A_OverLayOffset(-10, 30, 40);
		Stop;
	StaplerRHand:
		1HLF C 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELF C 0;
		2HLF # 0;
		#### C 2 A_OverLayOffset(26, 0, 28);
		#### D 2 A_OverLayOffset(26, 0, 51);
		#### D 2 A_OverLayOffset(26, 0, 28);
		Stop;
	StaplerRHand1:
		1HLF EFEFGEGEFDDD 1 A_OverLayOffset(26, 0, 51);
		Loop;
	PatchUpRHand1:
		2HLF A 0 A_JumpIf(Invoker.WeaponStatus[MEDS_WOUND]>0,2);
		2HLF C 0;
		2HLF # 0;
		2HLF # 3 A_OverLayOffset(-10, Random(-1,1), Random(-1,1));
		Loop;
	StaplerRHandEnd:
		1HLF D 2 A_OverLayOffset(26, 0, 38);
		1HLF C 2 A_OverLayOffset(26, 0, 28);
		1HLF B 2 A_OverLayOffset(26, 0, 18);
		Stop;
	PatchUpRHandEnd:
		2HLF B 0 A_JumpIf(Invoker.WeaponStatus[MEDS_WOUND]>0,2);
		2HLF D 0;
		2HLF # 3;
		2HLF # 1 A_OverLayOffset(-10, 10, 20);
		2HLF # 1 A_OverLayOffset(-10, 20, 30);
		2HLF # 1 A_OverLayOffset(-10, 30, 40);
		Stop;
	patchup:
		TNT1 A 0 {Invoker.WeaponStatus[MEDS_WOUND]=frandom(0,4);}
		TNT1 A 0 {A_OverLay(-10,"PatchUpRHand"); A_OverLay(26,"StaplerRHand");}
		TNT1 A 4;
		TNT1 A 0{
			if(invoker.weaponstatus[MEDS_SECONDFLESH]<1){
				A_WeaponMessage(Stringtable.Localize("$MEDIKIT_NOSUTURES"));
				setweaponstate("nope");
				return;
			}
			invoker.weaponstatus[MEDS_USEDON]=playernumber();
			invoker.weaponstatus[MEDS_SECONDFLESH]--;
		}
		TNT1 A 0 {A_OverLay(-10,"PatchUpRHand1"); A_OverLay(26,"StaplerRHand1");}
		TNT1 A 10 A_Overlay(3,"flashnail");
		TNT1 AAAAA random(4,5){
			invoker.target=self;
			A_Overlay(3,"flashstaple");
			if(!random(0,3))invoker.setstatelabel("patchupend");
		}goto patchupend;
	patchupend:
		TNT1 A 0 {A_OverLay(-10,"PatchUpRHandEnd"); A_OverLay(26,"StaplerRHandEnd");}
		TNT1 A 6{
			let itg=invoker.target;
			if(itg){
				let tgw=invoker.targetwound;
				if(
					!tgw
					||tgw.bleeder!=itg
				){
					tgw=hdbleedingwound.findbiggest(itg,HDBW_FINDPATCHED);
					invoker.targetwound=tgw;
				}
				if(
					tgw
					&&!tgw.depth
					&&!tgw.patched
				){
					invoker.targetwound=null;
					A_WeaponMessage(Stringtable.Localize("$MEDIKIT_WOUNDSEALED"),70);
					A_SpawnItemEx(bloodtype,
			frandom(0,3),frandom(-0.3,0.3)*radius,
			height*frandom(0.,0.3),
			flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
		);
					//setweaponstate("patchdone");
					//return;
				}
				if(
					tgw
					&&tgw.patch(frandom(0.8,1.2),true)
				){
					tgw.depth+=tgw.patched;
					tgw.patched=0;
				}
			}
		}
		1HLS C 4;
		TNT1 A 0 A_ClearRefire();
		goto ready;
	patchdone:
		TNT1 A 4;
		TNT1 A 4 A_StartSound("misc/bulletflesh",CHAN_WEAPON,CHANF_OVERLAP);
		TNT1 A 3 A_SpawnItemEx(bloodtype,
			frandom(0,3),frandom(-0.3,0.3)*radius,
			height*frandom(0.,0.3),
			flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
		);
		TNT1 A 2;
		goto nope;
	PatchBrunHand:
		2HLF E 1 A_OverLayOffset(-10, 30, 40);
		2HLF # 1 A_OverLayOffset(-10, 20, 30);
		2HLF # 1 A_OverLayOffset(-10, 10, 20);
		2HLF # 1 A_OverLayOffset(-10, 0, 0);
		2HLF # 1 A_OverLayOffset(-10, 10, 20);
		2HLF # 1 A_OverLayOffset(-10, 20, 30);
		2HLF # 1 A_OverLayOffset(-10, 30, 40);
		Stop;
	PatchBrunStapler:
		1HLF C 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELF C 0;
		#### C 2 A_OverLayOffset(26, 0, 28);
		#### D 2 A_OverLayOffset(26, 0, 51);
		#### C 2 A_OverLayOffset(26, 0, 28);
		Stop;
	PatchBrunStapler1:
		1HLF C 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,"PatchBrunStapler12");
		HELF D 4 A_OverLayOffset(26, 0, 51);
		HELF EFGD 2 A_OverLayOffset(26, Frandom(-3,6), Frandom(45,51));
		Loop;
	PatchBrunStapler12:
		1HLF D 10 A_OverLayOffset(26, 0, 51);
		1HLF HIJDHJIHIJD 2 A_OverLayOffset(26, Frandom(-3,6), Frandom(45,51));
		Loop;
	PatchBrunHand1:
		2HLF E 10 A_OverLayOffset(-10, Random(-1,1), Random(-1,1));
		2HLF EEEEE 2 A_OverLayOffset(-10, Random(-1,1), Random(-1,1));
		2HLF FFFFF 2 A_OverLayOffset(-10, Random(-1,1), Random(-1,1));
		2HLF GGGGG 2 A_OverLayOffset(-10, Random(-1,1), Random(-1,1));
		2HLF H 2 A_OverLayOffset(-10, Random(-1,1), Random(-1,1));
		Loop;
	PatchBrunStaplerEnd:
		1HLF D 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELF D 0;
		#### D 3 A_OverLayOffset(26, 0, 38);
		#### C 3 A_OverLayOffset(26, 0, 28);
		Stop;
	PatchBrunHandEnd:
		2HLF GHH 2 A_OverLayOffset(-10, Random(-1,1), Random(-1,1));
		2HLF I 2 A_OverLayOffset(-10, 10, 20);
		2HLF I 1 A_OverLayOffset(-10, 20, 30);
		2HLF I 1 A_OverLayOffset(-10, 30, 40);
		Stop;	
	patchburns:
		TNT1 A 0 {A_OverLay(-10,"PatchBrunHand");A_OverLay(26,"PatchBrunStapler");}
		TNT1 A 4;
		TNT1 A 0{
			if(!HDPlayerPawn(self))return;
			invoker.weaponstatus[MEDS_BLOOD]+=random(1,2);
			invoker.weaponstatus[MEDS_USEDON]=playernumber();
			int fleshgive=min(MEDIKIT_FLESHGIVE,invoker.weaponstatus[MEDS_SECONDFLESH]);
			invoker.weaponstatus[MEDS_SECONDFLESH]-=fleshgive;
			A_StartSound("medikit/stopper",CHAN_WEAPON);
			A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			A_StartSound("misc/smallslop",CHAN_BODY,CHANF_OVERLAP);
			actor a=spawn("SecondFleshBeast",pos,ALLOW_REPLACE);
			a.target=self;
			a.stamina=fleshgive;
			A_OverLay(-10,"PatchBrunHand1");A_OverLay(26,"PatchBrunStapler1");
		}
		TNT1 A 30;
		TNT1 A 0 {A_OverLay(-10,"PatchBrunHandEnd");A_OverLay(26,"PatchBrunStapler");}
		TNT1 A 6 A_MedikitReady();
		TNT1 A 0 {A_OverLay(26,"None");}
		goto ready;
	None:
		TNT1 A 1;
		Stop;
	patchburnsother:
		1HLF B 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELF B 0;
		HELF K 4{
			if(invoker.target){
				invoker.weaponstatus[MEDS_BLOOD]+=random(1,2);
				int fleshgive=min(MEDIKIT_FLESHGIVE,invoker.weaponstatus[MEDS_SECONDFLESH]);
				invoker.weaponstatus[MEDS_SECONDFLESH]-=fleshgive;
				invoker.target.A_StartSound("medikit/stopper",CHAN_WEAPON);
				invoker.target.A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
				invoker.target.A_StartSound("misc/smallslop",CHAN_BODY,CHANF_OVERLAP);
				actor a=spawn("SecondFleshBeast",invoker.target.pos,ALLOW_REPLACE);
				a.target=invoker.target;
				a.stamina=fleshgive;
			}
		}
		HELF K 10;
		HELF LMNLMNMLNMLN 2{
			let itg=invoker.target;
			
			if(!itg||absangle(angle,angleto(itg))>60||distance3dsquared(itg)>(radius*radius*16)){invoker.target=null;
			  A_WeaponMessage("Target disconnected!",15);
			  setweaponstate("PatchOtherEnd");
			  return;}}
	patchotherend:	
		HELF K 3;
		1HLF B 3;
		goto nope;
	DiagnoseRHand:
		2HLF B 1 A_OverLayOffset(-10,30,40);
		2HLF B 1 A_OverLayOffset(-10,20,30);
		2HLF B 1 A_OverLayOffset(-10,10,20);
		2HLF B 5 A_OverLayOffset(-10,0,0);
		2HLF B 1 A_OverLayOffset(-10,10,20);
		2HLF B 1 A_OverLayOffset(-10,20,30);
		2HLF B 1 A_OverLayOffset(-10,30,40);
		Stop;
	StaplerDiagnose:
		1HLF C 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELF C 0;
		#### C 1 A_OverLayOffset(26, 0, 28);
		#### C 2 A_OverLayOffset(26, 0, 38);
		#### D 3 A_OverLayOffset(26, 0, 51);
		#### C 1 A_OverLayOffset(26, 0, 38);
		#### C 1 A_OverLayOffset(26, 0, 28);
		Stop;
	diagnose:
		TNT1 A 0 {A_OverLay(-10,"DiagnoseRHand"); A_OverLay(26,"StaplerDiagnose");}
		TNT1 A 8;
		1HLS C 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELS C 0;
		#### A 1;
		#### A 0 A_WeaponMessage(Stringtable.Localize("$MEDIKIT_AUTODIAGNOSTIC"));
		#### ABCDCABDC 3{
			A_StartSound("medikit/scan",CHAN_WEAPON,volume:0.5);
			A_SetBlend("aa aa 88",0.04,1);
		}
		#### A 0 A_ScanResults(self,12);
		#### E 10;
		TNT1 A 0 A_Refire("nope");
		goto readyend;
	diagnoseother:
		1HLF B 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELF B 0;
		#### B 3;
		#### K 4;
		#### B 3;
		1HLS A 0 A_Jumpif(invoker.weaponstatus[MEDS_BLOOD]>0,2);
		HELS A 0;
		#### A 0{
			A_WeaponMessage(Stringtable.Localize("$MEDIKIT_AUTODIAGNOSTIC"));
			invoker.target=null;
			invoker.weaponstatus[MEDS_ACCURACY]=0;
		}
		#### ABCDCABDC 3{
			A_StartSound("medikit/scan",CHAN_WEAPON,volume:0.4);
			flinetracedata mediline;
			linetrace(
				angle,42,pitch,
				offsetz:height-12,
				data:mediline
			);
			let mha=mediline.hitactor;
			if(
				!mha
				||(invoker.target&&mha!=invoker.target)
			){
				invoker.target=null;
				invoker.weaponstatus[MEDS_ACCURACY]=0;
				return;
			}
			invoker.target=mha;
			invoker.weaponstatus[MEDS_ACCURACY]++;
		}
		#### A 0 A_ScanResults(invoker.target,invoker.weaponstatus[MEDS_ACCURACY]);
		#### E 14;
		TNT1 A 0 A_Refire("nope");
		goto readyend;

	spawn:
		MEDI B -1 nodelay{
			if(
				invoker.weaponstatus[MEDS_USEDON]>=0
			){
				frame=2;
				if(invoker.weaponstatus[MEDS_BLOOD]>0){
					actor bbb=spawn("BloodSplatSilent",pos,ALLOW_REPLACE);
					if(bbb)bbb.vel=vel;
					tics=random(10,500-invoker.weaponstatus[MEDS_BLOOD]);
					invoker.weaponstatus[MEDS_BLOOD]--;
				}
			}
		}wait;
	}
	action void A_ScanResults(actor scanactor,double scanaccuracy){
		A_StartSound("medikit/done",CHAN_WEAPON);
		double thrownoff=scanaccuracy-12;
		if(!scanactor||abs(thrownoff)>10){
			A_WeaponMessage(Stringtable.Localize("$MEDIKIT_AUTODIAGNOSTICFAIL"));
			invoker.target=null;
			invoker.weaponstatus[MEDS_ACCURACY]=0;
			return;
		}

		if(HDWoundFixer.CheckCovered(scanactor,CHECKCOV_CHECKBODY))thrownoff+=5.;

		string playerspecs="";
		let slf=HDPlayerPawn(scanactor);
		if(slf){
			thrownoff+=frandom(0,slf.aggravateddamage);
			string bloodloss=string.format("%.2f",
				double(slf.bloodloss)/(HDCONST_BLOODBAGAMOUNT<<2)
				+frandom(0,thrownoff*0.2)
			);
			playerspecs=Stringtable.Localize("$MEDIKIT_BURNS")..slf.burncount..Stringtable.Localize("$MEDIKIT_TISSUEDAMAGE")..slf.oldwoundcount..Stringtable.Localize("$MEDIKIT_BLOODLOSS")..bloodloss..Stringtable.Localize("$MEDIKIT_TRANSFUSIONUNITS");
		}

		string openwounds="";
		string bandaged="";
		string treated="";
		hdbleedingwound bldw=null;
		thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
		int rowcount=0;
		while(bldw=HDBleedingWound(bldit.next())){
			if(
				bldw
				&&bldw.bleeder==scanactor
			){
				if(
					!bldw.depth+frandom(-thrownoff,thrownoff)
					&&!bldw.patched
					&&!bldw.sealed
				)continue;

				string ams=
					(rowcount?"  ":"\n")
					.."\cg"..string.format("%.1f",bldw.depth).."\cc/\ck"..
					string.format("%.1f",bldw.patched+frandom(-thrownoff,thrownoff)).."\cc/\cu"..
					string.format("%.1f",bldw.sealed)
				;
				openwounds=openwounds.." "..ams;

				if(rowcount==2)rowcount=0;else rowcount++;
			}
		}
		if(openwounds=="")openwounds=Stringtable.Localize("$MEDIKIT_NONE");


		A_WeaponMessage(Stringtable.Localize("$MEDIKIT_AUTODIAGNOSTICFOR")..scanactor.gettag()..Stringtable.Localize("$MEDIKIT_WOUNDS")..openwounds..""..playerspecs,270);

		A_Log(Stringtable.Localize("$MEDIKIT_AUTODIAGNOSTICFOR")..scanactor.gettag()..Stringtable.Localize("$MEDIKIT_WOUNDS")..openwounds..playerspecs,true);
	}
}
class SecondFleshBeast:IdleDummy{
	states{
	spawn:
		TNT1 A 14;
		TNT1 A 16{target.A_StartSound("medikit/crackle",CHAN_BODY,CHANF_OVERLAP);}
		TNT1 A 0{
			target.A_StartSound("medikit/crackle",CHAN_BODY,CHANF_OVERLAP);
			target.A_Scream();
			let tgt=HDPlayerPawn(target);
			if(tgt)tgt.AddBlackout(128,24,4);
		}
		TNT1 AAA 4{
			let tgt=HDPlayerPawn(target);
			if(tgt){
				tgt.muzzleclimb1+=(frandom(-4,4),frandom(-10,12));
				tgt.muzzleclimb2+=(frandom(-4,4),frandom(-10,12));
				tgt.muzzleclimb3+=(frandom(-4,4),frandom(-10,12));
				tgt.muzzleclimb4+=(frandom(-4,4),frandom(-10,12));
			}
		}
		TNT1 A 4{
			let tgt=HDPlayerPawn(target);
			if(!tgt||tgt.bkilled||stamina<1){destroy();return;}
			if(tgt.health>10)tgt.damagemobj(tgt,tgt,min(tgt.health-10,3),"internal",DMG_NO_ARMOR);
			if(tgt)tgt.AddBlackout(24,8,4);
			tgt.A_StartSound("medikit/crackle",CHAN_BODY,CHANF_OVERLAP);
			tgt.muzzleclimb1+=(frandom(-1,1),frandom(-1,1));
			tgt.muzzleclimb2+=(frandom(-1,1),frandom(-1,1));
			tgt.muzzleclimb3+=(frandom(-1,1),frandom(-1,1));
			tgt.muzzleclimb4+=(frandom(-1,1),frandom(-1,1));
			tics=clamp(200-stamina,4,random(4,40));
			if(tics>15)tgt.A_StartSound(tgt.painsound,CHAN_VOICE);
			tgt.stunned+=10;
			tgt.burncount--;
			if(!random(0,200))tgt.aggravateddamage++;
			stamina--;
			if(hd_debug)A_Log(string.format("aggro %i  old %i  burn %i",tgt.aggravateddamage,tgt.oldwoundcount,tgt.burncount));
		}wait;
	}
}
class SecondFlesh:HDDrug{
	override void PreTravelled(){
		let hdp=hdplayerpawn(owner);
		hdp.burncount=max(0,hdp.burncount-amount);
		destroy();
	}
	override void OnHeartbeat(hdplayerpawn hdp){
		if(amount<1)return;
		int amt=amount;

		if(
			hdp.health>hdp.healthcap-(amt>>2)
		)hdp.damagemobj(self,hdp,1,"maxhpdrain");

		if(hdp.fatigue<random(1,amt))hdp.fatigue++;

		if(hdp.beatcounter%12==0){
			amount--;
			if(
				hdp.oldwoundcount>0
				&&random(0,2)
			)hdp.oldwoundcount--;

			double healamount=frandom(0.1,3.);
			array<hdbleedingwound> wounds;wounds.clear();
			HDBleedingWound bldw=null;
			thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
			while(bldw=HDBleedingWound(bldit.next())){
				if(
					bldw
					&&bldw.bleeder==hdp
					&&bldw.sealed>0
				)wounds.push(bldw);
			}
			if(wounds.size()>0){
				healamount/=wounds.size();
				for(int i=0;i<wounds.size();i++){
					wounds[i].sealed=max(0,wounds[i].sealed-healamount);
				}
			}

			if(!random(0,47))hdp.aggravateddamage++;
			damagemobj(self,hdp,1,"staples");
		}

		if(hd_debug>=4)console.printf("2FLS "..amt.."  = "..hdp.burncount);
	}
}

