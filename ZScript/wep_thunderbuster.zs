// ------------------------------------------------------------
// Thunder Buster
// ------------------------------------------------------------
class ThunderBuster:HDCellWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Thunder Buster"
		//$Sprite "PLASA0"

		+hdweapon.fitsinbackpack
		weapon.selectionorder 70;
		weapon.slotnumber 6;
		weapon.slotpriority 1;
		weapon.bobrangex 0.2;
		weapon.bobrangey 0.9;
		scale 0.6;
		inventory.pickupmessage "$PICKUP_THUNDERBUSTER";
		obituary "$OB_THUNDERBUSTER";
		hdweapon.barrelsize 28,1.6,3;
		hdweapon.refid HDLD_THUNDER;
		tag "$TAG_THUNDER";

		hdweapon.loadoutcodes "
			\cualt - 0/1, whether to start in spray fire mode";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override void tick(){
		super.tick();
		drainheat(TBS_HEAT,12);
	}
	override double gunmass(){
		return 10+(weaponstatus[TBS_BATTERY]<0?0:2);
	}
	override double weaponbulk(){
		return 175+(weaponstatus[1]>=0?ENC_BATTERY_LOADED:0);
	}
	override string,double getpickupsprite(){return "PLASA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawbattery(-54,-4,sb.DI_SCREEN_CENTER_BOTTOM,reloadorder:true);
			sb.drawnum(hpl.countinv("HDBattery"),-46,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(hdw.weaponstatus[0]&TBF_ALT){
			sb.drawimage(
				"STBURAUT",(-28,-10),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TRANSLATABLE|sb.DI_ITEM_RIGHT
			);
			sb.drawnum(int(2000/HDCONST_ONEMETRE),-16,-17,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_GRAY);
		}else sb.drawnum(hdw.weaponstatus[TBS_MAXRANGEDISPLAY],-16,-17,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_GRAY);
		int bat=hdw.weaponstatus[TBS_BATTERY];
		if(bat>0)sb.drawwepnum(bat,20);
		else if(!bat)sb.drawstring(
			sb.mamountfont,"00000",
			(-16,-9),sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);
		if(hdw.weaponstatus[TBF_SAFETY]==1)sb.drawimage("SAFETY",(-17,-16),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1,1));	
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRESHOOT
		..LWPHELP_ALTFIRE..StringTable.Localize("$THBWH_SWITCH")..(weaponstatus[0]&TBF_ALT?StringTable.Localize("$THBWH_DETONATOR"):StringTable.Localize("$THBWH_SCATTERSHOT"))..StringTable.Localize("$THBWH_MODE")
		..LWPHELP_RELOADRELOAD
		..LWPHELP_UNLOADUNLOAD
		..LWPHELP_ALTRELOAD..StringTable.Localize("$THBWH_ALTRELOAD").."\n"
		..LWPHELP_USE.."+"..LWPHELP_FIREMODE..StringTable.Localize("$LWPHELP_SAFETY")
		;
	}
	int rangefinder;
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int Light = Owner.CurSector.LightLevel*1.75;
		if(owner.player.fixedlightlevel==1)Light = 255;
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		sb.SetClipRect(
			-16+bob.x,-4+bob.y,32,16,
			sb.DI_SCREEN_CENTER
		);
		vector2 bobb=bob*1.2;
		sb.drawimage(
			"tbfrntsit",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
		);
		if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
		sb.drawimage(
			"TBBLFTSIT",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP, Col:Color(254-Light, 0,0,0)
		);
		sb.SetClipRect(cx,cy,cw,ch);
		sb.drawimage(
			"tbbaksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9
		);
		if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
		sb.drawimage(
			"TBBLKSIT",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9, Col:Color(254-Light, 0,0,0)
		);
		
		if(scopeview){
			bool alt=hdw.weaponstatus[0]&TBF_ALT;
			int scaledyoffset=36;

			name ctex="HDXCAM_TB";

			texman.setcameratotexture(hpc,ctex,3);
			sb.drawimage(
				ctex,(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				alpha:alt?(hpl.flip?0.7:0.8):1.,scale:((0.25/1.2),0.25)
			);
			let tb=ThunderBuster(hdw);
			sb.drawnum(min(tb.rangefinder,999),
				24+bob.x,12+bob.y,sb.DI_SCREEN_CENTER,
				(
					tb.rangefinder>=10
					&&tb.rangefinder<hdw.weaponstatus[TBS_MAXRANGEDISPLAY]
				)?Font.CR_GRAY:Font.CR_RED
				,0.4
			);
			sb.drawnum(hdw.weaponstatus[TBS_MAXRANGEDISPLAY],
				24+bob.x,20+bob.y,sb.DI_SCREEN_CENTER,Font.CR_WHITE,0.4
			);
			if(alt)sb.drawnum(int(2000/HDCONST_ONEMETRE),
				23+bob.x,19+bob.y,sb.DI_SCREEN_CENTER,Font.CR_BLACK,1.
			);
			sb.drawimage(
				"tbwindow",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:(1,1)
			);
			if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
			sb.drawimage(
				"tbBlk",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:(1,1), col:Color(254-Light, 0,0,0)
			);
			bobb*=3;
			double dotoff=max(abs(bobb.x),abs(bobb.y));
			if(dotoff<40)sb.drawimage(
				"redpxl",(0,scaledyoffset)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
				alpha:(alt?0.4:0.9)*(1.-dotoff*0.04),scale:alt?(hpl.flip?(3,3):(1,1)):(2,2)
			);
		}
	}
	override void failedpickupunload(){
		failedpickupunloadmag(TBS_BATTERY,"HDBattery");
	}
	override void consolidate(){
		CheckBFGCharge(TBS_BATTERY);
	}
	static void ThunderZap(
		actor caller,
		double zoffset=32,
		bool alt=false,
		int battery=20
	){
		//determine angle
		double shootangle=caller.angle;
		double shootpitch=caller.pitch;
		vector3 shootpos=(0,0,zoffset);
		let hdp=hdplayerpawn(caller);
		if(hdp){
			shootangle=hdp.gunangle;
			shootpitch=hdp.gunpitch;
			shootpos=hdp.gunpos;
		}
		if(alt){
			shootangle+=frandom(-1.2,1.2);
			shootpitch+=frandom(-1.3,1.1);
		}

		//create the line
		flinetracedata tlt;
		caller.linetrace(
			shootangle,
			8000+200*battery,
			shootpitch,
			flags:TRF_NOSKY|TRF_ABSOFFSET,
			offsetz:shootpos.z,
			offsetforward:shootpos.x,
			offsetside:shootpos.y,
			data:tlt
		);


		if(
			tlt.hittype==Trace_HitNone
			||(
				tlt.hitline&&(
					tlt.hitline.special==Line_Horizon
					||(
						tlt.linepart==2
						&&tlt.hitsector.gettexture(0)==skyflatnum
					)||(
						tlt.linepart==1
						&&tlt.hitline.sidedef[1]
						&&hdmath.oppositesector(tlt.hitline,tlt.hitsector).gettexture(0)==skyflatnum
					)
				)
			)
		)return;

		//alt does a totally different thing
		if(alt){
			if(tlt.hittype==Trace_HitNone||tlt.distance>2000)return;
			actor bbb=spawn("BeamSpotFlash",tlt.hitlocation-tlt.hitdir,ALLOW_REPLACE);
			bbb.setz(clamp(bbb.pos.z,bbb.floorz,bbb.ceilingz-8));
			if(!random(0,3))(lingeringthunder.zap(bbb,bbb,caller,40,true));
			beamspotflash(bbb).impactdistance=tlt.distance-16*battery;
			bbb.angle=caller.angle;
			bbb.A_SprayDecal("Scorch",12);
			bbb.pitch=caller.pitch;
			bbb.target=caller;
			bbb.tracer=tlt.hitactor; //damage inflicted on the puff's end
			if(tlt.hitline)doordestroyer.CheckDirtyWindowBreak(tlt.hitline,0.005*battery,tlt.hitlocation);
			return;
		}

		int basedmg=int(max(0,20-tlt.distance*(1./50.)));
		int dmgflags=caller&&caller.player?DMG_PLAYERATTACK:0; //don't know why the player damagemobj doesn't work

		if(tlt.hitline)doordestroyer.CheckDirtyWindowBreak(tlt.hitline,0.003*basedmg,tlt.hitlocation);

		//wet actor
		if(
			tlt.hitactor
		){
			actor hitactor=tlt.hitactor;
			if(hitactor.bloodtype=="ShieldNotBlood"){
				hitactor.damagemobj(null,caller,random(1,(battery<<2)),"Balefire",dmgflags);
			}else if(
				hitactor.bnodamage
				||hitactor.bnoblood
				||hitactor.bloodtype=="NotQuiteBloodSplat"
				||random(0,7)
				||hitactor.countinv("ImmunityToFire")
				||HDWoundFixer.CheckCovered(hitactor,true)
			){
				//dry actor - ping damage and continue
				if(!random(0,5))(lingeringthunder.zap(hitactor,hitactor,caller,40,true));
				hdf.give(hitactor,"Heat",(basedmg>>1));
				hitactor.damagemobj(null,caller,1,"electrical",dmgflags);
			}else{
				//wet actor
				if(!random(0,7))(lingeringthunder.zap(hitactor,hitactor,caller,(basedmg<<1),true));
				hdf.give(hitactor,"Heat",(basedmg<<1));
				hitactor.damagemobj(null,caller,basedmg,"electrical",dmgflags);
				actor sss=spawn("HDGunsmoke",tlt.hitlocation,ALLOW_REPLACE);
				sss.vel=(0,0,1)-tlt.hitdir;
				return;
			}
		}
		//where where the magic happens happens
		actor bbb=spawn("BeamSpot",tlt.hitlocation-tlt.hitdir,ALLOW_REPLACE);
		bbb.setz(clamp(bbb.pos.z,bbb.floorz,bbb.ceilingz-8));
		bbb.target=caller;
		bbb.stamina=basedmg;
		bbb.angle=caller.angle;
		bbb.pitch=caller.pitch;
	}
	action void A_ThunderZap(){
		if(invoker.weaponstatus[TBS_HEAT]>20)return;
		int battery=invoker.weaponstatus[TBS_BATTERY];
		if(battery<1){
			setweaponstate("nope");
			return;
		}

		//preliminary effects
		A_ZoomRecoil(0.99);
		A_StartSound("weapons/plasidle");
		if(IsMoving.Count(self)>9)A_MuzzleClimb(frandom(-0.8,0.8),frandom(-0.8,0.8));

		//the actual call
		ThunderBuster.ThunderZap(
			self,
			gunheight(),
			invoker.weaponstatus[0]&TBF_ALT,
			battery
		);

		//aftereffects
		if(invoker.weaponstatus[0]&TBF_ALT){
			if(!random(0,4))invoker.weaponstatus[TBS_BATTERY]--;
			A_MuzzleClimb(
				frandom(0.05,0.2),frandom(-0.2,-0.4),
				frandom(0.1,0.3),frandom(-0.2,-0.6),
				frandom(0.04,0.12),frandom(-0.1,-0.3),
				frandom(0.01,0.03),frandom(-0.1,-0.2)
			);
			invoker.weaponstatus[TBS_HEAT]+=6;
		}else if(!random(0,6))invoker.weaponstatus[TBS_BATTERY]--;
		invoker.weaponstatus[TBS_HEAT]+=random(0,3);

		//update range thingy
		invoker.weaponstatus[TBS_MAXRANGEDISPLAY]=int(
			(battery>0?battery*200+8000:0)/HDCONST_ONEMETRE
		);
	}
	states{
	Safety:
		---- A 0 {A_StartSound("weapons/fmswitch",CHAN_WEAPON,CHANF_OVERLAP,0.4);
		if(invoker.weaponstatus[TBF_SAFETY]==1)invoker.weaponstatus[TBF_SAFETY]=0;
		else invoker.weaponstatus[TBF_SAFETY]=1;}
		Goto Nope;
	ready:
		---- A 0 A_JumpIf(pressinguse()&&pressingfiremode(),"Safety");
		PLSG A 1{
			A_CheckIdSprite("THBGA0","PLSGA0");
			invoker.weaponstatus[TBS_WARMUP]=0;

			//update rangefinder
			if(
				invoker.weaponstatus[TBS_BATTERY]>0
				&&!(level.time&(1|2|4))
				&&max(abs(vel.x),abs(vel.y),abs(vel.z))<2
				&&(
					!player.cmd.pitch
					&&!player.cmd.yaw
				)
			){
				vector3 gunpos=gunpos();
				flinetracedata frt;
				linetrace(
					angle,
					512*HDCONST_ONEMETRE,
					pitch,
					flags:TRF_NOSKY|TRF_ABSOFFSET,
					offsetz:gunpos.z,
					offsetforward:gunpos.x,
					offsetside:gunpos.y,
					data:frt
				);
				if(
					frt.hittype==Trace_HitNone
					||(
						frt.hittype==Trace_HitCeiling
						&&frt.hitsector.gettexture(1)==skyflatnum
					)||(
						frt.hittype==Trace_HitFloor
						&&frt.hitsector.gettexture(0)==skyflatnum
					)||(
						!!frt.hitline
						&&frt.hitline.special==Line_Horizon
					)
				)invoker.rangefinder=999;
				else invoker.rangefinder=int(frt.distance*(1./HDCONST_ONEMETRE));
			}
			A_WeaponReady(WRF_ALL&~WRF_ALLOWUSER1);
		}goto readyend;
		PLSG AB 0;
		PLSF AB 0;
		THBG AB 0;
		THBF AB 0;
	fire:
		---- A 0 A_JumpIf(invoker.weaponstatus[TBF_SAFETY]==1,"Nope");
		#### A 3 offset(0,35);
	hold:
		#### A 0 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>0,"shoot");
		goto nope;
	shoot:
		#### A 1 offset(1,33) A_ThunderZap();
		#### A 1 offset(0,34) A_WeaponReady(WRF_NONE);
		#### A 1 offset(-1,33) A_WeaponReady(WRF_NONE);
		#### A 0{
			if(invoker.weaponstatus[TBS_BATTERY]<1){
				A_StartSound("weapons/plasmas",CHAN_WEAPON);
				A_GunFlash();
				setweaponstate("nope");
			}else{
				A_Refire();
			}
		}
		#### AAA 4{
			A_WeaponReady(WRF_NOFIRE);
			A_GunFlash();
		}goto ready;
	flash:
		THBF AB 0;
		#### A 0 A_CheckIdSprite("THBFA0","PLSFA0",PSP_FLASH);
		#### A 1 bright{
			HDFlashAlpha(64);
			A_Light2();
		}
		#### BA 1 bright;
		#### B 1 bright A_Light1();
		#### AB 1 bright;
		#### B 0 bright A_Light0();
		stop;
	altfire:
	firemode:
		PLSR A 1 offset(1,2) A_WeaponBusy();
		#### B 2 offset(2,2);
		#### C 1 offset(1,3) A_StartSound("weapons/plasswitch",8);
		#### C 2 offset(0,4);
		#### C 3 offset(-1,5);
		#### C 4 offset(-1,6);
		#### B 3 offset(-1,5);
		#### B 2 offset(0,4){
			invoker.weaponstatus[0]^=TBF_ALT;
			A_SetHelpText();
		}
		#### A 1;
		PLSG A 1 offset(0,4);
		#### A 1 offset(1,3);
		goto nope;

	select0:
		PLSG A 0{
			invoker.weaponstatus[TBS_MAXRANGEDISPLAY]=int(
				(8000+200*invoker.weaponstatus[TBS_BATTERY])/HDCONST_ONEMETRE
			);
			A_CheckIdSprite("THBGA0","PLSGA0");
		}goto select0big;
	deselect0:
		PLSG A 0 A_CheckIdSprite("THBGA0","PLSGA0");
		#### A 0 A_Light0();
		goto deselect0big;

	unload:
		#### A 0{
			invoker.weaponstatus[0]|=TBF_JUSTUNLOAD;
			if(invoker.weaponstatus[TBS_BATTERY]>=0)
				return resolvestate("unmag");
			return resolvestate("nope");
		}goto magout;
	unmag:
		PLSR A 2 offset(0,0){
			A_SetCrosshair(21);
			A_MuzzleClimb(frandom(-1.2,-2.4),frandom(1.2,2.4));
		}
		#### B 3 offset(0,0);
		#### C 1 Offset(-10,-20);
		PLSR D 1 offset(36,60);
		PLSR D 1 offset(30,60);
		PLSR D 1 offset(25,50);
		PLSR D 1 offset(20,40);
		PLSR D 1 offset(16,30);
		PLSR D 1 offset(10,20);
		PLSR D 1 offset(6,10);
		PLSR D 0 offset(0,0);
		#### A 0{
			int bat=invoker.weaponstatus[TBS_BATTERY];
			A_MuzzleClimb(frandom(-1.2,-2.4),frandom(1.2,2.4));
			if(
				(
					bat<0
				)||(
					!PressingUnload()&&!PressingReload()
				)
			)return resolvestate("dropmag");
			return resolvestate("pocketmag");
		}

	dropmag:
		PLSR D 3 Offset(0,0) A_StartSound("weapons/plasopen",8);
		PLSR D 2 Offset(2,16);
		PLSR D 5 Offset(6,30){
			int bat=invoker.weaponstatus[TBS_BATTERY];
			invoker.weaponstatus[TBS_BATTERY]=-1;
			if(bat>=0){
				HDMagAmmo.SpawnMag(self,"HDBattery",bat);
			}}
		PLSR D 2 Offset(10,27) A_StartSound("weapons/plasload",8,CHANF_OVERLAP);	
		PLSR D 2 Offset(5,23);
		PLSR D 1 Offset(1,16);
		PLSR D 1 Offset(0,0);
		goto magout;

	HandTakingBat:
		RVHA F 1 A_OverLayOffset(-26, -30, 50);
		RVHA F 1 A_OverLayOffset(-26, -36, 45);
		RVHA F 1 A_OverLayOffset(-26, -44, 40);
		RVHA F 1 A_OverLayOffset(-26, -56, 50);
		RVHA F 1 A_OverLayOffset(-26, -64, 45);
		RVHA F 1 A_OverLayOffset(-26, -70, 40);
		RVHA G 2 A_OverLayOffset(-26, -70, 35);
		PLSR E 2 A_OverLayOffset(-26, -38, 30);
		PLSR E 2 A_OverLayOffset(-26, -30, 32);
		PLSR E 1 A_OverLayOffset(-26, -23, 29);
		PLSR E 2 A_OverLayOffset(-26, -15, 32);
		PLSR E 2 A_OverLayOffset(-26, -4, 38);
		PLSR E 2 A_OverLayOffset(-26, 4, 46);
		PLSR E 2 A_OverLayOffset(-26, 11, 54);
		PLSR E 2 A_OverLayOffset(-26, 18, 62);
		Stop;
	pocketmag:
		---- A 0 A_OverLay(-26,"HandTakingBat");
		PLSR D 9;
		PLSR D 1 Offset(1,2) A_StartSound("weapons/plasopen",8);
		PLSR D 2 Offset(3,4);
		---- A 0{
			int bat=invoker.weaponstatus[TBS_BATTERY];
			invoker.weaponstatus[TBS_BATTERY]=-1;
			if(bat>=0){
				HDMagAmmo.GiveMag(self,"HDBattery",bat);
			}
		}
		PLSR D 1 Offset(5,5) A_StartSound("weapons/plasload",8);
		PLSR D 4 Offset(4,4);
		#### D 8 offset(1,1) A_StartSound("weapons/pocket",9);
		#### D 8 offset(0,0) A_StartSound("weapons/pocket",9,CHANF_OVERLAP);
		goto magout;

	magout:
		---- A 0 A_JumpIf(invoker.weaponstatus[0]&TBF_JUSTUNLOAD,"reload3");
		goto loadmag;

	reload:
		#### A 0{
			if(PressingZoom())SetWeaponState("CheckMag");
			else
			{
			invoker.weaponstatus[0]&=~TBF_JUSTUNLOAD;
			if(
				invoker.weaponstatus[TBS_BATTERY]<20
				&&countinv("HDBattery")
			)setweaponstate("unmag");
			}
		}goto nope;

	HandLoad:
		PLSR E 2 A_OverLayOffset(-26, 20, 62);
		PLSR E 2 A_OverLayOffset(-26, 14, 54);
		PLSR E 2 A_OverLayOffset(-26, 9, 46);
		PLSR E 2 A_OverLayOffset(-26, 1, 38);
		PLSR E 2 A_OverLayOffset(-26, -10, 32);
		PLSR E 2 A_OverLayOffset(-26, -20, 30);
		PLSR E 2 A_OverLayOffset(-26, -31, 29);
		PLSR E 2 A_OverLayOffset(-26, -34, 30);
		PLSR E 2 A_OverLayOffset(-26, -38, 29);
		RVHA G 2 A_OverLayOffset(-26, -70, 35);
		RVHA G 2 A_OverLayOffset(-26, -65, 40);
		RVHA G 2 A_OverLayOffset(-26, -57, 47);
		RVHA G 2 A_OverLayOffset(-26, -47, 54);
		RVHA G 2 A_OverLayOffset(-26, -39, 60);
		Stop;
	loadmag:
		PLSR D 2 offset(0,3){
			A_StartSound("weapons/pocket",9);
			if(health>39)A_SetTics(0);
		}
		#### DD 2 offset(0,2);
		#### D 2 offset(0,4) A_StartSound("weapons/pocket",9);
		#### A 0 A_OverLay(-26,"HandLoad");
		#### D 4 offset(0,3);
		#### D 6 offset(0,2);
		#### D 8 offset(0,3)A_StartSound("weapons/plasload",8);
		#### D 4 offset(0,4){if(health>39)A_SetTics(0);}
		#### D 4 offset(5,10)A_StartSound("weapons/plasclose",8);

		#### A 0{
			let mmm=HDMagAmmo(findinventory("HDBattery"));
			if(mmm)invoker.weaponstatus[TBS_BATTERY]=mmm.TakeMag(true);
		}goto reload3;

	reload3:
		PLSR D 1 offset(0,20){
			invoker.weaponstatus[TBS_MAXRANGEDISPLAY]=int(
				(8000+200*invoker.weaponstatus[TBS_BATTERY])/HDCONST_ONEMETRE
			);
			A_StartSound("weapons/plasclose2",8);
		}
		PLSR D 1 offset(10,30);
		PLSR D 1 offset(20,40);
		PLSR D 1 offset(28,50);
		PLSR D 1 offset(30,60);
		PLSR D 1 offset(36,70);
		#### C 2 Offset(-10,-20);
		#### C 1 Offset(-5,-10);
		#### B 2 offset(0,0);
		#### A 4 offset(0,0);
		goto nope;
	
	CheckMag:
		PLSR A 1 offset(1,2) A_WeaponBusy();
		#### B 2 offset(2,2);
		#### C 1 offset(1,3);// A_StartSound("weapons/plasswitch",8);
		#### C 1 offset(0,4);
		#### C 2 offset(-1,5);
	CheckMagLoop:
		#### C 3 offset(-1,6)A_JumpIf(!PressingReload(), 2);
		---- B 0 {if(invoker.weaponstatus[TBS_BATTERY]>0)A_Overlay(102, "Dumb");}
		Loop;
		#### B 2 offset(-1,5);
		#### B 1 offset(0,4);
		#### A 1;
		PLSG A 1 offset(0,4);
		#### A 1 offset(1,3);
		goto nope;
	
	Dumb:
		STUP A 0 A_OverLayOffset(102,29,24);
		STUP A 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>1,1);
		Stop;
		STUP B 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>3,1);
		Stop;
		STUP C 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>4,1);
		Stop;
		STUP D 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>6,1);
		Stop;
		STUP E 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>7,1);
		Stop;
		STUP F 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>9,1);
		Stop;
		STUP G 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>10,1);
		Stop;
		STUP H 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>12,1);
		Stop;
		STUP I 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>14,1);
		Stop;
		STUP J 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>15,1);
		Stop;
		STUP K 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>16,1);
		Stop;
		STUP L 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>17,1);
		Stop;
		STUP M 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>18,1);
		Stop;
		STUP N 5 A_JumpIf(invoker.weaponstatus[TBS_BATTERY]>19,1);
		Stop;
		STUP O 5;
		Stop;	

	user3:
		#### A 0 A_MagManager("HDBattery");
		goto ready;

	spawn:
		PLAS A -1;
		stop;
	}
	override void initializewepstats(bool idfa){
		weaponstatus[TBS_BATTERY]=20;
	}
	override void loadoutconfigure(string input){
		int fm=getloadoutvar(input,"alt",1);
		if(!fm)weaponstatus[0]&=~TBF_ALT;
		else if(fm>0)weaponstatus[0]|=TBF_ALT;
	}
}
enum tbstatus{
	TBF_ALT=1,
	TBF_JUSTUNLOAD=2,
	TBF_SAFETY=6,
	TBS_FLAGS=0,
	TBS_BATTERY=1,
	TBS_WARMUP=2,
	TBS_HEAT=3,
	TBS_MAXRANGEDISPLAY=4,

	TB_BEAMSPOTTID=666123
};


class BeamSpot:HDActor{
	default{
		+nointeraction //+noblockmap
		+forcexybillboard
		height 0.1;radius 0.1;
		renderstyle "add";
	}
	override void postbeginplay(){
		super.postbeginplay();
		changetid(TB_BEAMSPOTTID);
	}
	void A_Flicker(){
		alpha=frandom(0.1,1.);
		double amt=frandom(0.6,1.3);
		scale=(randompick(1,-1),1.)*amt;
		if(!random(0,7))HDMobAI.Frighten(self,256);
	}
	void A_BeamSpotBoom(){
		if(!target){ //how would this even happen?
			spawn("HDExplosion",pos,ALLOW_REPLACE);
			A_Explode();
			return;
		}
		double tgtdist=distance3d(target)-64;

		//arc lightning back to owner
		vector2 oldface=(angle,pitch);
		A_FaceTarget(0,0,FAF_TOP);
		target.A_CustomRailgun(
			random(120,240),0,"","azure",
			RGF_SILENT|RGF_NOPIERCING|RGF_FULLBRIGHT,
			0,40.0,"HDArcPuff",0,0,
			tgtdist,12,0.4,2.0,"",-4
		);
		angle=oldface.x;pitch=oldface.y;
		//spawn little cracks along the way
		vector3 toshooter=vec3to(target).unit();
		for(int i=0;i<tgtdist;i+=64){
			let aaa=spawn("ThunderCracker",pos+toshooter*i,ALLOW_REPLACE);
			if(aaa)aaa.target=target;
		}

		//crackity crack
		target.A_StartSound("weapons/plascrack",11);
		target.A_StartSound("weapons/plascrack",12);
		target.A_StartSound("weapons/plascrack",13);
		target.A_StartSound("world/tbfar",14);
		target.A_StartSound("world/explode",15,volume:0.5);

		//flash player's muzzle
		let hdp=hdplayerpawn(target);
		if(
			hdp
			&&hdp.player
		){
			let tbt=thunderbuster(target.player.readyweapon);
			if(tbt){
				hdp.recoilfov*=0.7;
				hdp.A_MuzzleClimb(
					(frandom(1.2,1.8),-frandom(4.0,5.4)),
					(frandom(0.8,1.2),-frandom(3.4,4.2)),
					(frandom(0.4,0.8),-frandom(2.4,2.4)),
					(-frandom(0.4,1.0),frandom(2.8,2.8))
				);
				hdp.player.setpsprite(PSP_FLASH,tbt.findstate("flash"));
				hdp.A_ChangeVelocity(
					cos(pitch)*-frandom(1,3),0,
					sin(pitch)*frandom(1,3),
					CVF_RELATIVE
				);
				tbt.weaponstatus[TBS_HEAT]+=70;
				tbt.weaponstatus[TBS_WARMUP]=0;
			}
		}

		//blast heat and shit		
		A_HDBlast(
			420,random(96,256),128,"slashing",
			pushradius:420,pushamount:256,
			immolateradius:128,immolateamount:-200,immolatechance:90
		);
		actor ltt=spawn("LingeringThunder",pos,ALLOW_REPLACE);
		ltt.target=target;

		A_SprayDecal("BusterScorch",14);
		DistantNoise.Make(self,"world/tbfar");
		DistantNoise.Make(self,"world/tbfar2",2.);
		DistantQuaker.Quake(self,
			5,50,2048,8,128,256,256
		);

		//check floor and ceiling and spawn more debris
		DistantNoise.Make(self,"world/tbfar");
		for(int i=0;i<3;i++)A_SpawnItemEx("WallChunker",
			frandom(-4,4),frandom(-4,4),-4,
			flags:SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);

		//"open" a door or window
		doordestroyer.destroydoor(self,frandom(1,frandom(32,96)),frandom(1,frandom(16,64)));
	}
	void A_CheckNeighbourSpots(){
		array<actor>beamspots;beamspots.clear();
		actoriterator it=level.createactoriterator(TB_BEAMSPOTTID,"BeamSpot");
		while(master=it.Next()){
			if(!BeamSpot(master))continue;
			double dist=master.distance3d(self)*0.01;
			if(dist<8){
				stamina+=int(21-dist);
				if(master!=self)beamspots.push(master);
				if(master.stamina>21)master.setstatelabel("glow");
				else master.setstatelabel("spawn2");
			}
		}
		if(stamina>=144){
			for(int i=0;i<beamspots.size();i++){
				if(beamspots[i])beamspots[i].destroy();
			}
			setstatelabel("explode");
		}
		else if(stamina>=21)setstatelabel("glow");
	}
	states{
	spawn:
		TNT1 A 0 nodelay A_CheckNeighbourSpots();
	spawn2:
		TNT1 A 3 A_StartSound("weapons/plasidle",CHAN_WEAPON,volume:0.4);
		stop;
	glow:
		PLSE A 0 A_SpawnItemEx("BeamSpotLight",flags:SXF_NOCHECKPOSITION|SXF_SETTARGET);
		PLSE A 0 A_SprayDecal("PlasmaShock",14);
		PLSE A 1 A_StartSound("weapons/plasidle",CHAN_WEAPON,volume:0.8);
		PLSE AAAA 1 A_Flicker();
		stop;
	explode:
		TNT1 A 0 A_BeamSpotBoom();
		TNT1 AAAA 0 Spawn("HDExplosion",pos+(frandom(-4,4),frandom(-4,4),frandom(-4,4)),ALLOW_REPLACE);
		TNT1 AAAA 0 Spawn("HDSmoke",pos+(frandom(-4,4),frandom(-4,4),frandom(-4,4)),ALLOW_REPLACE);
		TNT1 AAAAAAAA 0 ArcZap(self);
		TNT1 AAAAAAAAAAAAAAA 2 ArcZap(self);
		stop;
	}
}
class BeamSpotLight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=128;
		args[1]=96;
		args[2]=224;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!target){
			args[3]+=randompick(-10,10,-5,-20);
			if(args[3]<1)destroy();
		}else{
			args[3]=randompick(14,24,44);
			setorigin(target.pos,true);
		}
	}
}
class ThunderCracker:IdleDummy{
	states{
	spawn:
		TNT1 A 1;
		TNT1 A 10 A_StartSound("weapons/plascrack");
		TNT1 A 20 A_AlertMonsters();
		stop;
	}
}


//alt fire puff
class BeamSpotFlash:IdleDummy{
	default{
		+puffonactors +hittracer +puffgetsowner +rollsprite +rollcenter +forcexybillboard
		renderstyle "add";
		obituary "%o was hammered by %k's particle splatter.";
		decal "Scorch";
		seesound "weapons/plasmaf";
		deathsound "weapons/plasmaf";
	}
	double impactdistance;
	override void postbeginplay(){
		if(impactdistance>2000){
			destroy();
			return;
		}
		super.postbeginplay();

		double impactcloseness=2000-impactdistance;
		scale*=(impactcloseness)*0.0006;
		alpha=scale.y+0.3;
		vel=(frandom(-1,1),frandom(-1,1),frandom(1,3));

		int n=int(max(impactcloseness*0.03,2));
		int n1=n*3/5;
		int n2=n*2/5;
		if(tracer){
			HDF.Give(tracer,"Heat",n);
			int dmgflags=target&&target.player?DMG_PLAYERATTACK:0;
			tracer.damagemobj(self,target,random(n1,n),"electrical",dmgflags);
		}
		A_HDBlast(
			n*2,random(1,n),n,"electrical",
			n,-n,
			immolateradius:n1,immolateamount:random(4,8)*n2/-10,immolatechance:n
		);

		pitch=frandom(80,90);
		angle=frandom(0,360);
		A_SpawnItemEx("BeamSpotFlashLight",flags:SXF_NOCHECKPOSITION|SXF_SETTARGET);
		A_SpawnChunks("HDGunSmoke",clamp(n2*3/5,4,7),3,6);
		A_StartSound("weapons/plasmaf");
		A_AlertMonsters();
	}
	states{
	spawn:
		PLSS AB 1 bright;
		PLSE AAA 1 bright A_FadeIn(0.1);
		PLSE BCDE 1 bright A_FadeOut(0.1);
		stop;
	}
}

class BeamSpotFlashLight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=128;
		args[1]=96;
		args[2]=224;
		args[3]=96;
		args[4]=0;
	}
	override void tick(){
		if(isfrozen())return;
		args[3]+=randompick(-10,5,-20);
		if(args[3]<1)destroy();
	}
}


//Ionized is the ground because of you
class LingeringThunder:IdleDummy{
	int startingstamina;
	default{
		stamina 256;
	}
	override void postbeginplay(){
		super.postbeginplay();
		startingstamina=stamina;
	}
	void A_Zap(){
		if(stamina<1){destroy();return;}
		stamina-=5;
		blockthingsiterator zit=blockthingsiterator.create(self,96+(stamina>>2));
		int icount=0;
		bool haszapped=false;
		while(zit.next()){
			actor zt=zit.thing;
			if(
				!zt
				||(!zt.bshootable&&!zt.bsolid)
				||abs(zt.pos.z-pos.z)>96
				||zt.floorz+(stamina>>2)<zt.pos.z
				||!random(0,3)
				||!checksight(zt)
			)continue;
			haszapped=true;
			int zappower=Zap(zt,self,target,stamina);
			stamina-=max(2,zappower>>3);
		}
		if(!haszapped){
			double oldrad=radius;
			a_setsize(stamina,height);
			Zap(self,self,target,stamina,true);
			a_setsize(oldrad,height);
		}
		A_SetTics(max(1,min(random(4,24),int(sqrt(startingstamina-stamina)))));
	}
	static int Zap(actor victim,actor inflictor,actor source,int baseamount,bool nodmg=false){
		//create arc
		double ztr=victim.radius;
		vector3 nodes[4];
		int len=min(35,baseamount);
		nodes[0]=victim.pos+(frandom(-ztr,ztr),frandom(-ztr,ztr),frandom(0,victim.height));
		nodes[1]=nodes[0]+(frandom(-len,len),frandom(-len,len),frandom(-len,len));
		nodes[2]=nodes[1]+(frandom(-len,len),frandom(-len,len),frandom(-(len>>1),len));
		nodes[3]=nodes[2]+(frandom(-len,len),frandom(-len,len),frandom(-len*2/3,(len>>1)));
		for(int i=1;i<4;i++){
			vector3 pastnode=nodes[i-1];
			vector3 particlepos=nodes[i]-pastnode;
			int iterations=int(particlepos.length());
			vector3 particlemove=particlepos/iterations;
			particlepos=pastnode-victim.pos;
			for(int i=0;i<iterations;i++){
				victim.A_SpawnParticle("white",
					SPF_RELATIVE|SPF_FULLBRIGHT,(len>>1),frandom(1,7),0,
					particlepos.x,particlepos.y,particlepos.z,
					frandom(-0.1,0.1),frandom(-0.1,0.1),frandom(0.1,0.2),
					frandom(-0.1,0.1),frandom(-0.1,0.1),-0.05
				);
				particlepos+=particlemove+(frandom(-1,1),frandom(-1,1),frandom(-1,1));
			}
		}

		int zappower=random(baseamount>>5,baseamount>>2);
		victim.A_StartSound("weapons/plasidle",CHAN_AUTO,volume:frandom(0.2,0.6));
		victim.A_StartSound("misc/arccrackle",CHAN_AUTO);
		victim.A_StartSound("weapons/plascrack",CHAN_AUTO,volume:frandom(0.2,0.6));
		actor bsfl=spawn("BeamSpotFlashLight",victim.pos,ALLOW_REPLACE);
		bsfl.target=victim;

		//make bodies spasm
		if(
			victim.bcorpse
			&&victim.bshootable
			&&victim.mass
			&&!!victim.findstate("dead")
		){
			victim.vel.z+=3.*zappower/victim.mass;
		}

		if(!nodmg){
			victim.damagemobj(inflictor,source,zappower,"electrical",source&&source.player?DMG_PLAYERATTACK:0);
			if(hdmobbase(victim))hdmobbase(victim).stunned+=(zappower>>3);
		}
		return zappower;
	}
	states{
	spawn:
		TNT1 A 1 A_Zap();
		wait;
	}
}




