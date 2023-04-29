// ------------------------------------------------------------
// A 12-gauge pump for protection
// ------------------------------------------------------------
class Hunter:HDShotgun{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Hunter"
		//$Sprite "HUNTA0"

		weapon.selectionorder 31;
		weapon.slotnumber 3;
		weapon.slotpriority 1;
		weapon.bobrangex 0.21;
		weapon.bobrangey 0.9;
		scale 0.6;
		inventory.pickupmessage "You got the pump-action shotgun!";
		hdweapon.barrelsize 30,0.5,2;
		hdweapon.refid HDLD_HUNTER;
		tag "$TAG_HUNTER";
		obituary "$OB_MPSHOTGUN";

		hdweapon.loadoutcodes "
			\cutype - 0-2, export/regular/hacked
			\cufiremode - 0-2, pump/semi/auto, subject to the above
			\cuchoke - 0-7, 0 skeet, 7 full";
	}
	//returns the power of the load just fired
	static double Fire(actor caller,int choke=1){
		double spread=6.;
		double speedfactor=1.;
		let hhh=Hunter(caller.findinventory("Hunter"));
		if(hhh)choke=hhh.weaponstatus[HUNTS_CHOKE];

		choke=clamp(choke,0,7);
		spread=6.5-0.5*choke;
		speedfactor=1.+0.02857*choke;

		double shotpower=getshotpower();
		spread*=shotpower;
		speedfactor*=shotpower;
		HDBulletActor.FireBullet(caller,"HDB_wad");
		let p=HDBulletActor.FireBullet(caller,"HDB_00",
			spread:spread,speedfactor:speedfactor,amount:10
		);
		distantnoise.make(p,"world/shotgunfar");
		caller.A_StartSound("weapons/hunter",CHAN_WEAPON);
		return shotpower;
	}
	const HUNTER_MINSHOTPOWER=0.901;
	action void A_FireHunter(){
		double shotpower=invoker.Fire(self);
		A_GunFlash();
		vector2 shotrecoil=(randompick(-1,1),-2.6);
		if(invoker.weaponstatus[HUNTS_FIREMODE]>0)shotrecoil=(randompick(-1,1)*1.4,-3.4);
		shotrecoil*=shotpower;
		A_MuzzleClimb(0,0,shotrecoil.x,shotrecoil.y,randompick(-1,1)*shotpower,-0.3*shotpower);
		invoker.weaponstatus[HUNTS_CHAMBER]=1;
		invoker.shotpower=shotpower;
	}
	override string pickupmessage(){
		if(weaponstatus[0]&HUNTF_CANFULLAUTO)return string.format("%s You notice some tool marks near the fire selector...",super.pickupmessage());
		else if(weaponstatus[0]&HUNTF_EXPORT)return string.format("%s Where is the fire selector on this thing!?",super.pickupmessage());
		return super.pickupmessage();
	}
	override string,double getpickupsprite(bool usespare){return "HUNT"..getpickupframe(usespare).."0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("SHL1A0",(-47,-10),basestatusbar.DI_SCREEN_CENTER_BOTTOM);
			sb.drawnum(hpl.countinv("HDShellAmmo"),-46,-8,
				basestatusbar.DI_SCREEN_CENTER_BOTTOM
			);
		}
		if(hdw.weaponstatus[HUNTS_CHAMBER]>1){
			sb.drawrect(-24,-14,5,3);
			sb.drawrect(-18,-14,2,3);
		}
		else if(hdw.weaponstatus[HUNTS_CHAMBER]>0){
			sb.drawrect(-18,-14,2,3);
		}
		if(!(hdw.weaponstatus[0]&HUNTF_EXPORT))sb.drawwepcounter(hdw.weaponstatus[HUNTS_FIREMODE],
			-26,-12,"blank","RBRSA3A7","STFULAUT"
		);
		if(hdw.weaponstatus[HUNTF_SAFETY]==1)sb.drawimage("SAFETY",(-17,-14),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1,1));	
		sb.drawwepnum(hdw.weaponstatus[HUNTS_TUBE],hdw.weaponstatus[HUNTS_TUBESIZE],posy:-7);
		for(int i=hdw.weaponstatus[SHOTS_SIDESADDLE];i>0;i--){
			sb.drawrect(-16-i*2,-5,1,3);
		}
	}
	override string gethelptext(){
		return
		WEPHELP_USE.."+"..WEPHELP_FIREMODE.."  Safety\n"
		..WEPHELP_FIRE.."  Shoot (choke: "..weaponstatus[HUNTS_CHOKE]..")\n"
		..WEPHELP_ALTFIRE.."  Pump\n"
		..WEPHELP_RELOAD.."  Reload (side saddles first)\n"
		..WEPHELP_ZOOM.."+"..WEPHELP_RELOAD.."  Check Tube\n"
		..WEPHELP_ALTRELOAD.."  Reload (pockets only)\n"
		..(weaponstatus[0]&HUNTF_EXPORT?"":(WEPHELP_FIREMODE.."  Pump/Semi"..(weaponstatus[0]&HUNTF_CANFULLAUTO?"/Auto":"").."\n"))
		..WEPHELP_FIREMODE.."+"..WEPHELP_RELOAD.."  Load side saddles\n"
		..WEPHELP_USE.."+"..WEPHELP_UNLOAD.."  Steal ammo from Slayer\n"
		..WEPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		sb.SetClipRect(
			-16+bob.x,-32+bob.y,32,40,
			sb.DI_SCREEN_CENTER
		);
		vector2 bobb=bob*1.1;
		sb.drawimage(
			"frntsite",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
		);
		sb.SetClipRect(cx,cy,cw,ch);
		sb.drawimage(
			"sgbaksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9
		);
	}
	override double gunmass(){
		int tube=weaponstatus[HUNTS_TUBE];
		if(tube>4)tube+=(tube-4)*2;
		return 8+tube*0.3+weaponstatus[SHOTS_SIDESADDLE]*0.08;
	}
	override double weaponbulk(){
		return 125+(weaponstatus[SHOTS_SIDESADDLE]+weaponstatus[HUNTS_TUBE])*ENC_SHELLLOADED;
	}
	action void A_SwitchFireMode(bool forwards=true){
		if(invoker.weaponstatus[0]&HUNTF_EXPORT){
			invoker.weaponstatus[HUNTS_FIREMODE]=0;
			return;
		}
		int newfm=invoker.weaponstatus[HUNTS_FIREMODE]+(forwards?1:-1);
		int newmax=(invoker.weaponstatus[0]&HUNTF_CANFULLAUTO)?2:1;
		if(newfm>newmax)newfm=0;
		else if(newfm<0)newfm=newmax;
		invoker.weaponstatus[HUNTS_FIREMODE]=newfm;
	}
	action void A_SetAltHold(bool which){
		if(which)invoker.weaponstatus[0]|=HUNTF_ALTHOLDING;
		else invoker.weaponstatus[0]&=~HUNTF_ALTHOLDING;
	}
	action void A_Chamber(bool careful=false){
		int chm=invoker.weaponstatus[HUNTS_CHAMBER];
		invoker.weaponstatus[HUNTS_CHAMBER]=0;
		if(invoker.weaponstatus[HUNTS_TUBE]>0){
			invoker.weaponstatus[HUNTS_CHAMBER]=2;
			invoker.weaponstatus[HUNTS_TUBE]--;
		}
		vector3 cockdir;double cp=cos(pitch);
		if(careful)cockdir=(-cp,cp,-5);
		else cockdir=(0,-cp*5,sin(pitch)*frandom(4,6));
		cockdir.xy=rotatevector(cockdir.xy,angle);
		bool pocketed=false;
		if(chm>1){
			if(careful&&!A_JumpIfInventory("HDShellAmmo",0,"null")){
				HDF.Give(self,"HDShellAmmo",1);
				pocketed=true;
			}
		}else if(chm>0){	
			cockdir*=frandom(1.,1.3);
		}

		if(
			!pocketed
			&&chm>=1
		){
			vector3 gunofs=HDMath.RotateVec3D((9,-1,-2),angle,pitch);
			actor rrr=null;

			if(chm>1)rrr=spawn("HDFumblingShell",(pos.xy,pos.z+height*0.85)+gunofs+viewpos.offset);
			else rrr=spawn("HDSpentShell",(pos.xy,pos.z+height*0.85)+gunofs+viewpos.offset);

			rrr.target=self;
			rrr.angle=angle;
			rrr.vel=HDMath.RotateVec3D((1,-5,0.2),angle,pitch);
			if(chm==1)rrr.vel*=1.3;
			rrr.vel+=vel;
		}
	}
	action void A_CheckPocketSaddles(){
		if(invoker.weaponstatus[SHOTS_SIDESADDLE]<1)invoker.weaponstatus[0]|=HUNTF_FROMPOCKETS;
		if(!countinv("HDShellAmmo"))invoker.weaponstatus[0]&=~HUNTF_FROMPOCKETS;
	}
	action bool A_LoadTubeFromHand(){
		int hand=invoker.handshells;
		if(
			!hand
			||(
				invoker.weaponstatus[HUNTS_CHAMBER]>0
				&&invoker.weaponstatus[HUNTS_TUBE]>=invoker.weaponstatus[HUNTS_TUBESIZE]
			)
		){
			EmptyHand();
			return false;
		}
		invoker.weaponstatus[HUNTS_TUBE]++;
		invoker.handshells--;
		A_StartSound("weapons/huntreload",8,CHANF_OVERLAP);
		return true;
	}
	action bool A_GrabShells(int maxhand=3,bool settics=false,bool alwaysone=false){
		if(maxhand>0)EmptyHand();else maxhand=abs(maxhand);
		bool fromsidesaddles=!(invoker.weaponstatus[0]&HUNTF_FROMPOCKETS);
		int toload=min(
			fromsidesaddles?invoker.weaponstatus[SHOTS_SIDESADDLE]:countinv("HDShellAmmo"),
			alwaysone?1:(invoker.weaponstatus[HUNTS_TUBESIZE]-invoker.weaponstatus[HUNTS_TUBE]),
			maxhand
		);
		if(toload<1)return false;
		invoker.handshells=toload;
		if(fromsidesaddles){
			invoker.weaponstatus[SHOTS_SIDESADDLE]-=toload;
			if(settics)A_SetTics(2);
			A_StartSound("weapons/pocket",8,CHANF_OVERLAP,0.4);
			A_MuzzleClimb(
				frandom(0.1,0.15),frandom(0.05,0.08),
				frandom(0.1,0.15),frandom(0.05,0.08)
			);
		}else{
			A_TakeInventory("HDShellAmmo",toload,TIF_NOTAKEINFINITE);
			if(settics)A_SetTics(7);
			A_StartSound("weapons/pocket",9);
			A_MuzzleClimb(
				frandom(0.1,0.15),frandom(0.2,0.4),
				frandom(0.2,0.25),frandom(0.3,0.4),
				frandom(0.1,0.35),frandom(0.3,0.4),
				frandom(0.1,0.15),frandom(0.2,0.4)
			);
		}
		return true;
	}
	states{
	select0:
		SHTG A 0;
		goto select0big;
	deselect0:
		SHTG A 0;
		goto deselect0big;
	firemode:
		SHTG A 0 a_switchfiremode();
	firemodehold:
		---- A 1{
			if(pressingreload()){
				a_switchfiremode(false); //untoggle
				setweaponstate("reloadss");
			}else A_WeaponReady(WRF_NONE);
		}
		---- A 0 A_JumpIf(pressingfiremode()&&invoker.weaponstatus[SHOTS_SIDESADDLE]<12,"firemodehold");
		goto nope;
	Safety:
		---- A 0 {
		if(invoker.weaponstatus[HUNTF_SAFETY]==1)invoker.weaponstatus[HUNTF_SAFETY]=0;
		else invoker.weaponstatus[HUNTF_SAFETY]=1;}
		Goto Nope;
	ready:
		SHTG A 0 A_JumpIf(pressingunload()&&(pressinguse()||pressingzoom()),"cannibalize");
		---- A 0 A_JumpIf(pressinguse()&&pressingFiremode(),"Safety");
		SHTG A 0 A_JumpIf(pressingaltfire(),2);
		SHTG A 0{
			if(!pressingaltfire()){
				if(!pressingfire())A_ClearRefire();
				A_SetAltHold(false);
			}
		}
		SHTG A 1 A_WeaponReady(WRF_ALL);
		goto readyend;
	reloadSS:
		SHTG A 1 offset(1,34);
		SHTG A 2 offset(2,34);
		SHTG A 3 offset(3,36);
	reloadSSrestart:
		SHTG A 6 offset(3,35);
		SHTG A 9 offset(4,34);
		SHTG A 4 offset(3,34){
			int hnd=min(
				countinv("HDShellAmmo"),
				12-invoker.weaponstatus[SHOTS_SIDESADDLE],
				3
			);
			if(hnd<1)setweaponstate("reloadSSend");
			else{
				A_TakeInventory("HDShellAmmo",hnd);
				invoker.weaponstatus[SHOTS_SIDESADDLE]+=hnd;
				A_StartSound("weapons/pocket",8);
			}
		}
		SHTG A 0 {
			if(
				!PressingReload()
				&&!PressingAltReload()
			)setweaponstate("reloadSSend");
			else if(
				invoker.weaponstatus[SHOTS_SIDESADDLE]<12
				&&countinv("HDShellAmmo")
			)setweaponstate("ReloadSSrestart");
		}
	reloadSSend:
		SHTG A 3 offset(2,34);
		SHTG A 1 offset(1,34) EmptyHand(careful:true);
		goto nope;
	hold:
		SHTG A 0{
			bool paf=pressingaltfire();
			if(
				paf&&!(invoker.weaponstatus[0]&HUNTF_ALTHOLDING)
			)setweaponstate("chamber");
			else if(!paf)invoker.weaponstatus[0]&=~HUNTF_ALTHOLDING;
		}
		SHTG A 1 A_WeaponReady(WRF_NONE);
		SHTG A 0 A_Refire();
		goto ready;
	fire:
		---- A 0 A_JumpIf(invoker.weaponstatus[HUNTF_SAFETY]==1,"Nope");
		SHTG A 0 A_JumpIf(invoker.weaponstatus[HUNTS_CHAMBER]==2,"shoot");
		SHTG A 1 A_WeaponReady(WRF_NONE);
		SHTG A 0 A_Refire();
		goto ready;
	shoot:
		SHTG A 2;
		SHTG A 1 offset(0,36) A_FireHunter();
		SHTG E 1;
		SHTG E 0{
			if(
				invoker.weaponstatus[HUNTS_FIREMODE]>0
				&&invoker.shotpower>HUNTER_MINSHOTPOWER
			)setweaponstate("chamberauto");
		}goto ready;
	altfire:
	chamber:
		SHTG A 0 A_JumpIf(invoker.weaponstatus[0]&HUNTF_ALTHOLDING,"nope");
		SHTG A 0 A_SetAltHold(true);
		SHTG A 1 A_Overlay(120,"playsgco");
		SHTG AE 1 A_MuzzleClimb(0,frandom(0.6,1.));
		SHTG E 1 A_JumpIf(pressingaltfire(),"longstroke");
		SHTG EA 1 A_MuzzleClimb(0,-frandom(0.06,0.1));
		SHTG E 0 A_StartSound("weapons/huntshort",8);
		SHTG E 0 A_Refire("ready");
		goto ready;
	longstroke:
		SHTG F 2 A_MuzzleClimb(frandom(0.1,0.2));
		SHTG F 0{
			A_Chamber();
			A_MuzzleClimb(-frandom(0.1,0.2));
		}
	racked:
		SHTG F 1 A_WeaponReady(WRF_NOFIRE);
		SHTG F 0 A_JumpIf(!pressingaltfire(),"unrack");
		SHTG F 0 A_JumpIf((pressingunload()&&invoker.weaponstatus[HUNTS_CHAMBER]>0),"rackunload");
		SHTG F 0 A_JumpIf(invoker.weaponstatus[HUNTS_CHAMBER],"racked");
		SHTG F 0{
			int rld=0;
			if(pressingreload()){
				rld=1;
				if(invoker.weaponstatus[SHOTS_SIDESADDLE]>0)
				invoker.weaponstatus[0]&=~HUNTF_FROMPOCKETS;
				else{
					invoker.weaponstatus[0]|=HUNTF_FROMPOCKETS;
					rld=2;
				}
			}else if(pressingaltreload()){
				rld=2;
				invoker.weaponstatus[0]|=HUNTF_FROMPOCKETS;
			}
			if(
				(rld==2&&countinv("HDShellAmmo"))
				||(rld==1&&invoker.weaponstatus[SHOTS_SIDESADDLE]>0)
			)setweaponstate("rackreload");
		}
		loop;
	HandLoadShelRack:
		SHHA C 1 A_OverLayOffset(26, 18, 16);
		SHHA C 1 A_OverLayOffset(26, 12, 8);
		SHHA C 1 A_OverLayOffset(26, 6, 0);
		SHHA D 1 {if((HDPlayerPawn(self).bloodpressure>40)||(Health<41))A_OverLayOffset(-26, -3, -8); Else A_OverLayOffset(26, -2, -6);}
		SHHA D 1 A_OverLayOffset(26, -2, -7);
		SHHA D 1 {if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, -1, -6); Else A_OverLayOffset(26, -2, -8);}
		SHHA D 1 A_OverLayOffset(26, -2, -9);
		RVHA C 1 A_OverLayOffset(26, -32, 45);
		RVHA C 1 A_OverLayOffset(26, -28, 52);
		Stop;	
	rackreload:
		SHTG F 1 offset(-1,35) A_WeaponBusy(true);
		SHTG F 2 offset(-2,37);
		SHTG F 4 offset(-3,40);
		SHTG F 1 offset(-4,42) A_GrabShells(1,true,true);
		SHTG F 0 A_JumpIf(!(invoker.weaponstatus[0]&HUNTF_FROMPOCKETS),"rackloadone");
		SHTG F 6 offset(-5,43);
		SHTG F 6 offset(-4,41) A_StartSound("weapons/pocket",9);
	rackloadone:
		---- A 0 A_OverLay(26, "HandLoadShelRack");	
		SHTG F 1 offset(-4,42);
		SHTG F 2 offset(-4,41);
		SHTG F 3 offset(-4,40){
			A_StartSound("weapons/huntreload",8,CHANF_OVERLAP);
			invoker.weaponstatus[HUNTS_CHAMBER]=2;
			invoker.handshells--;
			EmptyHand(careful:true);
		}
		SHTG F 5 offset(-4,41);
		SHTG F 4 offset(-4,40) A_JumpIf(invoker.handshells>0,"rackloadone");
		goto rackreloadend;
	rackreloadend:
		SHTG F 1 offset(-3,39);
		SHTG F 1 offset(-2,37);
		SHTG F 1 offset(-1,34);
		SHTG F 0 A_WeaponBusy(false);
		goto racked;

	HandUnLoadRack:
		RVHA C 1 A_OverLayOffset(26, -28, 49);
		RVHA C 1 A_OverLayOffset(26, -32, 35);
		RVHA C 1 A_OverLayOffset(26, -35, 33);
		SHHA D 1 A_OverLayOffset(26, -2, -9);
		SHHA D 1 {if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, -1, -10); Else A_OverLayOffset(26, -2, -8);}
		SHHA D 1 A_OverLayOffset(26, -2, -7);
		SHHA D 1 {if((HDPlayerPawn(self).bloodpressure>40)||(Health<41))A_OverLayOffset(-26, -1, -4); Else A_OverLayOffset(26, -2, -3);}
		SHHA C 1 A_OverLayOffset(26, 12, 8);
		SHHA C 1 A_OverLayOffset(26, 18, 16);
		Stop;	
	rackunload:
		SHTG F 1 offset(-1,35) A_WeaponBusy(true);
		SHTG F 2 offset(-2,37);
		SHTG F 4 offset(-3,40);
		---- A 0 A_OverLay(26, "HandUnLoadRack");	
		SHTG F 1 offset(-4,42);
		SHTG F 2 offset(-4,41);
		SHTG F 3 offset(-4,40){
			int chm=invoker.weaponstatus[HUNTS_CHAMBER];
			invoker.weaponstatus[HUNTS_CHAMBER]=0;
			if(chm==2){
				invoker.handshells++;
				EmptyHand(careful:true);
			}else if(chm==1)A_SpawnItemEx("HDSpentShell",
				cos(pitch)*8,0,height-7-sin(pitch)*8,
				vel.x+cos(pitch)*cos(angle-random(86,90))*5,
				vel.y+cos(pitch)*sin(angle-random(86,90))*5,
				vel.z+sin(pitch)*random(4,6),
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
			if(chm)A_StartSound("weapons/huntreload",8,CHANF_OVERLAP);
		}
		SHTG F 5 offset(-4,41);
		SHTG F 4 offset(-4,40) A_JumpIf(invoker.handshells>0,"rackloadone");
		goto rackreloadend;

	unrack:
		SHTG F 0 A_Overlay(120,"playsgco2");
		SHTG E 1 A_JumpIf(!pressingfire(),1);
		SHTG EA 2{
			if(pressingfire())A_SetTics(1);
			A_MuzzleClimb(0,-frandom(0.6,1.));
		}
		SHTG A 0 A_ClearRefire();
		goto ready;
	playsgco:
		TNT1 A 8 A_StartSound("weapons/huntrackup",8);
		TNT1 A 0 A_StopSound(8);
		stop;
	playsgco2:
		TNT1 A 8 A_StartSound("weapons/huntrackdown",8);
		TNT1 A 0 A_StopSound(8);
		stop;
	chamberauto:
		SHTG A 1 A_Chamber();
		SHTG A 1 A_JumpIf(invoker.weaponstatus[0]&HUNTF_CANFULLAUTO&&invoker.weaponstatus[HUNTS_FIREMODE]==2,"ready");
		SHTG A 0 A_Refire();
		goto ready;
	flash:
		SHTF B 1 bright{
			A_Light2();
			HDFlashAlpha(-32);
		}
		TNT1 A 1 A_ZoomRecoil(0.9);
		TNT1 A 0 A_Light0();
		TNT1 A 0 A_AlertMonsters();
		stop;
	altreload:
	reloadfrompockets:
		SHTG A 0{
			if(!countinv("HDShellAmmo"))setweaponstate("nope");
			else invoker.weaponstatus[0]|=HUNTF_FROMPOCKETS;
		}goto startreload;
	CheckTube:
		SHTG A 1;
		SHTG BC 4 A_MuzzleClimb(frandom(1.2,2.4),-frandom(1.2,2.4));
		SHTG C 1 offset(0,34);
		SHTG C 1 offset(0,36) A_StartSound("weapons/huntopen",8);
		SHTG C 1 offset(0,38);
		SHTG C 4 offset(0,36) A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		SHTG D 1 offset(0,34) A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
	CheckLoop:	
		---- A 0 {if(invoker.weaponstatus[HUNTS_TUBE]>0)A_OverLay(102,"Dumb");
				if(invoker.weaponstatus[HUNTS_CHAMBER]>0)A_OverLay(103,"Dumb3");}
		SHTG D 5 offset(0,34) A_JumpIf(!pressingreload(),"CheckEnd");
		Loop;		
	CheckEnd:
		SHTG C 4 offset(0,34) A_StartSound("weapons/huntopen",8);
		SHTG C 1 offset(0,36);
		SHTG C 1 offset(0,34);
		SHTG CBA 3;
		SHTG A 0 A_JumpIf(invoker.weaponstatus[0]&HUNTF_HOLDING,"nope");
		goto ready;
	Dumb:
		STUP A 0 A_OverLayOffset(102,29,20);
		---- A 0 A_JumpIf(Invoker.WeaponStatus[HUNTS_TUBESIZE]==5,"Dumb2");
		STUP A 5 A_JumpIf(invoker.weaponstatus[HUNTS_TUBE]>1,1);
		Stop;
		STUP D 5 A_JumpIf(invoker.weaponstatus[HUNTS_TUBE]>2,1);
		Stop;
		STUP F 5 A_JumpIf(invoker.weaponstatus[HUNTS_TUBE]>3,1);
		Stop;
		STUP I 5 A_JumpIf(invoker.weaponstatus[HUNTS_TUBE]>4,1);
		Stop;
		STUP K 5 A_JumpIf(invoker.weaponstatus[HUNTS_TUBE]>5,1);
		Stop;
		STUP M 5 A_JumpIf(invoker.weaponstatus[HUNTS_TUBE]>6,1);
		Stop;
		STUP O 5;
		Stop;	
	Dumb3:
		STUP A 0 A_OverLayOffset(103,29,17);
		STUP A 5 A_JumpIf(Invoker.WeaponStatus[HUNTS_CHAMBER]>1,1);
		Stop;
		STUP P 5;
		Stop;
	Dumb2:
		STUP B 5 A_JumpIf(invoker.weaponstatus[HUNTS_TUBE]>1,1);
		Stop;
		STUP E 5 A_JumpIf(invoker.weaponstatus[HUNTS_TUBE]>2,1);
		Stop;
		STUP H 5 A_JumpIf(invoker.weaponstatus[HUNTS_TUBE]>3,1);
		Stop;
		STUP L 5 A_JumpIf(invoker.weaponstatus[HUNTS_TUBE]>4,1);
		Stop;
		STUP O 5;
		Stop;	
	reload:
	reloadfromsidesaddles:
		SHTG A 0{
			If(pressingzoom())Setweaponstate("CheckTube");
			int sss=invoker.weaponstatus[SHOTS_SIDESADDLE];
			int ppp=countinv("HDShellAmmo");
			if(ppp<1&&sss<1&&!pressingzoom())setweaponstate("nope");
				else if(sss<1)
					invoker.weaponstatus[0]|=HUNTF_FROMPOCKETS;
				else invoker.weaponstatus[0]&=~HUNTF_FROMPOCKETS;
		}goto startreload;
	startreload:
		SHTG A 1{
			if(
				invoker.weaponstatus[HUNTS_TUBE]>=invoker.weaponstatus[HUNTS_TUBESIZE]
			){
				if(
					invoker.weaponstatus[SHOTS_SIDESADDLE]<12
					&&countinv("HDShellAmmo")
				)setweaponstate("ReloadSS");
				else setweaponstate("nope");
			}
		}
		SHTG AB 4 A_MuzzleClimb(frandom(.6,.7),-frandom(.6,.7));
	reloadstarthand:
		SHTG C 1 offset(0,36);
		SHTG C 1 offset(0,38);
		SHTG C 2 offset(0,36);
		SHTG C 2 offset(0,34);
		SHTG C 3 offset(0,36);
		SHTG C 3 offset(0,40) A_CheckPocketSaddles();
		SHTG C 0 A_JumpIf(invoker.weaponstatus[0]&HUNTF_FROMPOCKETS,"reloadpocket");
	reloadfast:
		SHTG C 3 offset(0,40) A_GrabShells(3,false);
		SHTG C 3 offset(0,42) A_StartSound("weapons/pocket",9,volume:0.4);
		SHTG C 2 offset(0,41);
		goto reloadashell;
	reloadpocket:
		SHTG C 3 offset(0,39) A_GrabShells(3,false);
		SHTG C 5 offset(0,42) A_StartSound("weapons/pocket",9);
		SHTG C 6 offset(0,41) A_StartSound("weapons/pocket",9);
		SHTG C 4 offset(0,40);
		goto reloadashell;
	HandLoadShell:
		SHHA A 1 A_OverLayOffset(-26, -11, 1);
		SHHA A 1 A_OverLayOffset(-26, -16, -1);
		SHHA B 1 A_OverLayOffset(-26, 0, 0);
		SHHA B 1{if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, -1, 1); Else A_OverLayOffset(-26, 2, -2);}
		SHHA B 1 A_OverLayOffset(-26, 1, -3);
		SHHA B 1{if((HDPlayerPawn(self).bloodpressure>20)||(Health<41))A_OverLayOffset(-26, -1, 1); Else A_OverLayOffset(-26, 0, -4);}
		SHHA B 1 A_OverLayOffset(-26, 0, -2);
		SHHA B 1{if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, -1, 1); Else A_OverLayOffset(-26, 0, 0);}
		SHHA B 1 A_OverLayOffset(-26, 1, 4);
		SHHA B 1{if((HDPlayerPawn(self).bloodpressure>20)||(Health<41))A_OverLayOffset(-26, 3, 3); Else A_OverLayOffset(-26, 3, 7);}
		SHHA B 1 A_OverLayOffset(-26, 4, 9);
		SHHA B 1{if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, 7, 10); Else A_OverLayOffset(-26, 12, 14);}
		SHHA B 1 A_OverLayOffset(-26, 13, 19);
		SHHA B 1 A_OverLayOffset(-26, 14, 24);
		SHHA B 1 A_OverLayOffset(-26, 15, 29);
		Stop;	
	reloadashell:
		---- A 0 A_OverLay(-26, "HandLoadShell");
		SHTG C 2 offset(0,36);
		SHTG C 4 offset(0,34)A_LoadTubeFromHand();
		SHTG CCCCCC 1 offset(0,33){
			if(
				PressingReload()
				||PressingAltReload()
				||PressingUnload()
				||PressingFire()
				||PressingAltfire()
				||PressingZoom()
				||PressingFiremode()
			)invoker.weaponstatus[0]|=HUNTF_HOLDING;
			else invoker.weaponstatus[0]&=~HUNTF_HOLDING;

			if(
				invoker.weaponstatus[HUNTS_TUBE]>=invoker.weaponstatus[HUNTS_TUBESIZE]
				||(
					invoker.handshells<1&&(
						invoker.weaponstatus[0]&HUNTF_FROMPOCKETS
						||invoker.weaponstatus[SHOTS_SIDESADDLE]<1
					)&&
					!countinv("HDShellAmmo")
				)
			)setweaponstate("reloadend");
			else if(
				!pressingaltreload()
				&&!pressingreload()
			)setweaponstate("reloadend");
			else if(invoker.handshells<1)setweaponstate("reloadstarthand");
		}goto reloadashell;
	reloadend:
		SHTG C 4 offset(0,34) A_StartSound("weapons/huntopen",8);
		SHTG C 1 offset(0,36) EmptyHand(careful:true);
		SHTG C 1 offset(0,34);
		SHTG CBA 3;
		SHTG A 0 A_JumpIf(invoker.weaponstatus[0]&HUNTF_HOLDING,"nope");
		goto ready;

	cannibalize:
		SHTG A 2 offset(0,36) A_JumpIf(!countinv("Slayer"),"nope");
		SHTG A 2 offset(0,40) A_StartSound("weapons/pocket",9);
		SHTG A 6 offset(0,42);
		SHTG A 4 offset(0,44);
		SHTG A 6 offset(0,42);
		SHTG A 2 offset (0,36) A_CannibalizeOtherShotgun();
		goto ready;

	unloadSS:
		SHTG A 2 offset(1,34) A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]<1,"nope");
		SHTG A 1 offset(2,34);
		SHTG A 1 offset(3,36);
	unloadSSLoop1:
		SHTG A 4 offset(4,36);
		SHTG A 2 offset(5,37) A_UnloadSideSaddle();
		SHTG A 3 offset(4,36){	//decide whether to loop
			if(
				PressingReload()
				||PressingFire()
				||PressingAltfire()
				||invoker.weaponstatus[SHOTS_SIDESADDLE]<1
			)setweaponstate("unloadSSend");
		}goto unloadSSLoop1;
	unloadSSend:
		SHTG A 3 offset(4,35);
		SHTG A 2 offset(3,35);
		SHTG A 1 offset(2,34);
		SHTG A 1 offset(1,34);
		goto nope;
	HandUnLoad:
		RVHA A 1 A_OverLayOffset(-26, -40, 40);
		RVHA A 1 A_OverLayOffset(-26, -40, 35);
		RVHA A 1 A_OverLayOffset(-26, -40, 30);
		RVHA A 1 A_OverLayOffset(-26, -40, 28);
		RVHA A 1 A_OverLayOffset(-26, -45, 22);
		SHHA B 1 {if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, 0, 5); Else A_OverLayOffset(-26, 1, 4);}
		SHHA B 1 A_OverLayOffset(-26, 1, 4);
		SHHA B 1{if((HDPlayerPawn(self).bloodpressure>40)||(Health<41))A_OverLayOffset(-26, -1, 3); Else A_OverLayOffset(-26, 1, 4);}
		SHHA B 1 A_OverLayOffset(-26, 1, 4);
		SHHA B 1 {if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, 0, 5); Else A_OverLayOffset(-26, 1, 4);}
		SHHA B 1 A_OverLayOffset(-26, 3, 7);
		SHHA B 1 {if((HDPlayerPawn(self).bloodpressure>40)||(Health<41))A_OverLayOffset(-26, 3, 6); Else A_OverLayOffset(-26, 4, 9);}
		SHHA B 1 A_OverLayOffset(-26, 12, 14);
		SHHA B 1 {if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, 11, 16); Else A_OverLayOffset(-26, 13, 19);}
		SHHA B 1 A_OverLayOffset(-26, 14, 24);
		SHHA B 1 A_OverLayOffset(-26, 15, 29);
		Stop;	
	HandUnLoading:
		SHHA B 1 A_OverLayOffset(-26, 5, 7);
		SHHA B 1 {if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, 6, 8); Else A_OverLayOffset(-26, 5, 7);}
		SHHA B 2 A_OverLayOffset(-26, 4, 6);
		SHHA B 1 {if((HDPlayerPawn(self).bloodpressure>40)||(Health<41))A_OverLayOffset(-26, 4, 7); Else A_OverLayOffset(-26, 3, 5);}
		SHHA B 1 A_OverLayOffset(-26, 3, 5);
		SHHA B 2 A_OverLayOffset(-26, 2, 3);
		SHHA B 1 {if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, 3, 4); Else A_OverLayOffset(-26, 1, 3);}
		SHHA B 1 A_OverLayOffset(-26, 1, 3);
		SHHA B 2 A_OverLayOffset(-26, 0, 2);
		SHHA B 1 A_OverLayOffset(-26, 4, 7);
		SHHA B 1 A_OverLayOffset(-26, 15, 12);
	HandUnloaded:	
		SHHA B 1 A_OverLayOffset(-26, 20, 18);
		SHHA B 1 A_OverLayOffset(-26, 21, 24);
		SHHA B 1 A_OverLayOffset(-26, 22, 29);
		Stop;	
	HandUnloadCham:
		RVHA C 1 A_OverLayOffset(26, -40, 50);
		RVHA C 1 A_OverLayOffset(26, -50, 40);
		RVHA C 1 A_OverLayOffset(26, -60, 30);
		SHHA B 1 A_OverLayOffset(26, -10, 17);
		SHHA B 1 A_OverLayOffset(26, -14, 16);
		SHHA A 1 A_OverLayOffset(26, -30, 16);
		SHHA A 1 A_OverLayOffset(26, -22, 23);
		SHHA A 1 A_OverLayOffset(26, -17, 32);
		Stop;
	unload:
		SHTG A 1{
			if(
				invoker.weaponstatus[SHOTS_SIDESADDLE]>0
				&&!(player.cmd.buttons&BT_USE)
			)setweaponstate("unloadSS");
			else if(
				invoker.weaponstatus[HUNTS_CHAMBER]<1
				&&invoker.weaponstatus[HUNTS_TUBE]<1
			)setweaponstate("nope");
		}
		SHTG BC 4 A_MuzzleClimb(frandom(1.2,2.4),-frandom(1.2,2.4));
		SHTG C 1 offset(0,34);
		SHTG C 1 offset(0,36) A_StartSound("weapons/huntopen",8);
		SHTG C 1 offset(0,38);
		SHTG C 4 offset(0,36){
			A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
			if(invoker.weaponstatus[HUNTS_CHAMBER]<1){
				setweaponstate("unloadtube");
			}else A_StartSound("weapons/huntrack",8,CHANF_OVERLAP);
		}
		---- A 0 A_OverLay(26, "HandUnloadCham");
		SHTG D 8 offset(0,34){
			A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
			int chm=invoker.weaponstatus[HUNTS_CHAMBER];
			invoker.weaponstatus[HUNTS_CHAMBER]=0;
			if(chm>1){
				A_StartSound("weapons/huntreload",8);
				if(A_JumpIfInventory("HDShellAmmo",0,"null"))A_SpawnItemEx("HDFumblingShell",
					cos(pitch)*8,0,height-7-sin(pitch)*8,
					vel.x+cos(pitch)*cos(angle-random(86,90))*5,
					vel.y+cos(pitch)*sin(angle-random(86,90))*5,
					vel.z+sin(pitch)*random(4,6),
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);else{
					HDF.Give(self,"HDShellAmmo",1);
					A_StartSound("weapons/pocket",9);
					A_SetTics(5);
				}
			}else if(chm>0){A_SpawnItemEx("HDSpentShell",
				cos(pitch)*8,0,height-7-sin(pitch)*8,
				vel.x+cos(pitch)*cos(angle-random(86,90))*5,
				vel.y+cos(pitch)*sin(angle-random(86,90))*5,
				vel.z+sin(pitch)*random(4,6),
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			); A_OverLay(26, "None");}
		}
		SHTG C 0 A_JumpIf(!pressingunload(),"reloadend");
		SHTG C 4 offset(0,40);
	unloadtube:
		---- A 0 A_OverLay(-26,"HandUnload");
		SHTG C 6 offset(0,40) EmptyHand(careful:true);
	unloadloop:
		---- A 0 A_OverLay(-26,"HandUnloading");
		SHTG C 8 offset(1,41){
			if(invoker.weaponstatus[HUNTS_TUBE]<1){setweaponstate("reloadend"); A_OverLay(-26,"HandUnloaded");}
			else if(invoker.handshells>=3)setweaponstate("unloadloopend");
			else{
				invoker.handshells++;
				invoker.weaponstatus[HUNTS_TUBE]--;
			}
		}
		SHTG C 4 offset(0,40) A_StartSound("weapons/huntreload",8);
		loop;
	unloadloopend:
		SHTG C 6 offset(1,41);
		SHTG C 3 offset(1,42){
			int rmm=HDPickup.MaxGive(self,"HDShellAmmo",ENC_SHELL);
			if(rmm>0){
				A_StartSound("weapons/pocket",9);
				A_SetTics(8);
				HDF.Give(self,"HDShellAmmo",min(rmm,invoker.handshells));
				invoker.handshells=max(invoker.handshells-rmm,0);
			}
		}
		SHTG C 0 EmptyHand(careful:true);
		SHTG C 6 A_Jumpif(!pressingunload(),"reloadend");
		goto unloadloop;
	spawn:
		HUNT ABCDEFG -1 nodelay{
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
		weaponstatus[HUNTS_CHAMBER]=2;
		if(!idfa){
			weaponstatus[HUNTS_TUBESIZE]=7;
			weaponstatus[HUNTS_CHOKE]=1;
		}
		weaponstatus[HUNTS_TUBE]=weaponstatus[HUNTS_TUBESIZE];
		weaponstatus[SHOTS_SIDESADDLE]=12;
		handshells=0;
	}
	override void loadoutconfigure(string input){
		int type=getloadoutvar(input,"type",1);
		if(type>=0){
			switch(type){
			case 0:
				weaponstatus[0]|=HUNTF_EXPORT;
				weaponstatus[0]&=~HUNTF_CANFULLAUTO;
				break;
			case 1:
				weaponstatus[0]&=~HUNTF_EXPORT;
				weaponstatus[0]&=~HUNTF_CANFULLAUTO;
				break;
			case 2:
				weaponstatus[0]&=~HUNTF_EXPORT;
				weaponstatus[0]|=HUNTF_CANFULLAUTO;
				break;
			default:
				break;
			}
		}
		if(type<0||type>2)type=1;
		int firemode=getloadoutvar(input,"firemode",1);
		if(firemode>=0)weaponstatus[HUNTS_FIREMODE]=clamp(firemode,0,type);
		int choke=min(getloadoutvar(input,"choke",1),7);
		if(choke>=0)weaponstatus[HUNTS_CHOKE]=choke;

		int tubesize=((weaponstatus[0]&HUNTF_EXPORT)?5:7);
		if(weaponstatus[HUNTS_TUBE]>tubesize)weaponstatus[HUNTS_TUBE]=tubesize;
		weaponstatus[HUNTS_TUBESIZE]=tubesize;
	}
}
enum hunterstatus{
	HUNTF_CANFULLAUTO=1,
	HUNTF_JAMMED=2,
	HUNTF_UNLOADONLY=4,
	HUNTF_FROMPOCKETS=8,
	HUNTF_ALTHOLDING=16,
	HUNTF_SAFETY=18,
	HUNTF_HOLDING=32,
	HUNTF_EXPORT=64,

	HUNTS_FIREMODE=1,
	HUNTS_CHAMBER=2,
	//3 is for side saddles
	HUNTS_TUBE=4,
	HUNTS_TUBESIZE=5,
	HUNTS_HAND=6,
	HUNTS_CHOKE=7,
};


class HunterRandom:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let ggg=Hunter(spawn("Hunter",pos,ALLOW_REPLACE));
			if(!ggg)return;
			HDF.TransferSpecials(self,ggg,HDF.TS_ALL);

			if(!random(0,7))ggg.weaponstatus[HUNTS_CHOKE]=random(0,7);
			if(!random(0,32)){
				ggg.weaponstatus[0]&=~HUNTF_EXPORT;
				ggg.weaponstatus[0]|=HUNTF_CANFULLAUTO;
			}else if(!random(0,7)){
				ggg.weaponstatus[0]|=HUNTF_EXPORT;
				ggg.weaponstatus[0]&=~HUNTF_CANFULLAUTO;
			}
			int tubesize=((ggg.weaponstatus[0]&HUNTF_EXPORT)?5:7);
			if(ggg.weaponstatus[HUNTS_TUBE]>tubesize)ggg.weaponstatus[HUNTS_TUBE]=tubesize;
			ggg.weaponstatus[HUNTS_TUBESIZE]=tubesize;
		}stop;
	}
}

