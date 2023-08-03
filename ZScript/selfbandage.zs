//-------------------------------------------------
// D.I.Y.
//-------------------------------------------------
class SelfBandage:HDWoundFixer{
	default{
		+hdweapon.dontdisarm
		weapon.selectionorder 1004;
		weapon.slotnumber 9;
		tag "$TAG_BANDAGES";
	}
	void bandagewound(double amt,actor itg){
		if(itg){
			let tgw=targetwound;
			if(
				!tgw
				||tgw.bleeder!=itg
			){
				tgw=hdbleedingwound.findbiggest(itg);
				targetwound=tgw;
			}else if(
				!tgw.depth
			){
				targetwound=null;
				return;
			}
			if(tgw)tgw.patch(amt,false);
			else{
				wepmsg=Stringtable.Localize("$BANDAGES_NOWOUNDS");
				msgtimer=70;
				if(owner.player)owner.player.setpsprite(PSP_WEAPON,findstate("nope"));
			}
		}
	}
	override string,double getpickupsprite(){return "BLUDC0",1.;}
	override string gethelptext(){LocalizeHelp();
		return WEPHELP_INJECTOR
		.."\n"..WEPHELP_ALTRELOAD..StringTable.Localize("$BANDWH_ALTRELOAD")
		..(owner.countinv("BloodBagWorn")?"":StringTable.Localize("$BANDWH_IFANY"));}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		int of=0;

		let bwnd=targetwound;
		if(!bwnd||!bwnd.depth)bwnd=hdbleedingwound.findbiggest(hpl);
		if(
			bwnd
			&&bwnd.depth
		){
			sb.drawimage(
				"BLUDC0",(-19,-8),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT,
				0.1+(bwnd.depth)*0.07,scale:(0.1,0.1)*bwnd.width
			);
			of=clamp(int(bwnd.depth*0.2),1,3);
			if(hpl.flip)of=-of;
		}
		sb.drawrect(-24,-18+of,2,10);
		sb.drawrect(-29,-14+of,12,2);
	}
	override inventory CreateTossable(int amt){
		DropMeds(owner,0);
		return null;
	}
	int targetlock;
	states{
	select:
		TNT1 A 0{
			if(Random(0,2))invoker.weaponstatus[SFBS_WOUND]=1;
			if(!DoHelpText()) return;
			if(!!hdbleedingwound.findbiggest(self,0))A_WeaponMessage(Stringtable.Localize("$BANDAGES_TEXT1"),210);
			else A_WeaponMessage(Stringtable.Localize("$BANDAGES_TEXT2"),210);
		}
		Goto Super::Select;
	abort:
		#### A 1{
			if(DoHelpText())A_WeaponMessage(Stringtable.Localize("$BANDAGES_STAYSTILL"),70);
		}
		TNT1 A 0 A_Refire("Lower");
		goto Ready;
	fire:
		TNT1 A 0{
			invoker.targetwound=null;
			bool nope=false;
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				A_TakeOffFirst(blockinv.gettag());
				nope=true;
			}
			else if(!hdbleedingwound.findbiggest(self,0)){
				if(DoHelpText())A_WeaponMessage(Stringtable.Localize("$BANDAGES_NOTBLEEDING"),70);
				nope=true;
			}
			if(nope)player.setpsprite(PSP_WEAPON,invoker.findstate("nope"));
		}
	hold:
	lower:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[SFBS_WOUND]==1,"Search");
		TNT1 A 0 A_JumpIf(pitch>45,"try");
		TNT1 A 1 A_MuzzleClimb(0,6);
		TNT1 A 0 A_JumpIf(IsMoving.Count(self)>=4,"abort");
		TNT1 A 0 A_Refire("lower");
		goto ready;
	Search:
		RAGF WV 3;
		TNT1 A 0 A_Jump(75, "EjectBullet");
		RAGF BC 4;
		TNT1 A 0 A_Jump(75, "EjectBrass");
		RAGF DXY 3;
		---- A 0 A_Jump(256,"EjectBulletLeft");
		Goto Trying;
	EjectBrass:
		RAGF EFGH 3;
		#### A 0 A_PlaySkinSound(SKINSOUND_MEDS,"*usemeds");
		RAGF HJIJH 2 A_MuzzleClimb(frandom(-1.5,1.8),frandom(-1.4,1.4));
		#### A 0 A_PlaySkinSound(SKINSOUND_MEDS,"*usemeds");
		RAGF IJIHJI 2 A_MuzzleClimb(frandom(-1.5,1.8),frandom(-1.4,1.4));
		#### A 0 A_PlaySkinSound(SKINSOUND_MEDS,"*usemeds");
		RAGF KLMMM 3;
		RAGF NOP 2;
		TNT1 A 0 {invoker.bandagewound(frandom(5,10),self);}
		TNT1 A 0 A_StartSound("weapons/chunksplat",CHAN_BODY);
		RAGF QRSTU 3;
		---- A 0 {invoker.weaponstatus[SFBS_WOUND]=0;}
		Goto Try;
	EjectBulletLeft:
		RRGE AB 2;
		RRGE CDE 2;
		RRGE FG 4;
		---- A 0 A_StartSound("misc/smallslop",CHAN_VOICE);
		RRGE GOGGP 1 A_MuzzleClimb(frandom(-4.4,4.4),frandom(-2.4,2.4));
		---- A 0 A_StartSound("misc/smallslop",CHAN_VOICE);
		RRGE PO 1 A_MuzzleClimb(frandom(-4.4,4.4),frandom(-2.4,2.4));
		---- A 0 A_StartSound("misc/smallslop",CHAN_VOICE);
		RRGE GG 1 A_MuzzleClimb(frandom(-4.4,4.4),frandom(-2.4,2.4));
		---- A 0 A_StartSound("misc/smallslop",CHAN_VOICE);
		RRGE GOOGPGGO 1 A_MuzzleClimb(frandom(-4.4,4.4),frandom(-2.4,2.4));
		---- A 0 A_StartSound("weapons/rockopen",CHAN_VOICE);
		RRGE H 5;
		RRGE I 3;
		---- A 0 A_StartSound("weapons/rocklaunch",Chan_BODY);
		RRGE JK 3;
		---- A 0 A_MuzzleClimb(frandom(-5.4,5.4),frandom(-2.4,2.4));
		---- A 0{actor aaa=spawn(
					"TwistedBulletChunk",
					(pos.xy,pos.z+height-10)
					+(cos(pitch)*cos(angle),cos(pitch)*sin(angle),sin(pitch))*7,
					ALLOW_REPLACE);
				invoker.weaponstatus[SFBS_WOUND]=0;}
	BandageArm2Left:
		TNT1 A 0 {invoker.bandagewound(frandom(5,10),self);}
		RRGE L 4;
		---- A 0 A_StartSound("weapons/pocket",CHAN_BODY,CHANF_OVERLAP);
		RRGE LL 6 A_MuzzleClimb(frandom(-2.4,2.4),frandom(-2.4,2.4));
		---- A 0 A_StartSound("weapons/pocket",CHAN_BODY,CHANF_OVERLAP);
		RRGE LL 6 A_MuzzleClimb(frandom(-2.4,2.4),frandom(-2.4,2.4));
		RRGE MN 3;
		RRGE "[" 3;
		#### A 0 A_StartSound("bandage/rustle",CHAN_BODY,CHANF_OVERLAP);
		RRGE "]" 3;
		RRGE QRSTUVWXYZZ 3;
		RRGE Z 2 offset(10,38);
		RRGF A 2;
		---- A 0 offset(0,0);
		goto Heal;
	try:
		TNT1 A random(15,25);
		TNT1 A 0{
			A_MuzzleClimb(frandom(-1.5,1.8),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A 0 A_Jump(32,2);
		TNT1 A random(5,15) damagemobj(self,self,1,"bleedout");
		TNT1 A 0 A_JumpIf(IsMoving.Count(self)>=4,"abort");
	try2:
		//TNT1 A 0 A_JumpIf(targetwound<7,"Try5");
		---- A 0{let itg=invoker.target;
			if(itg){
				let tgw=invoker.targetwound;
				if(tgw.bleeder!=itg)A_Jump(256,1);}}
		Goto Try5;	
		TNT1 A 0{
			A_MuzzleClimb(frandom(-1.5,1.8),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		RAGE AB 2;
	EjectBullet:	
		RAGE CDE 2;
		RAGE FG 4;
		---- A 0 A_StartSound("misc/smallslop",CHAN_VOICE);
		RAGE GOGGP 1 A_MuzzleClimb(frandom(-4.4,4.4),frandom(-2.4,2.4));
		---- A 0 A_StartSound("misc/smallslop",CHAN_VOICE);
		RAGE PO 1 A_MuzzleClimb(frandom(-4.4,4.4),frandom(-2.4,2.4));
		---- A 0 A_StartSound("misc/smallslop",CHAN_VOICE);
		RAGE GG 1 A_MuzzleClimb(frandom(-4.4,4.4),frandom(-2.4,2.4));
		---- A 0 A_StartSound("misc/smallslop",CHAN_VOICE);
		RAGE GOOGPGGO 1 A_MuzzleClimb(frandom(-4.4,4.4),frandom(-2.4,2.4));
		---- A 0 A_StartSound("weapons/rockopen",CHAN_VOICE);
		RAGE H 5;
		RAGE I 3;
		---- A 0 A_StartSound("weapons/rocklaunch",Chan_BODY);
		RAGE JK 3;
		---- A 0 A_MuzzleClimb(frandom(-5.4,5.4),frandom(-2.4,2.4));
		---- A 0{actor aaa=spawn(
					"TwistedBulletChunk",
					(pos.xy,pos.z+height-10)
					+(cos(pitch)*cos(angle),cos(pitch)*sin(angle),sin(pitch))*7,
					ALLOW_REPLACE);
				invoker.weaponstatus[SFBS_WOUND]=0;}
	BandageArm2:
		TNT1 A 0 {invoker.bandagewound(frandom(5,10),self);}
		RAGE L 4;
		---- A 0 A_StartSound("weapons/pocket",CHAN_BODY,CHANF_OVERLAP);
		RAGE LL 6 A_MuzzleClimb(frandom(-2.4,2.4),frandom(-2.4,2.4));
		---- A 0 A_StartSound("weapons/pocket",CHAN_BODY,CHANF_OVERLAP);
		RAGE LL 6 A_MuzzleClimb(frandom(-2.4,2.4),frandom(-2.4,2.4));
		RAGE MN 3;
		RAGE "[" 3;
		#### A 0 A_StartSound("bandage/rustle",CHAN_BODY,CHANF_OVERLAP);
		RAGE "]" 3;
		RAGE QRSTUVWXYZZ 3;
		RAGE Z 2 offset(10,38);
		RAGF A 2;
		---- A 0 offset(0,0);
		goto Heal;
	None:
		TNT1 A 0;
		Stop;
	Try41:
		TNT1 A 0 A_CheckFloor(2);
		TNT1 A 0 A_Jump(240,2);
		TNT1 A 0 A_ChangeVelocity(frandom(-0.3,0.3),frandom(-0.3,0.3),frandom(-1,2));
		TNT1 A 0{
			A_MuzzleClimb(frandom(-1.5,1.7),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		//TNT1 A 0 A_Jump(240,2);
		RAGA ABCD 2;
		Stop;
	Try42:
		RRGA ABCD 2;
		Stop;
	Try4:
		TNT1 A 0 A_CheckFloor(2);
		TNT1 A 0 A_Jump(240,2);
		TNT1 A 0 A_ChangeVelocity(frandom(-0.3,0.3),frandom(-0.3,0.3),frandom(-1,2));
		TNT1 A 0{
			A_MuzzleClimb(frandom(-1.5,1.7),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A 0 A_Jump(240,2);
		RAGD E 0;
		TNT1 A 0 A_Jump(140,2);
		TNT1 A 0 A_JumpIf(IsMoving.Count(self)>=4,"abort");
		TNT1 A 0 A_Refire("try5");
		goto ready;	
	try3:
		TNT1 A random(20,40){
			A_MuzzleClimb(frandom(-1.6,1.8),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A random(1,2) A_Jump(32,2,4);
		TNT1 A 0 A_Jump(256,2);
		TNT1 A random(1,2) A_PlaySkinSound(SKINSOUND_GRUNT,"*usefail");
		TNT1 A 0 A_Jump(256,2);
		TNT1 A random(1,2) A_PlaySkinSound(SKINSOUND_GRUNT,"*grunt");
		TNT1 A 0 A_Jump(90,"try4");
		RAGA E 0 A_Jump(60,4);
		RAGB E 0 A_Jump(110,3);
		RAGC E 0 A_Jump(140,2);
		RAGD E 0;
		#### V 1 Offset(0,50);
		#### V 1 Offset(0,30);
		#### V 1 Offset(0,10);
		#### VW 3 Offset(0,0);
		#### A 0 A_StartSound("bandage/rip",CHAN_WEAPON,CHANF_OVERLAP,0.4);
		#### XYZ 2;
		#### A 0 A_Jump(128,"BandageArmRight1");
		#### U 3;
		#### A 0 A_OverLay(26,"Try41");
		#### U 8;
		#### A 0 A_OverLay(26,"None");
		#### A 0 A_Refire("BandageArm");
		goto BandageArm;
	TryingRight:
		RRGA ABCD 2;
		RRGA E 0 A_Jump(60,"BandageArmRight");
		RRGB E 0 A_Jump(110,"BandageArmRight");
		RRGC E 0 A_Jump(140,"BandageArmRight");
		RRGD E 0;
		Goto BandageArmRight;
	BandageArmRight1:
		#### A 0 A_OverLay(26,"Try42");
		#### U 8;
		#### A 0 A_OverLay(26,"None");
		---- A 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("RAGAA0"),4);
		---- A 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("RAGBA0"),4);
		---- A 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("RAGCA0"),4);
		---- A 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("RAGDA0"),4);
		RRGA A 0 A_Jump(256,"BandageArmRight");
		RRGB A 0 A_Jump(256,"BandageArmRight");
		RRGC A 0 A_Jump(256,"BandageArmRight");
		RRGD A 0;
	BandageArmRight:	
		#### A 0 A_Jump(240,2);
		#### A 0 A_PlaySkinSound(SKINSOUND_GRUNT,"*grunt");
		//TNT1 A 0 A_Jump(140,2);
		#### A 0 A_StartSound("bandage/rustle",CHAN_BODY,CHANF_OVERLAP);
		#### EFFGHIJO 2;
		#### A 0 A_StartSound("bandage/rustle",CHAN_BODY,CHANF_OVERLAP);
		#### PFGHIJK 2;
		#### LM 2;
		RRGA N 2;
		Goto Heal;
	try5:
		TNT1 A 0 A_MuzzleClimb(frandom(-1.8,1.8),frandom(-2.4,2.4));
		TNT1 A 0 A_Jump(8,"Try@");
		TNT1 A 0 A_Jump(20,"try3");
		TNT1 A 0 A_Jump(16,"try4");
	Trying:	
		TNT1 A 0 A_Jump(128,"TryingRight");
		RAGA ABCD 2;
		RAGA E 0 A_Jump(60,4);
		RAGB E 0 A_Jump(110,3);
		RAGC E 0 A_Jump(140,2);
		RAGD E 0;
	BandageArm:	
		#### A 0 A_Jump(240,2);
		#### A 0 A_PlaySkinSound(SKINSOUND_GRUNT,"*grunt");
		#### A 0 A_StartSound("bandage/rustle",CHAN_BODY,CHANF_OVERLAP);
		#### EFFGHIJO 2;
		#### A 0 A_StartSound("bandage/rustle",CHAN_BODY,CHANF_OVERLAP);
		#### PFGHIJK 2;
		#### LM 2;
		RAGA N 2;
	Heal:	
		TNT1 A 0 A_JumpIf(!!hdbleedingwound.findbiggest(self,0),2);
		TNT1 A 0 {
			if(DoHelpText())A_WeaponMessage(Stringtable.Localize("$BANDAGES_STABLE"),144);
		}goto nope;
		TNT1 A 0 A_Jump(42,2);
		TNT1 A 0 A_JumpIf(HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKBODY),2);
		TNT1 A 4 A_Jump(100,2,3);
		TNT1 A 0 {invoker.bandagewound(frandom(1,3),self);}
		TNT1 A 0 A_MuzzleClimb(frandom(-2.4,2.4),frandom(-2.4,2.4));
		TNT1 A 0 A_Refire("Try2");
		goto Ready;
	nope:
		#### A 0{invoker.targetlock=0;}
		goto super::nope;
	altfire:
	althold:
		TNT1 A 1;
		TNT1 A 0{
			actor a;int b;
			[a,b]=LineAttack(angle,42,pitch,0,"none",
				"CheckPuff",flags:LAF_NORANDOMPUFFZ|LAF_NOINTERACT
			);
			let c=a.tracer;
			if(!HDBleedingWound.canbleed(c)){
				A_WeaponMessage(Stringtable.Localize("$BANDAGES_NOTHINGDONE"));
				return resolvestate("nope");
			}
			if(IsMoving.Count(c)>4){
				c.A_Print(string.format(Stringtable.Localize("$BANDAGES_SOMEONEBANDAGING"),player.getusername()));
				A_WeaponMessage(Stringtable.Localize("$BANDAGES_STAYSTILLOTHER"));
				return resolvestate("nope");
			}
			if(!hdbleedingwound.findbiggest(c)){
				A_WeaponMessage(Stringtable.Localize("$BANDAGES_OTHERNOTBLEEDING"));
				return resolvestate("nope");
			}
			invoker.target=c;
			invoker.targetlock++;
			if(invoker.targetlock>10){
				A_Refire("injectbandage");
			}else A_Refire();
			return resolvestate(null);
		}goto nope;
	injectbandage:
		TNT1 A random(7,14){
			if(invoker.target){
				A_WeaponMessage(Stringtable.Localize("$BANDAGES_WORKINGON")..HDMath.GetName(invoker.target).."...",20);
				if(random(0,2)){
					if(!random(0,2))invoker.target.A_StartSound("bandage/rustle",CHAN_BODY);
					return;
				}
				invoker.target.A_StartSound("weapons/pocket",CHAN_BODY,CHANF_OVERLAP);
				invoker.bandagewound(frandom(3,5),invoker.target);
			}
		}goto ready;

	altreload:
		TNT1 A 0 A_StartSound("weapons/pocket",9);
		TNT1 A 15 A_JumpIf(!countinv("BloodBagWorn")||HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL),"nope");
		TNT1 A 10{
			A_SetBlend("7a 3a 18",0.1,4);
			A_MuzzleClimb(0,2);
			A_PlaySkinSound(SKINSOUND_MEDS,"*usemeds");
			A_DropInventory("BloodBagWorn");
		}
		goto nope;


	spawn:
		TNT1 A 1;
		stop;
	}
}

enum selfbandagestatus{
	SFBS_WOUND=0,
};

class TwistedBulletChunk:WallChunk{
	default{scale 0.12;translation "1:255=86:99";}
}