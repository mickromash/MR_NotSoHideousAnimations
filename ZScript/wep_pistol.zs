// ------------------------------------------------------------
// Pistol
// ------------------------------------------------------------
class HDHandgunRandomDrop:RandomSpawner{
	default{
		dropitem "HDPistol",16,5;
		dropitem "HDRevolver",16,1;
	}
}
class HDHandgun:HDWeapon{
	bool wronghand;
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	action void A_SwapHandguns(){
		let mwt=SpareWeapons(findinventory("SpareWeapons"));
		if(!mwt){
			setweaponstate("whyareyousmiling");
			return;
		}
		int pistindex=mwt.weapontype.find(invoker.getclassname());
		if(pistindex==mwt.weapontype.size()){
			setweaponstate("whyareyousmiling");
			return;
		}
		A_WeaponBusy();

		array<string> wepstat;
		string wepstat2="";
		mwt.weaponstatus[pistindex].split(wepstat,",");
		for(int i=0;i<wepstat.size();i++){
			if(i)wepstat2=wepstat2..",";
			wepstat2=wepstat2..invoker.weaponstatus[i];
			invoker.weaponstatus[i]=wepstat[i].toint();
		}
		mwt.weaponstatus[pistindex]=wepstat2;

		invoker.wronghand=!invoker.wronghand;
	}
}
class HDPistol:HDHandgun replaces Pistol{
	string LogMag;
	default{
		+hdweapon.fitsinbackpack
		+hdweapon.reverseguninertia
		scale 0.63;
		weapon.selectionorder 50;
		weapon.slotnumber 2;
		weapon.slotpriority 2;
		weapon.kickback 30;
		weapon.bobrangex 0.1;
		weapon.bobrangey 0.6;
		weapon.bobspeed 2.5;
		weapon.bobstyle "normal";
		obituary "%o got capped by %k's pea shooter.";
		inventory.pickupmessage "You got the pistol!";
		tag "$TAG_PISTOL";
		hdweapon.refid HDLD_PISTOL;
		hdweapon.barrelsize 19,0.3,0.5;

		hdweapon.loadoutcodes "
			\cuselectfire - 0/1, whether it has a fire selector
			\cufiremode - 0/1, semi/auto, subject to the above";
	}
	override double weaponbulk(){
		int mgg=weaponstatus[PISS_MAG];
		return 30+(mgg<0?0:(ENC_9MAG_LOADED+mgg*ENC_9_LOADED));
	}
	override double gunmass(){
		int mgg=weaponstatus[PISS_MAG];
		return 3.5+(mgg<0?0:0.08*(mgg+1));
	}
	override void failedpickupunload(){
		failedpickupunloadmag(PISS_MAG,"HD9mMag15");
	}
	override string,double getpickupsprite(bool usespare){
		string spr;
		int wep0=GetSpareWeaponValue(0,usespare);
		if(GetSpareWeaponValue(PISS_CHAMBER,usespare)<1){
			if(wep0&PISF_SELECTFIRE)spr="D";
			else spr="B";
		}else{
			if(wep0&PISF_SELECTFIRE)spr="C";
			else spr="A";
		}
		return "PIST"..spr.."0",1.;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			int nextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD9mMag15")));
			if(nextmagloaded>=15){
				sb.drawimage("CLP2NORM",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1,1));
			}else if(nextmagloaded<1){
				sb.drawimage("CLP2EMPTY",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,alpha:nextmagloaded?0.6:1.,scale:(1,1));
			}else sb.drawbar(
				"CLP2NORM","CLP2GREY",
				nextmagloaded,15,
				(-46,-3),-1,
				sb.SHADER_VERT,sb.DI_SCREEN_CENTER_BOTTOM
			);
			sb.drawnum(hpl.countinv("HD9mMag15"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			}
		if(hdw.weaponstatus[PISF_SAFETY]==1)sb.drawimage("SAFETY",(-17,-12),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1,1));	
		if(hdw.weaponstatus[0]&PISF_SELECTFIRE)sb.drawwepcounter(hdw.weaponstatus[0]&PISF_FIREMODE,
			-22,-10,"RBRSA3A7","STFULAUT"
		);
		sb.drawwepnum(hdw.weaponstatus[PISS_MAG],15);
		if(hdw.weaponstatus[PISS_CHAMBER]==2)sb.drawrect(-19,-11,3,1);
	}
	override string gethelptext(){
		return
		WEPHELP_USE.."+"..WEPHELP_FIREMODE.."  Safety\n"
		..WEPHELP_FIRESHOOT
		..((weaponstatus[0]&PISF_SELECTFIRE)?(WEPHELP_FIREMODE.."  Semi/Auto\n"):"")
		..WEPHELP_ALTRELOAD.."  Quick-Swap (if available)\n"
		..WEPHELP_RELOAD.."  Reload mag\n"
		..WEPHELP_USE.."+"..WEPHELP_RELOAD.."  Reload chamber\n"
		..WEPHELP_ZOOM.."+"..WEPHELP_RELOAD.."  Check Mag\n"
		..WEPHELP_MAGMANAGER
		..WEPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		vector2 scc;
		vector2 bobb=bob*1.3;

		//if slide is pushed back, throw sights off line
		if(hpl.player.getpsprite(PSP_WEAPON).frame==1){
			sb.SetClipRect(
				-8+bob.x,-9+bob.y,16,15,
				sb.DI_SCREEN_CENTER
			);
			bobb.y-=1;
			scc=(0.6,0.6);
		}
		else if(hpl.player.getpsprite(PSP_WEAPON).frame>=2){
			sb.SetClipRect(
				-10+bob.x,-10+bob.y,20,19,
				sb.DI_SCREEN_CENTER
			);
			bobb.y-=2;
			scc=(0.7,0.8);
		}else{
			sb.SetClipRect(
				-8+bob.x,-9+bob.y,16,15,
				sb.DI_SCREEN_CENTER
			);
			scc=(0.6,0.6);
		}
		sb.drawimage(
			"frntsite",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			scale:scc
		);
		sb.SetClipRect(cx,cy,cw,ch);
		sb.drawimage(
			"backsite",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9,
			scale:scc
		);
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("HDPistolAmmo"))owner.A_DropInventory("HDPistolAmmo",amt*15);
			else owner.A_DropInventory("HD9mMag15",amt);
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("HDPistolAmmo");
		ForceOneBasicAmmo("HD9mMag15");
	}
	action void A_CheckPistolHand(){
		if(invoker.wronghand)player.getpsprite(PSP_WEAPON).sprite=getspriteindex("PI2GA0");
	}
	states{
	select0:
		PISG A 0{
			if(!countinv("NulledWeapon"))invoker.wronghand=false;
			A_TakeInventory("NulledWeapon");
			A_CheckPistolHand();
		}
		#### A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		#### C 0;
		---- A 1 A_Raise();
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(24);
		---- A 1 A_Raise(18);
		wait;
	deselect0:
		PISG A 0 A_CheckPistolHand();
		#### A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		#### C 0;
		---- AAA 1 A_Lower();
		---- A 1 A_Lower(18);
		---- A 1 A_Lower(24);
		---- A 1 A_Lower(30);
		wait;

	ready:
		PISG A 0 A_CheckPistolHand();
		#### A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		#### C 0;
		#### # 0 A_SetCrosshair(21);
		#### # 1 A_WeaponReady(WRF_ALL);
		goto readyend;
	user3:
		---- A 0 A_MagManager("HD9mMag15");
		goto ready;
	user2:
	firemode:
		---- A 0{if(pressinguse()){if(invoker.weaponstatus[PISF_SAFETY]==1){invoker.weaponstatus[PISF_SAFETY]=0;setweaponstate("Nope");} else {invoker.weaponstatus[PISF_SAFETY]=1;setweaponstate("Nope");}}}
		---- A 0{
			if(invoker.weaponstatus[0]&PISF_SELECTFIRE)
			invoker.weaponstatus[0]^=PISF_FIREMODE;
			else invoker.weaponstatus[0]&=~PISF_FIREMODE;
		}goto nope;
	altfire:
		---- A 0{
			invoker.weaponstatus[0]&=~PISF_JUSTUNLOAD;
			if(
				invoker.weaponstatus[PISS_CHAMBER]!=2
				&&invoker.weaponstatus[PISS_MAG]>0
			)setweaponstate("chamber_manual");
		}goto nope;
	HandChamber:
		RVHA C 1 A_OverLayOffset(26, -10, 40);
		RVHA C 1 A_OverLayOffset(26, -20, 30);
		RVHA C 1 A_OverLayOffset(26, -30, 20);
		RVHA C 1 A_OverLayOffset(26, -40, 10);
		RVHA E 1 A_OverLayOffset(26, -17, 0);
		RVHA E 1 A_OverLayOffset(26, -17, 1);
		RVHA E 1 A_OverLayOffset(26, -17, 2);
		RVHA E 1 A_OverLayOffset(26, -17, 6);
		RVHA E 1 A_OverLayOffset(26, -17, 9);
		RVHA E 1 A_OverLayOffset(26, -17, 13);
		RVHA E 1 A_OverLayOffset(26, -17, 12);
		RVHA E 1 A_OverLayOffset(26, -17, 11);
		RVHA C 1 A_OverLayOffset(26, -39, 10);
		RVHA C 1 A_OverLayOffset(26, -35, 14);
		RVHA C 1 A_OverLayOffset(26, -27, 20);
		RVHA C 1 A_OverLayOffset(26, -20, 36);
		RVHA C 1 A_OverLayOffset(26, -12, 48);
		Stop;	
	HandChamberRight:
		RVHB C 1 A_OverLayOffset(26, -10, 20);
		RVHB C 1 A_OverLayOffset(26, 0, 10);
		RVHB C 1 A_OverLayOffset(26, 10, 0);
		RVHB C 1 A_OverLayOffset(26, 20, -10);
		RVHB E 1 A_OverLayOffset(26, -17, 0);
		RVHB E 1 A_OverLayOffset(26, -17, 1);
		RVHB E 1 A_OverLayOffset(26, -17, 2);
		RVHB E 1 A_OverLayOffset(26, -17, 6);
		RVHB E 1 A_OverLayOffset(26, -17, 9);
		RVHB E 1 A_OverLayOffset(26, -17, 13);
		RVHB E 1 A_OverLayOffset(26, -17, 12);
		RVHB E 1 A_OverLayOffset(26, -17, 11);
		RVHB C 1 A_OverLayOffset(26, 20, -10);
		RVHB C 1 A_OverLayOffset(26, 10, 4);
		RVHB C 1 A_OverLayOffset(26, 0, 10);
		RVHB C 1 A_OverLayOffset(26, -10, 26);
		RVHB C 1 A_OverLayOffset(26, -20, 38);
		Stop;		
	chamber_manualUnload:
		---- A 0 A_JumpIf(
			!(invoker.weaponstatus[0]&PISF_JUSTUNLOAD)
			&&(
				invoker.weaponstatus[PISS_CHAMBER]==2
				||invoker.weaponstatus[PISS_MAG]<1
			)
			,"nope"
		);
		#### A 0 {if(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PI2GA0"))A_OverLay(26,"HandChamberRight");Else A_OverLay(26,"HandChamber");}
		#### B 4 offset(0,30);
		#### H 2 offset(0,30);
		#### H 2 offset(0,32);
		#### I 2 offset(0,34){
			A_MuzzleClimb(frandom(0.4,0.5),-frandom(0.6,0.8));
			A_StartSound("weapons/pischamber2",8);
			int psch=invoker.weaponstatus[PISS_CHAMBER];
			invoker.weaponstatus[PISS_CHAMBER]=0;
			if(psch==2){
				A_EjectCasing("HDPistolAmmo",
					frandom(-1,2),
					(-frandom(2,3),frandom(0,0.2),frandom(0.4,0.5)),
					(-2,0,-1)
				);
			}else if(psch==1){
				A_EjectCasing("HDSpent9mm",
					-frandom(-1,2),
					(frandom(0.4,0.7),-frandom(6,7),frandom(0.8,1)),
					(-2,0,-1)
				);
			}
			if(invoker.weaponstatus[PISS_MAG]>0){
				invoker.weaponstatus[PISS_CHAMBER]=2;
				invoker.weaponstatus[PISS_MAG]--;
			}
		}
		#### H 3 offset(0,36);
		#### B 3 offset(0,30);
		goto nope;	
	chamber_manual:
		---- A 0 A_JumpIf(invoker.weaponstatus[PISF_SAFETY]==1,"Nope");
		---- A 0 A_JumpIf(!(invoker.weaponstatus[0]&PISF_JUSTUNLOAD)
			&&(
				invoker.weaponstatus[PISS_CHAMBER]==2
				||invoker.weaponstatus[PISS_MAG]<1
			)
			,"nope"
		);
		#### B 3 offset(0,34);
		#### C 4 offset(0,37){
			A_MuzzleClimb(frandom(0.4,0.5),-frandom(0.6,0.8));
			A_StartSound("weapons/pischamber2",8);
			int psch=invoker.weaponstatus[PISS_CHAMBER];
			invoker.weaponstatus[PISS_CHAMBER]=0;
			if(psch==2){
				A_EjectCasing("HDPistolAmmo",
					frandom(-1,2),
					(-frandom(2,3),frandom(0,0.2),frandom(0.4,0.5)),
					(-2,0,-1)
				);
			}else if(psch==1){
				A_EjectCasing("HDSpent9mm",
					-frandom(-1,2),
					(frandom(0.4,0.7),-frandom(6,7),frandom(0.8,1)),
					(-2,0,-1)
				);
			}
			if(invoker.weaponstatus[PISS_MAG]>0){
				invoker.weaponstatus[PISS_CHAMBER]=2;
				invoker.weaponstatus[PISS_MAG]--;
			}
		}
		#### B 3 offset(0,35);
		goto nope;
	chamber_manualReload:
		---- A 0 A_JumpIf(invoker.weaponstatus[PISF_SAFETY]==1,"Nope");
		#### A 0 A_JumpIf((player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4A0"))||(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3A0")),2);
		PSR1 A 0 A_Jump(256,2);
		PSR3 A 0;
		#### F 3 offset(0,0);
		#### A 0 A_JumpIf((player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4A0"))||(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3A0")),3);
		PSR2 F 4 offset(10,10);
		#### A 0 A_Jump(256,2);
		PSR4 A 4 offset(-10,10);
		#### F 0 offset(10,10){
			A_MuzzleClimb(frandom(0.4,0.5),-frandom(0.6,0.8));
			A_StartSound("weapons/pischamber2",8);
			int psch=invoker.weaponstatus[PISS_CHAMBER];
			invoker.weaponstatus[PISS_CHAMBER]=0;
			if(psch==2){
				A_EjectCasing("HDPistolAmmo",
					frandom(-1,2),
					(-frandom(2,3),frandom(0,0.2),frandom(0.4,0.5)),
					(-2,0,-1)
				);
			}else if(psch==1){
				A_EjectCasing("HDSpent9mm",
					-frandom(-1,2),
					(frandom(0.4,0.7),-frandom(6,7),frandom(0.8,1)),
					(-2,0,-1)
				);
			}
			if(invoker.weaponstatus[PISS_MAG]>0){
				invoker.weaponstatus[PISS_CHAMBER]=2;
				invoker.weaponstatus[PISS_MAG]--;
			}
		}
		#### A 0 A_JumpIf((player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4A0"))||(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3A0")),3);
		#### F 7 offset(5,20);
		#### A 0 A_Jump(256,2);
		PSR4 F 7 Offset(-5,20);
		#### A 0 A_JumpIf((player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4A0"))||(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3A0")),2);
		PSR1 A 0 A_Jump(256,2);
		PSR3 A 0;
		#### RSQ 2 offset(0,0);
		#### A 0 A_JumpIf((player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4A0"))||(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3A0")),2);
		PISG A 0 A_Jump(256,2);
		PI2G A 1 Offset(2,-5);
		#### A 1 offset(-2,-5);
		goto nope;
	althold:
	hold:
		goto nope;
	fire:
		---- A 0{
			invoker.weaponstatus[0]&=~PISF_JUSTUNLOAD;
			if(invoker.weaponstatus[PISF_SAFETY]==1)setweaponstate("nope");
			if(invoker.weaponstatus[PISS_CHAMBER]==2&&invoker.weaponstatus[PISF_SAFETY]==0)setweaponstate("shoot");
			else if(invoker.weaponstatus[PISS_MAG]>0&&invoker.weaponstatus[PISF_SAFETY]==0)setweaponstate("chamber_manual");
		}goto nope;
	shoot:
		#### B 1{
			if(invoker.weaponstatus[PISS_CHAMBER]==2)A_GunFlash();
		}
		#### I 1{
			if(hdplayerpawn(self)){
				hdplayerpawn(self).gunbraced=false;
			}
			A_MuzzleClimb(
				-frandom(0.8,1.),-frandom(1.2,1.6),
				frandom(0.4,0.5),frandom(0.6,0.8)
			);
		}
		#### C 0{
			A_EjectCasing("HDSpent9mm"
				,frandom(-1,2),
				(frandom(0.4,0.7),-frandom(6,7),frandom(0.8,1))
			);
			invoker.weaponstatus[PISS_CHAMBER]=0;
			if(invoker.weaponstatus[PISS_MAG]<1){
				A_StartSound("weapons/pistoldry",8,CHANF_OVERLAP,0.9);
				setweaponstate("nope");
			}
		}
		#### B 1{
			A_WeaponReady(WRF_NOFIRE);
			invoker.weaponstatus[PISS_CHAMBER]=2;
			invoker.weaponstatus[PISS_MAG]--;
			if(
				(invoker.weaponstatus[0]&(PISF_FIREMODE|PISF_SELECTFIRE))
				==(PISF_FIREMODE|PISF_SELECTFIRE)
			){
				IsMoving.Give(self,5);
				A_Refire("fire");
			}else A_Refire();
		}goto ready;
	flash:
		PI2F A 0 A_JumpIf(invoker.wronghand,2);
		PISF A 0;
		---- A 1 bright{
			HDFlashAlpha(64);
			A_Light1();
			let bbb=HDBulletActor.FireBullet(self,"HDB_9",spread:2.,speedfactor:frandom(0.97,1.03));
			if(
				frandom(0,ceilingz-floorz)<bbb.speed*0.3
			)A_AlertMonsters(256);

			invoker.weaponstatus[PISS_CHAMBER]=1;
			A_ZoomRecoil(0.995);
			A_MuzzleClimb(-frandom(0.4,1.2),-frandom(0.4,1.6));
		}
		---- A 0 A_StartSound("weapons/pistol",CHAN_WEAPON);
		---- A 0 A_Light0();
		stop;
	unload:
		---- A 0{
			invoker.weaponstatus[0]|=PISF_JUSTUNLOAD;
			if(invoker.weaponstatus[PISS_MAG]>=0)setweaponstate("unmag");
			else if(invoker.weaponstatus[PISF_SAFETY]==1)setweaponstate("Nope");
		}goto chamber_manualunload;
	HandLoadChamber:
		PSHA A 0;
		#### A 1 A_OverLayOffset(26,7,40);
		#### A 1 A_OverLayOffset(26,-3,30);
		#### A 1 A_OverLayOffset(26,-11,20);
		#### A 1 A_OverLayOffset(26,-18,10);
		#### A 1 A_OverLayOffset(26,-25,0);
		#### A 1 A_OverLayOffset(26,-24,1);
		#### A 1 A_OverLayOffset(26,-25,0);
		#### B 1 A_OverLayOffset(26,-25,0);
		#### B 1 A_OverLayOffset(26,-18,6);
		#### B 1 A_OverLayOffset(26,-11,13);
		#### B 1 A_OverLayOffset(26,-3,20);
		#### B 1 A_OverLayOffset(26,7,27);
		#### B 1 A_OverLayOffset(26,13,39);
		Stop;
	HandLoadChamberRight:
		PSHB A 0;
		#### A 1 A_OverLayOffset(26,-7,40);
		#### A 1 A_OverLayOffset(26,3,30);
		#### A 1 A_OverLayOffset(26,11,20);
		#### A 1 A_OverLayOffset(26,18,10);
		#### A 1 A_OverLayOffset(26,25,0);
		#### A 1 A_OverLayOffset(26,24,1);
		#### A 1 A_OverLayOffset(26,25,0);
		#### B 1 A_OverLayOffset(26,15,0);
		#### B 1 A_OverLayOffset(26,4,6);
		#### B 1 A_OverLayOffset(26,-12,13);
		#### B 1 A_OverLayOffset(26,-20,20);
		#### B 1 A_OverLayOffset(26,-30,27);
		#### B 1 A_OverLayOffset(26,-40,39);
		Stop;	
	loadchamber:
		---- A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,"nope");
		---- A 1 offset(0,20) A_StartSound("weapons/pocket",9);
		---- A 1 offset(2,40);
		---- A 1 offset(2,50);
		---- A 1 offset(3,53);
		---- A 2 offset(5,56);
		---- A 2 offset(7,60);
		#### A 0 {if(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PI2GA0"))A_OverLay(26,"HandLoadChamberRight");Else A_OverLay(26,"HandLoadChamber");}
		#### H 2 offset(10,60);
		#### I 2 offset(8,66);
		#### I 3 offset(6,68){
			if(countinv("HDPistolAmmo")){
				A_TakeInventory("HDPistolAmmo",1,TIF_NOTAKEINFINITE);
				invoker.weaponstatus[PISS_CHAMBER]=2;
				A_StartSound("weapons/pischamber1",8);
			}
		}
		#### H 2 offset(5,66);
		#### B 1 offset(4,54);
		#### B 1 offset(3,46);
		#### B 1 offset(2,38);
		#### B 2 offset(1,28);
		#### B 3 offset(0,14);
		goto readyend;
	reload:
		---- A 0{
			invoker.weaponstatus[0]&=~PISF_JUSTUNLOAD;
			bool nomags=HDMagAmmo.NothingLoaded(self,"HD9mMag15");
			If(pressingzoom()&&invoker.weaponstatus[PISS_MAG]>-1)Setweaponstate("CheckMag");
			if((invoker.weaponstatus[PISS_MAG]>=15)&&!pressingzoom())setweaponstate("nope");
			else if(
				invoker.weaponstatus[PISS_MAG]<1
				&&(
					pressinguse()
					||(nomags&&!pressingzoom())
				)
			){
				if(
					countinv("HDPistolAmmo")
				)setweaponstate("loadchamber");
				else setweaponstate("nope");
			}else if(nomags&&!pressingzoom())setweaponstate("nope");
		}goto unmag;
	CheckMag:
		---- A 0;
		#### A 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PI2GA0"),2);
		PSR1 Q 0 A_Jump(256,2); 
		PSR3 A 0;
		#### Q 1 offset(0,0)A_SetCrosshair(21);
		#### Q 2;
		#### SR 2;
		#### R 0 A_JumpIf((player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"))&&(invoker.weaponstatus[PISS_CHAMBER]>0),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),5);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,7);
		PSR1 A 0 A_Jump(256,6);
		PSR4 F 2 offset(-5,15); 
		#### F 0 A_Jump(256,4);
		PSR3 F 2 offset(-5,15);
		#### F 0 A_Jump(256,2);
		#### F 2 offset(5,15);
		#### F 0 offset(0,0);
		---- R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4R0"),4);
		---- R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),4);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,4);
		PSR1 A 0 A_Jump(256,3);
		PSR4 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		PSR3 A 0;
		#### NLJ 1 offset(0,15) {A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));if((HDPlayerPawn(self).bloodpressure>19)||(Health<41))A_SetTics(2);}
		#### A 0 A_JumpIf((HDPlayerPawn(self).bloodpressure<20)&&(Health>40),2);
		#### J 2 offset(0,15) A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		#### I 3{A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4)); A_StartSound("weapons/pismagclick",8,CHANF_OVERLAP);if((HDPlayerPawn(self).bloodpressure>25)||(Health<41))A_SetTics(4);}
		#### A 0 A_JumpIf(invoker.weaponstatus[PISS_MAG]<1,"Checkmagempty");
		---- A 0 A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
	CheckLoop:	
		---- A 0 A_OverLay(102,"Dumb");
		#### H 5 offset(0,15) A_JumpIf(!pressingreload(),"CheckEnd");
		Loop;
	Dumb:
		STUP A 0 A_OverLayOffset(102,29,24);
		STUP A 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>1,1);
		Stop;
		STUP B 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>2,1);
		Stop;
		STUP C 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>3,1);
		Stop;
		STUP D 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>4,1);
		Stop;
		STUP E 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>5,1);
		Stop;
		STUP F 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>6,1);
		Stop;
		STUP G 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>7,1);
		Stop;
		STUP H 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>8,1);
		Stop;
		STUP I 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>9,1);
		Stop;
		STUP J 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>10,1);
		Stop;
		STUP K 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>11,1);
		Stop;
		STUP L 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>12,1);
		Stop;
		STUP M 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>13,1);
		Stop;
		Stop;
		STUP N 5 A_JumpIf(invoker.weaponstatus[PISS_MAG]>14,1);
		Stop;
		STUP O 5;
		Stop;
	CheckEnd:
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4R0"),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),4);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,4);
		PSR1 A 0 A_Jump(256,3);
		PSR4 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		PSR3 A 0;
		#### H 3 offset(0,15) {A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));if((HDPlayerPawn(self).bloodpressure>19)||(Health<41))A_SetTics(4);}
		#### I 3 offset(0,15){if((HDPlayerPawn(self).bloodpressure>25)||(Health<41))A_SetTics(5);}
		#### A 0 A_StartSound("weapons/pismagclick",8);
		#### A 0 A_JumpIf((HDPlayerPawn(self).bloodpressure<20)&&(Health>40),2);
		#### J 2 offset(0,15);
		#### JL 4 offset(0,15);
		goto reloadend;
	Checkmagempty:
		---- R 0;
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4R0"),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),4);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,4);
		PSR1 A 0 A_Jump(256,3);
		PSR4 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		PSR3 A 0;
		//---- A 0 A_OverLay(102,"Dumb");
		#### D 5 offset(0,15) A_JumpIf(!pressingreload(),"CheckEndEmpty");
		Loop;
	CheckEndEmpty:	
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4R0"),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),4);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,4);
		PSR1 A 0 A_Jump(256,3);
		PSR4 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		PSR3 A 0;
		#### D 3 offset(0,15) {A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));if((HDPlayerPawn(self).bloodpressure>19)||(Health<41))A_SetTics(4);}
		#### I 3 offset(0,15){if((HDPlayerPawn(self).bloodpressure>25)||(Health<41))A_SetTics(5);}
		#### A 0 A_StartSound("weapons/pismagclick",8);
		#### A 0 A_JumpIf((HDPlayerPawn(self).bloodpressure<20)&&(Health>40),2);
		#### J 2 offset(0,15);
		#### JL 4 offset(0,15);
		Goto reloadend;
	unmag:
		---- A 0;
		#### A 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PI2GA0"),2);
		PSR1 Q 0 A_Jump(256,2); 
		PSR3 A 0;
		#### Q 1 offset(0,0)A_SetCrosshair(21);
		#### Q 2;
		#### SR 2;
		#### R 0 A_JumpIf((player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"))&&(invoker.weaponstatus[PISS_CHAMBER]>0),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),5);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,7);
		PSR1 A 0 A_Jump(256,6);
		PSR4 F 2 offset(-5,15); 
		#### F 0 A_Jump(256,4);
		PSR3 F 2 offset(-5,15);
		#### F 0 A_Jump(256,2);
		#### F 2 offset(5,15);
		#### F 0 offset(0,0);
		#### A 0{
			if(invoker.weaponstatus[PISS_MAG]==-1)setweaponstate("magout");
			else if(
				(!PressingUnload()&&!PressingReload())
				||A_JumpIfInventory("HD9mMag15",0,"null")
			){
				setweaponstate("magouting");
			}
			else{
				//A_StartSound("weapons/pocket",9);
				setweaponstate("pocketmag"); 
			}
		}
	magouting:
		---- R 0;
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4R0"),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),4);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,4);
		PSR1 A 0 A_Jump(256,3);
		PSR4 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		PSR3 A 0;
		#### A 0 A_StartSound("weapons/pismagclick",8,CHANF_OVERLAP);
		#### BC 2 offset(0,15);
		#### A 0 A_JumpIf(invoker.weaponstatus[PISS_MAG]<1,"magoutingempty");
		#### HG 1 offset(0,15);
		#### F 2 offset(0,0);
		goto magout;
	magoutingempty:
		#### DE 1 offset(0,15);
		#### F 2 offset(0,0);
		goto magout;
	pocketmag:
		---- R 0;
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4R0"),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),4);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,4);
		PSR1 A 0 A_Jump(256,3);
		PSR4 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		PSR3 A 0;
		#### NMLJJ 1 offset(0,15) {A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));if((HDPlayerPawn(self).bloodpressure>19)||(Health<41))A_SetTics(2);}
		#### A 0 A_JumpIf((HDPlayerPawn(self).bloodpressure<20)&&(Health>40),2);
		#### J 2 offset(0,15) A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		#### I 3{A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4)); A_StartSound("weapons/pismagclick",8,CHANF_OVERLAP);if((HDPlayerPawn(self).bloodpressure>25)||(Health<41))A_SetTics(4);}
		#### A 0 A_JumpIf(invoker.weaponstatus[PISS_MAG]<1,"pocketmagempty");
		#### HG 3 offset(0,15) {A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));if((HDPlayerPawn(self).bloodpressure>19)||(Health<41))A_SetTics(4);}
		#### FF 3 {A_StartSound("weapons/pocket",9);if((HDPlayerPawn(self).bloodpressure>19)||(Health<41))A_SetTics(4);}
		goto magout;
	pocketmagempty:
		---- R 0;
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4R0"),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),4);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,4);
		PSR1 A 0 A_Jump(256,3);
		PSR4 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		PSR3 A 0;
		#### DE 3 offset(0,15) {A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));if((HDPlayerPawn(self).bloodpressure>25)||(Health<41))A_SetTics(4);}
		#### FF 3 {A_StartSound("weapons/pocket",9);if((HDPlayerPawn(self).bloodpressure>19)||(Health<41))A_SetTics(4);}
		goto magout;
	magout:
		#### A 0{
			int pmg=invoker.weaponstatus[PISS_MAG];
			invoker.weaponstatus[PISS_MAG]=-1;
			//if(pmg<0)setweaponstate("unmag");
			if(
				(!PressingUnload()&&!PressingReload())
				||A_JumpIfInventory("HD9mMag15",0,"null")
			){
				HDMagAmmo.SpawnMag(self,"HD9mMag15",pmg);
				//setweaponstate("magouting");
			}
			else{
				HDMagAmmo.GiveMag(self,"HD9mMag15",pmg);
				//A_StartSound("weapons/pocket",9);
				//setweaponstate("pocketmag");
			}
		}
		---- A 0{
			if(invoker.weaponstatus[0]&PISF_JUSTUNLOAD)setweaponstate("reloadend");
			else setweaponstate("loadmag");
		}

	loadmag:
		---- R 0;
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4R0"),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),4);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,4);
		PSR1 A 0 A_Jump(256,3);
		PSR4 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		PSR3 A 0;
		#### F 2{
			let mmm=hdmagammo(findinventory("HD9mMag15"));
			if(mmm){
				invoker.weaponstatus[PISS_MAG]=mmm.TakeMag(true);
			}
		}
		#### A 0 A_JumpIf(invoker.weaponstatus[PISS_MAG]<1,"loadmagempty");
		#### G 3 offset(0,15) A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		#### A 0 A_StartSound("weapons/pocket",9);
		#### H 3 offset(0,15) {A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));if((HDPlayerPawn(self).bloodpressure>19)||(Health<41))A_SetTics(4);}
		#### I 3 offset(0,15){if((HDPlayerPawn(self).bloodpressure>25)||(Health<41))A_SetTics(5);}
		#### A 0 A_StartSound("weapons/pismagclick",8);
		#### A 0 A_JumpIf((HDPlayerPawn(self).bloodpressure<20)&&(Health>40),2);
		#### J 2 offset(0,15);
		#### JL 4 offset(0,15);
		goto reloadend;
	loadmagempty:
		---- R 0;
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4R0"),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),4);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,4);
		PSR1 A 0 A_Jump(256,3);
		PSR4 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		PSR3 A 0;
		#### E 3 offset(0,15) A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		#### A 0 A_StartSound("weapons/pocket",9);
		#### D 3 offset(0,15) {A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));if((HDPlayerPawn(self).bloodpressure>19)||(Health<41))A_SetTics(4);}
		#### I 3 offset(0,15){if((HDPlayerPawn(self).bloodpressure>25)||(Health<41))A_SetTics(5);}
		#### A 0 A_StartSound("weapons/pismagclick",8);
		#### A 0 A_JumpIf((HDPlayerPawn(self).bloodpressure<20)&&(Health>40),2);
		#### J 2 offset(0,15);
		#### JL 4 offset(0,15);
	reloadend:
		#### A 0 A_JumpIf(invoker.weaponstatus[PISF_SAFETY]==0&&!(invoker.weaponstatus[0]&PISF_JUSTUNLOAD)&&invoker.weaponstatus[PISS_MAG]>0&&invoker.weaponstatus[PISS_CHAMBER]==0,"chamber_manualReload");
		---- R 0;
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4R0"),4);
		#### R 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3R0"),4);
		PSR2 A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,6);
		PSR1 A 0 A_Jump(256,5);
		PSR4 F 3 offset(-5,20);
		#### A 0 A_Jump(256,4);
		PSR3 F 3 offset(-5,20);
		#### A 0 A_Jump(256,2);
		#### F 3 offset(5,20);
		#### A 0 A_JumpIf((player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4A0"))||(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3A0")),2);
		PSR1 A 0 A_Jump(256,2);
		PSR3 A 0;
		#### RSQ 2 offset(0,0);
		#### Q 0 A_JumpIf((player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR4Q0"))||(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("PSR3Q0")),2);
		PISG A 0 A_Jump(256,3);
		PI2G A 1 offset(2,-5);
		#### A 0 A_Jump(256,2);
		#### A 1 offset(-2,-5);
		#### A 0 A_JumpIf(invoker.weaponstatus[PISF_SAFETY]==0&&!(invoker.weaponstatus[0]&PISF_JUSTUNLOAD),"chamber_manual");
		goto nope;

	user1:
	altreload:
	swappistols:
		---- A 0 A_SwapHandguns();
		---- A 0{
			bool id=(Wads.CheckNumForName("id",0)!=-1);
			bool offhand=invoker.wronghand;
			bool lefthanded=(id!=offhand);
			if(lefthanded){
				A_Overlay(1025,"raiseleft");
				A_Overlay(1026,"lowerright");
			}else{
				A_Overlay(1025,"raiseright");
				A_Overlay(1026,"lowerleft");
			}
		}
		TNT1 A 5;
		PISG A 0 A_CheckPistolHand();
		goto nope;
	lowerleft:
		PISG A 0 A_JumpIf(Wads.CheckNumForName("id",0)!=-1,2);
		PI2G A 0;
		#### B 1 offset(-6,38);
		#### B 1 offset(-12,48);
		#### B 1 offset(-20,60);
		#### B 1 offset(-34,76);
		#### B 1 offset(-50,86);
		stop;
	lowerright:
		PI2G A 0 A_JumpIf(Wads.CheckNumForName("id",0)!=-1,2);
		PISG A 0;
		#### B 1 offset(6,38);
		#### B 1 offset(12,48);
		#### B 1 offset(20,60);
		#### B 1 offset(34,76);
		#### B 1 offset(50,86);
		stop;
	raiseleft:
		PISG A 0 A_JumpIf(Wads.CheckNumForName("id",0)!=-1,2);
		PI2G A 0;
		#### A 1 offset(-50,86);
		#### A 1 offset(-34,76);
		#### A 1 offset(-20,60);
		#### A 1 offset(-12,48);
		#### A 1 offset(-6,38);
		stop;
	raiseright:
		PI2G A 0 A_JumpIf(Wads.CheckNumForName("id",0)!=-1,2);
		PISG A 0;
		#### A 1 offset(50,86);
		#### A 1 offset(34,76);
		#### A 1 offset(20,60);
		#### A 1 offset(12,48);
		#### A 1 offset(6,38);
		stop;
	whyareyousmiling:
		#### B 1 offset(0,48);
		#### B 1 offset(0,60);
		#### B 1 offset(0,76);
		TNT1 A 7;
		PISG A 0{
			invoker.wronghand=!invoker.wronghand;
			A_CheckPistolHand();
		}
		#### B 1 offset(0,76);
		#### B 1 offset(0,60);
		#### B 1 offset(0,48);
		goto nope;


	spawn:
		PIST ABCD -1 nodelay{
			if(invoker.weaponstatus[PISS_CHAMBER]<1){
				if(invoker.weaponstatus[0]&PISF_SELECTFIRE)frame=3;
				else frame=1;
			}else{
				if(invoker.weaponstatus[0]&PISF_SELECTFIRE)frame=2;
				else frame=0;
			}
		}stop;
	}
	override void initializewepstats(bool idfa){
		weaponstatus[PISS_MAG]=15;
		weaponstatus[PISS_CHAMBER]=2;
	}
	override void loadoutconfigure(string input){
		int selectfire=getloadoutvar(input,"selectfire",1);
		if(!selectfire){
			weaponstatus[0]&=~PISF_SELECTFIRE;
			weaponstatus[0]&=~PISF_FIREMODE;
		}else if(selectfire>0){
			weaponstatus[0]|=PISF_SELECTFIRE;
		}
		if(weaponstatus[0]&PISF_SELECTFIRE){
			int firemode=getloadoutvar(input,"firemode",1);
			if(!firemode)weaponstatus[0]&=~PISF_FIREMODE;
			else if(firemode>0)weaponstatus[0]|=PISF_FIREMODE;
		}
	}
}
enum pistolstatus{
	PISF_SELECTFIRE=1,
	PISF_FIREMODE=2,
	PISF_SAFETY=3,
	PISF_JUSTUNLOAD=4,
	PISS_FLAGS=0,
	PISS_MAG=1,
	PISS_CHAMBER=2, //0 empty, 1 spent, 2 loaded
};



//use this to give an autopistol in a custom loadout
class HDAutoPistol:HDWeaponGiver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Pistol (select-fire)"
		//$Sprite "PISTA0"
		tag "pistol (select-fire)";
		hdweapongiver.bulk 34;
		hdweapongiver.weapontogive "HDPistol";
		hdweapongiver.config "selectfire";
		hdweapongiver.weprefid HDLD_PISTOL;
		inventory.icon "PISTC0";
	}
}

