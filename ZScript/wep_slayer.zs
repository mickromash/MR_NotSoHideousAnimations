// ------------------------------------------------------------
// Super Shotgun
// ------------------------------------------------------------
class Slayer:HDShotgun replaces HDShotgun{
	bool Checking;
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Slayer"
		//$Sprite "SLAYA0"

		+hdweapon.fitsinbackpack
		weapon.selectionorder 30;
		weapon.slotnumber 3;
		weapon.slotpriority 2;
		inventory.pickupmessage "$PICKUP_SLAYER";
		obituary "$OB_MPSSHOTGUN";
		weapon.bobrangex 0.3;
		weapon.bobrangey 0.86;
		scale 0.6;
		hdweapon.barrelsize 26,1,1;
		tag "$TAG_SLAYER";
		hdweapon.refid HDLD_SLAYER;

		hdweapon.loadoutcodes "
			\culchoke, rchoke - 0-7, 0 skeet, 7 full";
	}
	static void Fire(actor caller,bool right,int choke=7){
		double shotpower=getshotpower();
		double spread=3.;
		double speedfactor=1.2;
		let sss=Slayer(caller.findinventory("Slayer"));
		if(sss){
			choke=sss.weaponstatus[right?SLAYS_CHOKE2:SLAYS_CHOKE1];
			sss.shotpower=shotpower;
		}

		choke=clamp(choke,0,7);
		spread=6.5-0.5*choke;
		speedfactor=1.+0.02857*choke;

		spread*=shotpower;
		speedfactor*=shotpower;
		vector2 barreladjust=(0.8,-0.05);
		if(right)barreladjust=-barreladjust;
		HDBulletActor.FireBullet(caller,"HDB_wad",xyofs:barreladjust.x,aimoffx:barreladjust.y);
		let p=HDBulletActor.FireBullet(caller,"HDB_00",xyofs:barreladjust.x,
			spread:spread,aimoffx:barreladjust.y,speedfactor:speedfactor,amount:10
		);
		distantnoise.make(p,"world/shotgunfar");
	}
	override string,double getpickupsprite(bool usespare){return "SLAY"..getpickupframe(usespare).."0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("SHL1A0",(-47,-10),sb.DI_SCREEN_CENTER_BOTTOM);
			sb.drawnum(hpl.countinv("HDShellAmmo"),-46,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		int loffs=-31;int rofs=-18;
		if(hdw.weaponstatus[0]&SLAYF_DOUBLE){
			loffs=-27;rofs=-23;
			sb.drawimage("STBURAUT",(-23,-17),sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(hdw.weaponstatus[SLAYS_CHAMBER1]>1){
			sb.drawrect(loffs,-15,3,5);
			sb.drawrect(loffs,-9,3,2);
		}else if(hdw.weaponstatus[SLAYS_CHAMBER1]>0){
			sb.drawrect(loffs,-9,3,2);
		}
		if(hdw.weaponstatus[SLAYS_CHAMBER2]>1){
			sb.drawrect(rofs,-15,3,5);
			sb.drawrect(rofs,-9,3,2);
		}else if(hdw.weaponstatus[SLAYS_CHAMBER2]>0){
			sb.drawrect(rofs,-9,3,2);
		}
		for(int i=hdw.weaponstatus[SHOTS_SIDESADDLE];i>0;i--){
			sb.drawrect(-11-i*2,-5,1,3);
		}
		if(hdw.weaponstatus[SLAYF_SAFETY]==1)sb.drawimage("SAFETY",(-23,-13),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1,1));	
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRE..StringTable.Localize("$SLAWH_FIRE")..weaponstatus[SLAYS_CHOKE1]..")\n"
		..LWPHELP_ALTFIRE..StringTable.Localize("$SLAWH_ALTFIRE")..weaponstatus[SLAYS_CHOKE2]..")\n"
		..LWPHELP_RELOAD..StringTable.Localize("$SLAWH_RELOAD")
		..LWPHELP_ALTRELOAD..StringTable.Localize("$SLAWH_ALTRELOAD")
		..LWPHELP_FIREMODE..StringTable.Localize("$SLAWH_FMODE")
		..LWPHELP_FIREMODE.."+"..LWPHELP_RELOAD..StringTable.Localize("$SLAWH_FMODPRELOAD")
		..LWPHELP_USE.."+"..LWPHELP_UNLOAD..StringTable.Localize("$SLAWH_UPUNL")//"  Steal ammo from Hunter\n"
		..LWPHELP_UNLOADUNLOAD
		..LWPHELP_USE.."+"..LWPHELP_FIREMODE..StringTable.Localize("$LWPHELP_SAFETY")
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		sb.SetClipRect(
			-16+bob.x,-32+bob.y,32,38,
			sb.DI_SCREEN_CENTER
		);
		vector2 bobb=bob*1.1;
		int Light = Owner.Cursector.LightLevel * 1.75;
		if(owner.player.fixedlightlevel==1)Light = 255;
		if(bplayingid){sb.drawimage(
			"dbfrntsit",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
		);
		if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
		sb.drawimage(
			"dbblftsit",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
		col:color(255-Light,0,0,0));}
		else{
			if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
			sb.fill(
				color(250,int(Light*0.08),int(Light*0.08),int(Light*0.08)),
				bobb.x-9,bobb.y+2,18,3,
				sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
			);
			else
			sb.fill(
				color(250,26,26,26),
				bobb.x-9,bobb.y+2,18,3,
				sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
			);
			sb.fill(
				color(250,66,66,66),
				bobb.x-2,bobb.y+2,4,1,
				sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
			);
		}
		sb.SetClipRect(cx,cy,cw,ch);

		sb.drawimage(
			"dbbaksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9
		);
		if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
		sb.drawimage(
			"dbbaksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9, col:Color(255-Light,0,0,0)
		);
	}
	override void PostBeginPlay(){
		if(Wads.CheckNumForName("SHT2B0",wads.ns_sprites,-1,false)<0){
			if(owner){
				actor ownor=owner;
				ownor.A_GiveInventory("Hunter");
				if(
					ownor.player
					&&min(level.time,ownor.getage())<10
				){
					HDWeaponSelector sss;
					thinkeriterator ssi=ThinkerIterator.create("HDWeaponSelector");
					while(sss=HDWeaponSelector(ssi.next(true))){
						if(
							sss.other==ownor
							&&sss.weptype=="Slayer"
						){
							sss.weptype="Hunter";
							break;
						}
					}
				}
				ownor.A_Log(StringTable.Localize("$SLAYERUNAVAILABLE"),true);
			}else{
				spawn("Hunter",pos,ALLOW_REPLACE);
			}
			destroy();
			return;
		}
		super.postbeginplay();
	}
	override double gunmass(){
		return 6+weaponstatus[SHOTS_SIDESADDLE]*0.06;
	}
	override double weaponbulk(){
		return 100+weaponstatus[SHOTS_SIDESADDLE]*ENC_SHELLLOADED;
	}
	//so you don't switch to the hunter every IDFA in D1
	override void detachfromowner(){
		if(Wads.CheckNumForName("SHT2B0",wads.ns_sprites,-1,false)<0){
			weapon.detachfromowner();
		}else hdweapon.detachfromowner();
	}
	transient cvar swapbarrels;
	states{
	Non:
		TNT1 A 1;
		Stop;
	select0:
		SH2G A 0{invoker.swapbarrels=cvar.getcvar("hd_swapbarrels",player);invoker.Checking=false;}
		goto select0small;
	deselect0:
		SH2G A 0 {invoker.Checking=false;}
		goto deselect0small;
	Safety:
		---- A 0 {A_StartSound("weapons/fmswitch",CHAN_WEAPON,CHANF_OVERLAP,0.4);
		if(invoker.weaponstatus[SLAYF_SAFETY]==1)invoker.weaponstatus[SLAYF_SAFETY]=0;
		else invoker.weaponstatus[SLAYF_SAFETY]=1;}
		Goto Nope;	
	fire:
	altfire:
		#### A 0 A_ClearRefire();
	ready:
		TNT1 A 0; //let the PostBeginPlay handle the presence of the relevant sprite
		SH2G A 0 A_JumpIf(pressingunload()&&(pressinguse()||pressingzoom()),"cannibalize");
		#### A 0 A_JumpIf(pressinguse()&&pressingFiremode(),"Safety");
		#### A 1{
			if(PressingFireMode()){
				invoker.weaponstatus[0]|=SLAYF_DOUBLE;
				if(pressingreload()&&invoker.weaponstatus[SHOTS_SIDESADDLE]<12){
					invoker.weaponstatus[0]&=~SLAYF_DOUBLE;
					setweaponstate("reloadss");
					return;
				}
			}else invoker.weaponstatus[0]&=~SLAYF_DOUBLE;

			int pff;
			if(invoker.swapbarrels&&invoker.swapbarrels.getbool()){
				pff=PressingAltfire();
				if(PressingFire())pff|=2;
			}else{
				pff=PressingFire();
				if(PressingAltfire())pff|=2;
			}

			bool ch1=invoker.weaponstatus[SLAYS_CHAMBER1]==2;
			bool ch2=invoker.weaponstatus[SLAYS_CHAMBER2]==2;

			bool dbl=invoker.weaponstatus[0]&SLAYF_DOUBLE;
			{
			if(ch1&&ch2){
				if(pff==3){
					A_Overlay(PSP_FLASH,"flashboth");
					return;
				}
				else if(pff&&dbl){
					setweaponstate("double");
					return;
				}
			}else if(pff&&dbl){
				if(ch1)A_Overlay(11,"flashleft");
				if(ch2)A_Overlay(12,"flashright");
			}
			if(ch1&&pff%2)A_Overlay(11,"flashleft");
			else if(ch2&&pff>1)A_Overlay(12,"flashright");
			}
			A_WeaponReady((WRF_ALL|WRF_NOFIRE)&~WRF_ALLOWUSER2);
		}
		#### A 0 A_WeaponReady();
		goto readyend;
	double:
		---- A 0 A_JumpIf(invoker.weaponstatus[SLAYF_SAFETY]==1,"Nope");
		#### A 1 offset(0,34);
		#### A 1 offset(0,33);
		#### A 0 A_Overlay(PSP_FLASH,"flashboth");
		goto readyend;

	flashleft:
		---- A 0 A_JumpIf(invoker.weaponstatus[SLAYF_SAFETY]==1,"Non");
		SH2F A 1 bright{
			A_Light2();
			HDFlashAlpha(64,false,overlayid());
			A_StartSound("weapons/slayersingle",CHAN_WEAPON,CHANF_OVERLAP);
			A_ZoomRecoil(0.9);
			invoker.weaponstatus[SLAYS_CHAMBER1]=1;

			invoker.Fire(self,0);
		}
		TNT1 A 1{
			A_Light0();
			double shotpower=invoker.shotpower;
			A_MuzzleClimb(0.8*shotpower,-1.6*shotpower,0.8*shotpower,-1.6*shotpower);
		}goto flasheither;
	flashright:
		---- A 0 A_JumpIf(invoker.weaponstatus[SLAYF_SAFETY]==1,"Non");
		SH2F B 1 bright{
			A_Light2();
			HDFlashAlpha(64,false,overlayid());
			A_StartSound("weapons/slayersingle",CHAN_WEAPON,CHANF_OVERLAP);
			A_ZoomRecoil(0.9);
			invoker.weaponstatus[SLAYS_CHAMBER2]=1;

			invoker.Fire(self,1);
		}
		TNT1 A 1{
			A_Light0();
			double shotpower=invoker.shotpower;
			A_MuzzleClimb(-0.8*shotpower,-1.6*shotpower,-0.8*shotpower,-1.6*shotpower);
		}goto flasheither;
	flasheither:
		---- A 0 A_JumpIf(invoker.weaponstatus[SLAYF_SAFETY]==1,"Non");
		TNT1 A 0 A_AlertMonsters();
		TNT1 A 0 setweaponstate("recoil");
		stop;
	flashboth:
		---- A 0 A_JumpIf(invoker.weaponstatus[SLAYF_SAFETY]==1,"Non");
		SH2F C 1 bright{
			A_Light2();
			HDFlashAlpha(128);
			A_StartSound("weapons/slayersingle",CHAN_WEAPON,CHANF_OVERLAP);
			A_StartSound("weapons/slayersingle",CHAN_WEAPON,CHANF_OVERLAP);
			A_ZoomRecoil(0.7);
			invoker.weaponstatus[SLAYS_CHAMBER1]=1;
			invoker.weaponstatus[SLAYS_CHAMBER2]=1;

			invoker.Fire(self,0);
			invoker.Fire(self,1);
		}
		TNT1 A 1{
			A_Light0();
			double shotpower=invoker.shotpower;
			double mlt=(invoker.bplayingid?0.6:-0.6)*shotpower;
			double mlt2=-3.*shotpower;
			A_MuzzleClimb(mlt,mlt2,mlt,mlt2);
		}goto flasheither;
	recoil:
		#### K 1;
		goto ready;
	CheckSide:
		TNT1 A 0 A_OverLay(102, "SideCheck");
		TNT1 A 13;
		STKG J 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>1,1);
		Goto CheckingSide;
		STKG K 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>3,1);
		Goto CheckingSide;
		SHTG L 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>5,1);
		Goto CheckingSide;
		SHTG M 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>7,1);
		Goto CheckingSide;
		SHTG N 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>9,1);
		Goto CheckingSide;
		SHTG O 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>11,1);
		Goto CheckingSide;
		SHTG P 0;
	CheckingSide:
		#### # 5 A_JumpIf(!pressingaltreload(),"CheckSideEnd");
		Loop;
	CheckSideEnd:
		TNT1 A 0 A_OverLay(102, "SideCheckEnd");
		TNT1 # 12;
		Goto Ready;
	SideCheck:
		SH2G A 1 A_OverLayOffset(102, -10, 30);
		SH2G A 1 A_OverLayOffset(102, -20, 60);
		SH2G A 1 A_OverLayOffset(102, -30, 90);
		SH2G A 1 A_OverLayOffset(102, -40, 120);
		SH2G A 1 A_OverLayOffset(102, -50, 150);
		TNT1 A 2;
		STKG J 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>1,1);
		Goto RaiseSide;
		STKG K 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>3,1);
		Goto RaiseSide;
		SHTG L 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>5,1);
		Goto RaiseSide;
		SHTG M 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>7,1);
		Goto RaiseSide;
		SHTG N 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>9,1);
		Goto RaiseSide;
		SHTG O 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>11,1);
		Goto RaiseSide;
		SHTG P 0;
	RaiseSide:	
		#### # 1 A_OverLayOffset(102, 50, 40);
		#### # 1 A_OverLayOffset(102, 45, 35);
		#### # 1 A_OverLayOffset(102, 35, 25);
		#### # 1 A_OverLayOffset(102, 30, 20);
		#### # 1 A_OverLayOffset(102, 20, 10);
		#### # 1 {A_OverLayOffset(102, 11, 0)invoker.Checking=true;}
		Stop;
	SideCheckEnd:
		STKG J 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>1,1);
		Goto LowSide;
		STKG K 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>3,1);
		Goto LowSide;
		SHTG L 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>5,1);
		Goto LowSide;
		SHTG M 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>7,1);
		Goto LowSide;
		SHTG N 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>9,1);
		Goto LowSide;
		SHTG O 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>11,1);
		Goto LowSide;
		SHTG P 0;
	LowSide:	
		#### # 1 A_OverLayOffset(102, 6, 0);
		#### # 1 A_OverLayOffset(102, 16, 10);
		#### # 1 A_OverLayOffset(102, 38, 35);
		#### # 1 A_OverLayOffset(102, 50, 40);
		TNT1 A 2 {invoker.Checking=false;}
		SH2G A 1 A_OverLayOffset(102, -50, 150);
		SH2G A 1 A_OverLayOffset(102, -40, 120);
		SH2G A 1 A_OverLayOffset(102, -30, 90);
		SH2G A 1 A_OverLayOffset(102, -20, 60);
		SH2G A 1 A_OverLayOffset(102, -10, 30);
		Stop;
	altreload:
		---- A 0 A_JumpIf(pressingzoom(),"CheckSide");
		#### A 0{
			if(
				countinv("HDShellAmmo")
				&&(
					invoker.weaponstatus[SLAYS_CHAMBER1]<2
					||invoker.weaponstatus[SLAYS_CHAMBER2]<2
				)
			){
				invoker.weaponstatus[0]|=SLAYF_FROMPOCKETS;
				invoker.weaponstatus[0]&=~SLAYF_UNLOADONLY;
			}
			else setweaponstate("nope");
		}goto reloadstart;
	reload:
		#### A 0{
			if(
				invoker.weaponstatus[SLAYS_CHAMBER1]>1&&
				invoker.weaponstatus[SLAYS_CHAMBER2]>1
			)setweaponstate("reloadss");

			invoker.weaponstatus[0]&=~SLAYF_UNLOADONLY;
			if(invoker.weaponstatus[SHOTS_SIDESADDLE]>0)
				invoker.weaponstatus[0]&=~SLAYF_FROMPOCKETS;
			else if(countinv("HDShellAmmo"))
				invoker.weaponstatus[0]|=SLAYF_FROMPOCKETS;
			else setweaponstate("nope");
		}goto reloadstart;
	reloadstart:
	unloadstart:
		SLYR A 2 offset(-5,-10)EmptyHand();
		SLYR A 2 offset(-2,-5);
		SLYR A 3 offset(0,0);
		#### B 5 A_StartSound("weapons/sshoto",8);
		#### C 4 A_MuzzleClimb(
			frandom(0.6,1.2),frandom(0.6,1.2),
			frandom(0.6,1.2),frandom(0.6,1.2),
			frandom(1.2,2.4),frandom(1.2,2.4)
		);
		TNT1 A 3{
			//eject whatever is already loaded
			for(int i=0;i<2;i++){
				int chm=invoker.weaponstatus[SLAYS_CHAMBER1+i];
				invoker.weaponstatus[SLAYS_CHAMBER1+i]=0;
				actor sss=null;
				if(chm>1)sss=spawn("HDUnspentShell",pos+HDMath.GetGunPos(self),ALLOW_REPLACE);
				else if(chm==1)sss=spawn("HDSpentShell",pos+HDMath.GetGunPos(self),ALLOW_REPLACE);
				if(!!sss){
					double aaa=angle+frandom(-20,20);
					sss.pitch=pitch;sss.angle=angle;
					sss.vel=(cos(aaa),sin(aaa),2);
					if(chm>1)sss.vel*=frandom(0.5,2);
					sss.vel+=vel;
					sss.target=self;
				}
			}
		}
		TNT1 A 2 offset(0,0);
		TNT1 A 2;
		TNT1 A 2;
		TNT1 A 8 offset(-8,0){
			if(invoker.weaponstatus[0]&SLAYF_UNLOADONLY){
				setweaponstate("unloadend");
				return;
			}

			//play animation to search pockets as appropriate
			if(invoker.weaponstatus[0]&SLAYF_FROMPOCKETS)
				A_StartSound("weapons/pocket",9);
				else setweaponstate("reloadnopocket");
		}
		SLYR D 2 offset(-10,44);
		SLYR D 2 offset(-5,37);
		#### D 4 offset(1,-1);
		#### D 4 offset(3,31);
	reloadnopocket:
		SLYR E 5 offset(1,35);
		#### E 2 offset(0,36);
		#### F 2 offset(0,40);
		#### G 1 offset(0,46);
		#### H 2 offset(0,54);

		#### I 2{
			//take up to 2 shells in hand
			int ssh=0;
			if(invoker.weaponstatus[0]&SLAYF_FROMPOCKETS){
				ssh=min(2,countinv("HDShellAmmo"));
				if(ssh>0)A_TakeInventory("HDShellAmmo",ssh);
			}else{
				ssh=min(2,invoker.weaponstatus[SHOTS_SIDESADDLE]);
				invoker.weaponstatus[SHOTS_SIDESADDLE]-=ssh;
			}

			//if the above leaves you with nothing, abort
			if(ssh<1){
				A_SetTics(0);
				return;
			}

			//transfer from hand to chambers
			ssh--;
			while(ssh>=0){
				invoker.weaponstatus[SLAYS_CHAMBER2-ssh]=2;
				ssh--;
			}
		}
		#### J 2 A_StartSound("weapons/sshotl",8);
		#### K 2;
		#### L 1;
		#### M 2 A_StartSound("weapons/sshotc",8);
		#### NOP 2;
		goto ready;
	unloadend:
		SLYR A 0 A_StartSound("weapons/sshotc",8);
		#### NOP 2;
		goto nope;

	reloadss:
		#### A 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>=12,"nope");
		#### A 1 offset(1,34);
		#### A 2 offset(2,34);
		#### A 3 offset(3,36);
	reloadssrestart:
		#### A 6 offset(3,35);
		#### A 9 offset(4,34) A_StartSound("weapons/pocket",9);
	reloadssloop1:
		#### A 0{
			if(invoker.weaponstatus[SHOTS_SIDESADDLE]>=12)setweaponstate("reloadssend");

			//load shells into hand
			int ssh=min(
				3,
				12-invoker.weaponstatus[SHOTS_SIDESADDLE],
				countinv("HDShellAmmo")
			);
			if(ssh<1){
				setweaponstate("reloadssend");
				return;
			}
			invoker.weaponstatus[SHOTS_SIDESADDLE]+=ssh;
			A_TakeInventory("HDShellAmmo",ssh,TIF_NOTAKEINFINITE);
		}
	reloadssend:
		#### A 4 offset(3,34);
		#### A 0{
			if(
				invoker.weaponstatus[SHOTS_SIDESADDLE]<12
				&&(pressingreload()||pressingaltreload())
				&&countinv("HDShellAmmo")
			)setweaponstate("reloadssrestart");
		}
		#### A 3 offset(2,34);
		#### A 1 offset(1,34) emptyhand(careful:true);
		goto nope;
	unloadss:
		#### A 0 EmptyHand();
		#### A 2 offset(2,34) A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]<1,"nope");
		#### A 1 offset(3,36);
	unloadssloop1:
		#### A 4 offset(4,36);
		#### A 2 offset(5,37) A_UnloadSideSaddle();
		#### A 3 offset(4,36){	//decide whether to loop
			if(
				invoker.weaponstatus[SHOTS_SIDESADDLE]>0
				&&!pressingfire()
				&&!pressingaltfire()
				&&!pressingreload()
			)setweaponstate("unloadssloop1");
		}
		#### A 3 offset(4,35);
		#### A 2 offset(3,35);
		#### A 1 offset(2,34);
		goto nope;
	unload:
		#### K 2 offset(0,34){
			if(invoker.weaponstatus[SHOTS_SIDESADDLE]>0)setweaponstate("unloadss");
			else invoker.weaponstatus[0]|=SLAYF_UNLOADONLY;
		}goto unloadstart;

	cannibalize:
		#### A 0 EmptyHand();
		#### A 2 offset(0,36) A_JumpIf(!countinv("Hunter"),"nope");
		#### A 2 offset(0,40) A_StartSound("weapons/pocket",9);
		#### A 8 offset(0,42);
		#### A 8 offset(0,44);
		#### A 8 offset(0,42);
		#### A 2 offset(0,36) A_CannibalizeOtherShotgun();
		goto ready;

	spawn:
		SLAY ABCDEFG -1 nodelay{
			int ssh=invoker.weaponstatus[SHOTS_SIDESADDLE];
			if(ssh>=11)frame=0;
			else if(ssh>=9)frame=1;
			else if(ssh>=7)frame=2;
			else if(ssh>=5)frame=3;
			else if(ssh>=3)frame=4;
			else if(ssh>=1)frame=5;
			else frame=6;
		}
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[SLAYS_CHAMBER1]=2;
		weaponstatus[SLAYS_CHAMBER2]=2;
		weaponstatus[SHOTS_SIDESADDLE]=12;
		if(!idfa){
			weaponstatus[SLAYS_CHOKE1]=7;
			weaponstatus[SLAYS_CHOKE2]=7;
		}
		handshells=0;
	}
	override void loadoutconfigure(string input){
		int choke=min(getloadoutvar(input,"lchoke",1),7);
		if(choke>=0)weaponstatus[SLAYS_CHOKE1]=choke;
		choke=min(getloadoutvar(input,"rchoke",1),7);
		if(choke>=0)weaponstatus[SLAYS_CHOKE2]=choke;
	}
}
enum slayerstatus{
	SLAYF_UNLOADONLY=1,
	SLAYF_DOUBLE=2,
	SLAYF_FROMPOCKETS=4,
	SLAYF_SAFETY=6,
	SLAYS_CHAMBER1=1,
	SLAYS_CHAMBER2=2,
	//3 is for side saddles
	SLAYS_HEAT1=4,
	SLAYS_HEAT2=5,
	SLAYS_CHOKE1=6,
	SLAYS_CHOKE2=7
};

class SlayerRandom:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let ggg=Slayer(spawn("Slayer",pos,ALLOW_REPLACE));
			if(!ggg)return;
			ggg.special=special;
			ggg.vel=vel;
			for(int i=0;i<5;i++)ggg.args[i]=args[i];
			if(!random(0,7)){
				ggg.weaponstatus[SLAYS_CHOKE1]=random(random(0,7),7);
				ggg.weaponstatus[SLAYS_CHOKE2]=random(random(0,7),7);
			}
		}stop;
	}
}