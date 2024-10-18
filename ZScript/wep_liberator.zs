// ------------------------------------------------------------
// 7.76mm Reloading Bot
// ------------------------------------------------------------
class AutoReloadingThingy:HDWeapon{
	int powders;
	int brass;
	bool makinground;
	override void beginplay(){
		super.beginplay();
		brass=0;powders=0;makinground=false;
	}
	override void Consolidate(){
		int totalpowder=owner.countinv("FourMilAmmo");
		int totalbrass=owner.countinv("SevenMilBrass");
		int onppowder=totalpowder;
		int onpbrass=totalbrass;
		let bp=hdbackpack(owner.FindInventory("HDBackpack",true));
		if(bp){
			totalpowder+=bp.Storage.GetAmount('fourmilammo');
			totalbrass+=bp.Storage.GetAmount('sevenmilbrass');
		}
		if(!totalbrass||totalpowder<4)return;
		int canmake=min(totalbrass,totalpowder/4);
		//matter is being lost in this exchange. if you have a backpack you WILL have space.
		int onpspace=HDPickup.MaxGive(owner,"SevenMilAmmoRecast",ENC_776);
		if(!bp)canmake=min(canmake,onpspace);

		//evaluate amounts
		totalpowder-=canmake*4;
		totalbrass-=canmake;
		int didmake=canmake-random(0,canmake/10);

		//deduct inventory
		//remove inv first, then bp
		int deductfrombp=canmake-onpbrass;
		owner.A_TakeInventory("sevenmilbrass",canmake);
		if(deductfrombp>0)bp.Storage.AddAmount('sevenmilbrass',-deductfrombp);
		deductfrombp=canmake*4-onppowder;
		owner.A_TakeInventory("fourmilammo",canmake*4);
		if(deductfrombp>0)bp.Storage.AddAMount('fourmilammo',-deductfrombp);


		//add resulting rounds
		//fill up inv first, then bp
		if(didmake<1)return;

		int bpadd=didmake-onpspace;
		int onpadd=didmake-max(0,bpadd);

		if(bpadd>0)bp.Storage.AddAmount("SevenMilAmmoRecast",bpadd,flags:BF_IGNORECAP);
		if(onpadd>0)owner.A_GiveInventory("SevenMilAmmoRecast",onpadd);


		owner.A_Log("You reloaded "..didmake.." 7.76mm rounds during your downtime.",true);
	}
	override void actualpickup(actor other,bool silent){
		super.actualpickup(other,silent);
		if(!other)return;
		while(powders>0){
			powders--;
			if(other.A_JumpIfInventory("FourMilAmmo",0,"null"))
				other.A_SpawnItemEx("FourMilAmmo",0,0,other.height-16,2,0,1);
			else HDF.Give(other,"FourMilAmmo",1);
		}
		while(brass>0){
			brass--;
			if(other.A_JumpIfInventory("SevenMilBrass",0,"null"))
				other.A_SpawnItemEx("SevenMilBrass",0,0,owner.height-16,2,0,1);
			else HDF.Give(other,"SevenMilBrass",1);
		}
	}
	void A_Chug(){
		A_StartSound("roundmaker/chug1",8);
		A_StartSound("roundmaker/chug2",9);
		vel.xy+=(frandom(-0.1,0.1),frandom(-0.1,0.1));
		if(floorz>=pos.z)vel.z+=frandom(0,1);
	}
	void A_MakeRound(){
		if(brass<1||powders<4){
			makinground=false;
			setstatelabel("spawn");
			return;
		}
		brass--;powders-=4;
		A_StartSound("roundmaker/pop",10);
		if(!random(0,63)){
			A_SpawnItemEx("HDExplosion");
			A_Explode(32,32);
		}else A_SpawnItemEx("HDLoose7mmRecast",0,0,0,1,0,3,0,SXF_NOCHECKPOSITION);
	}
	action void A_CheckChug(bool anyotherconditions=true){
		if(
			anyotherconditions
			&&countinv("SevenMilBrass")
			&&countinv("FourMilAmmo")>=4
		){
			invoker.makinground=true;
			int counter=min(10,countinv("SevenMilBrass"));
			invoker.brass=counter;A_TakeInventory("SevenMilBrass",counter);
			counter=min(30,countinv("FourMilAmmo"));
			invoker.powders=counter;A_TakeInventory("FourMilAmmo",counter);
			dropinventory(invoker);
		}
	}
	states{
	chug:
		---- AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 3{invoker.A_Chug();}
		---- A 10{invoker.A_MakeRound();}
		---- A 0 A_Jump(256,"spawn");
	}
}
class AutoReloader:AutoReloadingThingy{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "7.76mm Auto-Reloader"
		//$Sprite "RLDRA0"

		+weapon.wimpy_weapon
		+inventory.invbar
		+hdweapon.fitsinbackpack
		inventory.pickupsound "misc/w_pkup";
		inventory.pickupmessage "$PICKUP_RELOADER";
		scale 0.5;
		hdweapon.refid HDLD_776RL;
		tag "$TAG_RELOADER";
	}
	override double gunmass(){return 0;}
	override double weaponbulk(){
		return 20*amount;
	}
	override string,double getpickupsprite(){return "RLDRA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		vector2 bob=hpl.wepbob*0.3;
		int brass=hpl.countinv("SevenMilBrass");
		int fourm=hpl.countinv("FourMilAmmo");
		double lph=(brass&&fourm>=4)?1.:0.6;
		sb.drawimage("RLDRA0",(0,-64)+bob,
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER,
			alpha:lph,scale:(2,2)
		);
		sb.drawimage("RBRSA3A7",(-30,-64)+bob,
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER|sb.DI_ITEM_RIGHT,
			alpha:lph,scale:(2.5,2.5)
		);
		sb.drawimage("RCLSA3A7",(30,-64)+bob,
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER|sb.DI_ITEM_LEFT,
			alpha:lph,scale:(1.9,4.7)
		);
		sb.drawstring(
			sb.psmallfont,""..brass,(-30,-54)+bob,
			sb.DI_TEXT_ALIGN_RIGHT|sb.DI_SCREEN_CENTER_BOTTOM,
			fourm?Font.CR_GOLD:Font.CR_DARKGRAY,alpha:lph
		);
		sb.drawstring(
			sb.psmallfont,""..fourm,(30,-54)+bob,
			sb.DI_TEXT_ALIGN_LEFT|sb.DI_SCREEN_CENTER_BOTTOM,
			fourm?Font.CR_LIGHTBLUE:Font.CR_DARKGRAY,alpha:lph
		);
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRE..StringTable.Localize("$ARELWH_FIRE")//"  Assemble rounds\n"
		..LWPHELP_USE.."+"..LWPHELP_UNLOAD..StringTable.Localize("$ARELWH_SAMELOL")//"  same"
		;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	states{
	select0:
		TNT1 A 0 A_Raise(999);
		wait;
	deselect0:
		TNT1 A 0 A_Lower(999);
		wait;
	ready:
		TNT1 A 1 A_WeaponReady(WRF_ALLOWUSER3|WRF_ALLOWUSER4);
		goto readyend;
	fire:
		TNT1 A 0 A_CheckChug();
		goto ready;
	hold:
		TNT1 A 1;
		TNT1 A 0 A_Refire("hold");
		goto ready;
	user3:
		---- A 0{
			if(countinv("HD7mMag"))A_MagManager("HD7mMag");
			else if(countinv("HD7mClip"))A_MagManager("HD7mMag");
			else A_SelectWeapon("PickupManager");
		}
		goto ready;
	user4:
	unload:
		TNT1 A 1 A_CheckChug(pressinguse());
		goto ready;
	spawn:
		RLDR A -1 nodelay A_JumpIf(
			invoker.makinground
			&&invoker.brass>0
			&&invoker.powders>=3,
		"chug");
		stop;
	}
}


// ------------------------------------------------------------
// Liberator Battle Rifle
// ------------------------------------------------------------
class LiberatorRifle:AutoReloadingThingy{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Liberator"
		//$Sprite "BRFLB0"

		+hdweapon.fitsinbackpack
		weapon.slotnumber 6;
		weapon.slotpriority 2;
		weapon.kickback 20;
		weapon.selectionorder 27;
		inventory.pickupsound "misc/w_pkup";
		inventory.pickupmessage "$PICKUP_LIB";
		weapon.bobrangex 0.22;
		weapon.bobrangey 0.9;
		scale 0.7;
		obituary "%o was liberated by %k.";
		hdweapon.refid HDLD_LIB;
		tag "$TAG_LIB";
		inventory.icon "BRFLB0";

		hdweapon.ammo1 "HD7mMag",1;
		hdweapon.ammo2 "HDRocketAmmo",1;

		hdweapon.loadoutcodes "
			\cunogl - 0/1, whether it has a launcher
			\cunobp - 0/1, whether it is bullpup
			\cusemi - 0/1, whether it is limited to semi
			\culefty - 0/1, whether brass comes out on left
			\cualtreticle - 0/1, whether to use the glowing crosshair
			\cufrontreticle - 0/1, whether crosshair scales with zoom
			\cufiremode - 0/1, whether you start in full auto
			\cubulletdrop - 0-600, amount of compensation for bullet drop
			\cuzoom - ??-70, 10x the resulting FOV in degrees
			\cudot - 0-5";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override void postbeginplay(){
		super.postbeginplay();
		if(weaponstatus[0]&LIBF_NOLAUNCHER){
			barrelwidth=0.7;
			barreldepth=1.2;
			weaponstatus[0]&=~(LIBF_GRENADEMODE|LIBF_GRENADELOADED);
		}else{
			barrelwidth=1;
			barreldepth=3;
			bobrangey*=1.2;
		}
		if(weaponstatus[0]&LIBF_NOBULLPUP){
			barrellength=32;
			bfitsinbackpack=false;
			bobrangex*=1.08;bobrangey*=1.08;
		}else{
			barrellength=27;
		}
	}
	override double gunmass(){
		if(weaponstatus[0]&LIBF_NOBULLPUP){
			double howmuch=11;
			if(weaponstatus[0]&LIBF_NOLAUNCHER)return howmuch+weaponstatus[LIBS_MAG]*0.04;
			return howmuch+1.1+weaponstatus[LIBS_MAG]*0.05+(weaponstatus[0]&LIBF_GRENADELOADED?1.2:0.9);
		}else{
			double howmuch=9;
			if(weaponstatus[0]&LIBF_NOLAUNCHER)return howmuch+weaponstatus[LIBS_MAG]*0.04;
			return howmuch+1.+weaponstatus[LIBS_MAG]*0.04+(weaponstatus[0]&LIBF_GRENADELOADED?1.:0.6);
		}
	}
	override double weaponbulk(){
		double blx=(weaponstatus[0]&LIBF_NOBULLPUP)?120:100;
		if(!(weaponstatus[0]&LIBF_NOLAUNCHER)){
			blx+=28;
			if(weaponstatus[0]&LIBF_GRENADELOADED)blx+=ENC_ROCKETLOADED;
		}
		int mgg=weaponstatus[LIBS_MAG];
		return blx+(mgg<0?0:(ENC_776MAG_LOADED+mgg*ENC_776_LOADED));
	}
	override string,double getpickupsprite(bool usespare){
		string spr;
		int wep0=GetSpareWeaponValue(0,usespare);
		int wepmag=GetSpareWeaponValue(LIBS_MAG,usespare);

		// A: -g +m +a
		// B: +g +m +a
		// C: -g -m +a
		// D: +g -m +a
		if(wep0&LIBF_NOLAUNCHER){
			if(wepmag<0)spr="C";
			else spr="A";
		}else{
			if(wepmag<0)spr="D";
			else spr="B";
		}

		// E: -g +m -a
		// F: +g +m -a
		// G: -g -m -a
		// H: +g -m -a
		if(wep0&LIBF_NOAUTO)spr=string.format("%c",spr.byteat(0)+4);

		return ((wep0&LIBF_NOBULLPUP)?"BRLL":"BRFL")..spr.."0",1.;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			int nextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD7mMag"))) % 100;
			if(nextmagloaded>=30){
				sb.drawimage("RMAGNORM",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM);
			}else if(nextmagloaded<1){
				sb.drawimage("RMAGEMPTY",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,alpha:nextmagloaded?0.6:1.);
			}else sb.drawbar(
				"RMAGNORM","RMAGGREY",
				nextmagloaded,30,
				(-46,-3),-1,
				sb.SHADER_VERT,sb.DI_SCREEN_CENTER_BOTTOM
			);
			sb.drawnum(hpl.countinv("HD7mMag"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			if(!(hdw.weaponstatus[0]&LIBF_NOLAUNCHER)){
				sb.drawimage("ROQPA0",(-62,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
				sb.drawnum(hpl.countinv("HDRocketAmmo"),-56,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			}
		}
		if(!(hdw.weaponstatus[0]&LIBF_NOAUTO)){
			string llba="RBRSA3A7";
			if(hdw.weaponstatus[0]&LIBF_FULLAUTO)llba="STFULAUT";
			sb.drawimage(
				llba,(-22,-10),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TRANSLATABLE|sb.DI_ITEM_RIGHT
			);
		}
		if(hdw.weaponstatus[0]&LIBF_GRENADELOADED)sb.drawrect(-20,-15.6,4,2.6);
		int lod=max(hdw.weaponstatus[LIBS_MAG],0);
		sb.drawwepnum(lod,30);
		if(hdw.weaponstatus[LIBS_CHAMBER]==2){
			sb.drawrect(-19,-11,3,1);
			lod++;
		}
		if(hdw.weaponstatus[0]&LIBF_GRENADEMODE){
			DrawRifleGrenadeStatus(sb,hdw);
		}
	}
	override string gethelptext(){
		bool gl=!(weaponstatus[0]&LIBF_NOLAUNCHER);
		bool glmode=gl&&(weaponstatus[0]&LIBF_GRENADEMODE);
		LocalizeHelp();
		return
		LWPHELP_FIRESHOOT
		..(gl?(LWPHELP_ALTFIRE..(glmode?(StringTable.Localize("$LIBWH_ALTFIRE1")):(StringTable.Localize("$LIBWH_ALTFIRE2")))):"")
		..LWPHELP_RELOAD..StringTable.Localize("$LIBWH_RELOAD")
		..LWPHELP_USE.."+"..LWPHELP_RELOAD..StringTable.Localize("$LIBWH_UPRELOAD")
		..(gl?(LWPHELP_ALTRELOAD..StringTable.Localize("$LIBWH_ALTRELOAD")):"")
		..(glmode?(LWPHELP_FIREMODE.."+"..LWPHELP_UPDOWN..StringTable.Localize("$LIBWH_FMODPUD"))
			:(
			(LWPHELP_FIREMODE..StringTable.Localize("$LIBWH_FMODE"))
			..LWPHELP_ZOOM.."+"..LWPHELP_FIREMODE.."+"..LWPHELP_UPDOWN..StringTable.Localize("$LIBWH_ZPFMOD")))
		..LWPHELP_MAGMANAGER
		..LWPHELP_UNLOAD..StringTable.Localize("$LIBWH_UNLOAD")..(glmode?StringTable.Localize("$LIBWH_GL"):StringTable.Localize("$LIBWH_MAG"))
		..LWPHELP_USE.."+"..LWPHELP_UNLOAD..StringTable.Localize("$UPUNLOAD")
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int Light = Owner.CurSector.LightLevel * 1.75;
		if(owner.player.fixedlightlevel==1)Light = 255;
		if(hdw.weaponstatus[0]&LIBF_GRENADEMODE)sb.drawgrenadeladder(hdw.airburst,bob);
		else{
			double dotoff=max(abs(bob.x),abs(bob.y));
			if(dotoff<40){
				string whichdot=sb.ChooseReflexReticle(hdw.weaponstatus[LIBS_DOT]);
				sb.drawimage(
					whichdot,(0,0)+bob*1.1,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					alpha:0.8-dotoff*0.01,
					col:0xFF000000|sb.crosshaircolor.GetInt()
				);
			}
			sb.drawimage(
				"libsite",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);
			if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
			sb.drawimage(
				"libsite",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER, col:Color(254-Light, 0,0,0)
			);
			if(scopeview){
				int scaledyoffset=60;
				int scaledwidth=72;
				double degree=hdw.weaponstatus[LIBS_ZOOM]*0.1;
				double deg=1/degree;
				int cx,cy,cw,ch;
				[cx,cy,cw,ch]=screen.GetClipRect();
				sb.SetClipRect(
					-36+bob.x,24+bob.y,scaledwidth,scaledwidth,
					sb.DI_SCREEN_CENTER
				);


				sb.fill(color(255,0,0,0),
					bob.x-36,scaledyoffset+bob.y-36,
					72,72,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
				);

				texman.setcameratotexture(hpc,"HDXCAM_LIB",degree);
				let cam  = texman.CheckForTexture("HDXCAM_LIB",TexMan.Type_Any);
				let reticle = texman.CheckForTexture(
					(hdw.weaponstatus[0] & LIBF_ALTRETICLE)? "reticle2" : "reticle1"
				,TexMan.Type_Any);

				vector2 frontoffs=(0,scaledyoffset)+bob*2;

				double camSize = texman.GetSize(cam);
				sb.DrawCircle(cam,frontoffs,.08825,usePixelRatio:true);

				//[2022-09-17] there's a glitch in GZDoom where if the reticle would be drawn completely off screen,
				//the cliprect is ignored. The figure is a product of trial and error.
				if((bob.y/fov)<0.4){
					let reticleScale = camSize / texman.GetSize(reticle);
					if(hdw.weaponstatus[0]&LIBF_FRONTRETICLE){
						sb.DrawCircle(reticle,frontoffs,393*reticleScale, bob*4, 1.6*deg);
					}else{
						sb.DrawCircle(reticle,(0,scaledyoffset)+bob,.403*reticleScale, uvScale: .52);
					}
				}

				//see comments in zm66.zs
				//let hole = texman.CheckForTexture("scophole",TexMan.Type_Any);
				//let holeScale    = camSize / texman.GetSize(hole);
				//sb.DrawCircle(hole, (0, scaledyoffset) + bob, .403 * holeScale, bob * 5, uvScale: .95);


				screen.SetClipRect(cx,cy,cw,ch);

				sb.drawimage(
					"libscope",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
				);
				sb.drawstring(
					sb.mAmountFont,string.format("%.1f",degree),
					(6+bob.x,95+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
					Font.CR_BLACK
				);
				sb.drawstring(
					sb.mAmountFont,string.format("%i",hdw.weaponstatus[LIBS_DROPADJUST]),
					(6+bob.x,17+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
					Font.CR_BLACK
				);
			}
		}
	}
	override void SetReflexReticle(int which){weaponstatus[LIBS_DOT]=which;}
	override void failedpickupunload(){
		failedpickupunloadmag(LIBS_MAG,"HD7mMag");
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("SevenMilAmmo"))owner.A_DropInventory("SevenMilAmmo",30);
			else{
				double angchange=(weaponstatus[0]&LIBF_NOLAUNCHER)?0:-10;
				if(angchange)owner.angle-=angchange;
				owner.A_DropInventory("HD7mMag",1);
				if(angchange){
					owner.angle+=angchange*2;
					owner.A_DropInventory("HDRocketAmmo",1);
					owner.angle-=angchange;
				}
			}
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("SevenMilAmmo");
		owner.A_TakeInventory("SevenMilBrass");
		owner.A_TakeInventory("FourMilAmmo");
		if(weaponstatus[0]&LIBF_NOLAUNCHER)hdammotype2=null;
		else owner.A_SetInventory("HDRocketAmmo",1);
		ForceOneBasicAmmo("HD7mMag");
	}
	override void tick(){
		super.tick();
		drainheat(LIBS_HEAT,8);
	}
	action void A_Chamber(bool unloadonly=false){
		A_StartSound("weapons/libchamber",8,CHANF_OVERLAP);
		if(invoker.weaponstatus[LIBS_CHAMBER]>0){
			actor brsss=null;
			class<actor> brscc="HDSpent7mm";
			if(invoker.weaponstatus[LIBS_CHAMBER]==2){
				brscc=invoker.weaponstatus[0]&LIBF_RECAST?"HDLoose7mmRecast":"HDLoose7mm";
			}
			if(invoker.weaponstatus[0]&LIBF_NOBULLPUP){
				bool lefty=invoker.weaponstatus[0]&LIBF_LEFTY;
				int lll=(lefty?1:-1);
				brsss=A_EjectCasing(
					brscc,lll,
					(frandom(5,5.5),frandom(0,lll),frandom(0,0.2)),
					(5,1.5*lll,-3)
				);
				brsss.bseesdaggers=lefty;
			}else{
				int bss=invoker.weaponstatus[LIBS_BRASS];
				if(
					brscc=="HDSpent7mm"
					&&bss<random(1,7)
				){
					invoker.weaponstatus[LIBS_BRASS]++;
					A_StartSound("misc/casing",8,CHANF_OVERLAP);
				}else{
					brsss=A_EjectCasing(
						brscc,0,
						(frandom(0.1,2.),frandom(-0.1,0.1),frandom(-0.1,0.1)),
						(12,0,-3)
					);
				}
			}
			if(!!brsss){
				brsss.target=self;
				if(brscc!="HDSpent7mm")brsss.vel*=0.4;
				brsss.vel+=vel;
				brsss.A_StartSound(brsss.bouncesound,volume:0.4);
			}
		}

		invoker.weaponstatus[0]&=~LIBF_RECAST;

		if(
			!unloadonly
			&&invoker.weaponstatus[LIBS_MAG]>0
		){
			invoker.weaponstatus[LIBS_CHAMBER]=2;
			if(HD7mMag.CheckRecast(invoker.weaponstatus[LIBS_MAG],invoker.weaponstatus[LIBS_RECASTS])){
				invoker.weaponstatus[0]|=LIBF_RECAST;
				invoker.weaponstatus[LIBS_RECASTS]--;
			}
			invoker.weaponstatus[LIBS_MAG]--;
		}else{
			invoker.weaponstatus[LIBS_CHAMBER]=0;
		}
	}
	states{
	brasstube:
		TNT1 A 4{
			if(
				invoker.weaponstatus[LIBS_BRASS]>0
				&&(
					pitch>5
					||IsBusy(self)
				)
			){
				double fc=max(pitch*0.01,5);
				double cosp=cos(pitch);
				actor brsss;
				[cosp,brsss]=A_SpawnItemEx("HDSpent7mm",
					cosp*12,0,height-8-sin(pitch)*12,
					cosp*fc,0.2*randompick(-1,1),-sin(pitch)*fc,
					0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
				brsss.vel+=vel;
				brsss.A_StartSound(brsss.bouncesound,volume:0.4);
				invoker.weaponstatus[LIBS_BRASS]--;
			}
		}wait;
	select0:
		BRFG A 0{
			A_CheckDefaultReflexReticle(LIBS_DOT);
			A_Overlay(776,"brasstube");
			invoker.weaponstatus[0]&=~LIBF_GRENADEMODE;
		}goto select0big;
	deselect0:
		BRFG A 0{
			while(invoker.weaponstatus[LIBS_BRASS]>0){
				double cosp=cos(pitch);
				actor brsss;
				[cosp,brsss]=A_SpawnItemEx("HDSpent7mm",
					cosp*12,0,height-8-sin(pitch)*12,
					cosp*3,0.2*randompick(-1,1),-sin(pitch)*3,
					0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
				brsss.vel+=vel;
				brsss.A_StartSound(brsss.bouncesound,volume:0.4);
				invoker.weaponstatus[LIBS_BRASS]--;
			}
		}goto deselect0big;
	ready:
		BRFG A 1{
			if(pressingzoom()){
				if(player.cmd.buttons&BT_USE){
					A_ZoomAdjust(LIBS_DROPADJUST,0,1200,BT_USE);
				}else if(invoker.weaponstatus[0]&LIBF_FRONTRETICLE)A_ZoomAdjust(LIBS_ZOOM,20,40);
				else A_ZoomAdjust(LIBS_ZOOM,6,70);
				A_WeaponReady(WRF_NONE);
			}else A_WeaponReady(WRF_ALL);
		}goto readyend;
	user3:
		---- A 0 A_JumpIf(!(invoker.weaponstatus[0]&LIBF_GRENADEMODE),1);
		goto super::user3;
		---- A 0 A_MagManager("HD7mMag");
		goto ready;

	fire:
		BRFG A 0{
			if(
				invoker.weaponstatus[0]&LIBF_NOLAUNCHER
				||!(invoker.weaponstatus[0]&LIBF_GRENADEMODE)
			){
				setweaponstate("firegun");
			}else setweaponstate("firegrenade");
		}
	hold:
		BRFG A 1{
			if(
				invoker.weaponstatus[0]&LIBF_GRENADEMODE
				||!(invoker.weaponstatus[0]&LIBF_FULLAUTO)
				||(invoker.weaponstatus[0]&LIBF_NOAUTO)
				||invoker.weaponstatus[LIBS_CHAMBER]!=2
			)setweaponstate("nope");
		}goto shoot;

	firegun:
		BRFG A 1{
			if(invoker.weaponstatus[0]&LIBF_NOBULLPUP)A_SetTics(0);
			else if(invoker.weaponstatus[0]&LIBF_FULLAUTO)A_SetTics(2);
		}
	shoot:
		BRFG A 1{
			if(invoker.weaponstatus[LIBS_CHAMBER]==2)A_Gunflash();
			else setweaponstate("chamber_manual");
			A_WeaponReady(WRF_NONE);
		}
		BRFG B 1 A_Chamber();
		BRFG A 0 A_Refire();
		goto nope;
	flash:
		BRFF A 1 bright{
			A_Light1();
			A_StartSound("weapons/bigrifle",CHAN_WEAPON);

			HDBulletActor.FireBullet(self,
				invoker.weaponstatus[0]&LIBF_RECAST?"HDB_776r":"HDB_776",
				aimoffy:(-HDCONST_GRAVITY/1000.)*invoker.weaponstatus[LIBS_DROPADJUST]
			);

			if(invoker.weaponstatus[0]&LIBF_NOBULLPUP){
				HDFlashAlpha(16);
				A_ZoomRecoil(0.90);
				A_MuzzleClimb(
					0,0,
					-0.07,-0.14,
					-frandom(0.3,0.6),-frandom(1.,1.4),
					-frandom(0.2,0.4),-frandom(1.,1.4)
				);
			}else{
				HDFlashAlpha(32);
				A_ZoomRecoil(0.95);
				A_MuzzleClimb(
					0,0,
					-0.2,-0.4,
					-frandom(0.5,0.9),-frandom(1.7,2.1),
					-frandom(0.5,0.9),-frandom(1.7,2.1)
				);
			}

			invoker.weaponstatus[LIBS_CHAMBER]=1;
			invoker.weaponstatus[LIBS_HEAT]+=2;
			invoker.weaponstatus[0]&=~LIBF_RECAST;
			A_AlertMonsters();
		}
		goto lightdone;
	chamber_manual:
		BRFG A 1 offset(-1,34){
			if(
				invoker.weaponstatus[LIBS_CHAMBER]==2
				||invoker.weaponstatus[LIBS_MAG]<1
			)setweaponstate("nope");
		}
		BRFG B 1 offset(-2,36)A_Chamber();
		BRFG B 1 offset(-2,38);
		BRFG A 1 offset(-1,34);
		goto nope;


	firemode:
		---- A 0{
			if(invoker.weaponstatus[0]&LIBF_GRENADEMODE)setweaponstate("abadjust");
			else if(!(invoker.weaponstatus[0]&LIBF_NOAUTO))invoker.weaponstatus[0]^=LIBF_FULLAUTO;
		}goto nope;


	unloadchamber:
		BRFG B 1 offset(-1,34){
			if(
				invoker.weaponstatus[LIBS_CHAMBER]<1
			)setweaponstate("nope");
		}
		BRFG B 1 offset(-2,36)A_Chamber(true);
		BRFG B 1 offset(-2,38);
		BRFG A 1 offset(-1,34);
		goto nope;

	loadchamber:
		BRFG A 0 A_JumpIf(invoker.weaponstatus[LIBS_CHAMBER]>0,"nope");
		BRFG A 0 A_JumpIf(
			!countinv("SevenMilAmmo")
			&&!countinv("SevenMilAmmoRecast")
		,"nope");
		BRFG A 1 offset(0,34) A_StartSound("weapons/pocket",9);
		BRFG A 2 offset(2,36);
		BRFG B 8 offset(5,40);
		BRFG B 8 offset(7,44);
		BRFG B 8 offset(6,43);
		BRFG B 10 offset(4,39){
			class<inventory> rndtp="SevenMilAmmo";
			if(!countinv(rndtp))rndtp="SevenMilAmmoRecast";

			if(countinv(rndtp)){
				A_TakeInventory(rndtp,1,TIF_NOTAKEINFINITE);
				invoker.weaponstatus[LIBS_CHAMBER]=2;

				if(rndtp=="SevenMilAmmoRecast")invoker.weaponstatus[0]|=LIBF_RECAST;
				else invoker.weaponstatus[0]&=~LIBF_RECAST;

				A_StartSound("weapons/libchamber2",8);
				A_StartSound("weapons/libchamber2a",8,CHANF_OVERLAP,0.7);
			}else A_SetTics(4);
		}
		BRFG B 7 offset(5,37);
		BRFG B 1 offset(2,36);
		BRFG A 1 offset(0,34);
		goto readyend;

	user4:
	unload:
		---- A 1 A_CheckChug(pressinguse()); //DO NOT set this frame to zero
		BRFG A 0{
			invoker.weaponstatus[0]|=LIBF_JUSTUNLOAD;
			if(
				invoker.weaponstatus[0]&LIBF_GRENADEMODE
			){
				return resolvestate("unloadgrenade");
			}else if(
				invoker.weaponstatus[LIBS_MAG]>=0  
			){
				return resolvestate("unmag");
			}else if(
				invoker.weaponstatus[LIBS_CHAMBER]>0  
			){
				return resolvestate("unloadchamber");
			}
			return resolvestate("nope");
		}
	reload:
		BRFG A 0{
			if(PressingZoom())Return resolvestate("CheckMag");
			int inmag=invoker.weaponstatus[LIBS_MAG];
			bool nomags=HDMagAmmo.NothingLoaded(self,"HD7mMag");
			bool haverounds=countinv("SevenMilAmmo")||countinv("SevenMilAmmoRecast");
			invoker.weaponstatus[0]&=~LIBF_JUSTUNLOAD;

			//no point reloading
			if(
				inmag>=30
				||(
					//no mags to load and can't directly load chamber
					nomags
					&&(
						!haverounds
						||inmag>=0
						||invoker.weaponstatus[LIBS_CHAMBER]>0
					)
				)
			)return resolvestate("nope");

			//no mag, empty chamber, have loose rounds
			if(
				inmag<0
				&&invoker.weaponstatus[LIBS_CHAMBER]<1
				&&haverounds
				&&(
					pressinguse()
					||nomags
				)
			)return resolvestate("loadchamber");

			if(
				invoker.weaponstatus[LIBS_MAG]>0  
			){
				//if full mag and unchambered, chamber
				if(
					invoker.weaponstatus[LIBS_MAG]>=30  
					&&invoker.weaponstatus[LIBS_CHAMBER]!=2
				){
					return resolvestate("chamber_manual");
				}				
			}
			return resolvestate("unmag");
		}

	unmag:
		BRFG A 1 offset(0,34);
		BRFG A 1 offset(2,36);
		BRFG B 1 offset(4,40);
		BRFG B 2 offset(8,42){
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
			A_StartSound("weapons/rifleclick2",8);
		}
		BRFG B 4 offset(14,46){
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
			A_StartSound ("weapons/rifleunload",8,CHANF_OVERLAP);
		}
		BRFG B 0{
			int magamt=invoker.weaponstatus[LIBS_MAG];
			if(magamt<0){setweaponstate("magout");return;}

			if(magamt>0){
				int fullets=clamp(30-invoker.weaponstatus[LIBS_RECASTS],0,magamt);
				magamt+=fullets*100;
			}

			invoker.weaponstatus[LIBS_MAG]=-1;
			invoker.weaponstatus[LIBS_RECASTS]=0;
			if(
				!PressingReload()
				&&!PressingUnload()
			){
				HDMagAmmo.SpawnMag(self,"HD7mMag",magamt);
				setweaponstate("magout");
			}else{
				HDMagAmmo.GiveMag(self,"HD7mMag",magamt);
				setweaponstate("pocketmag");
			}
		}
	pocketmag:
		BRFG B 7 offset(12,52)A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		BRFG B 0 A_StartSound("weapons/pocket",9);
		BRFG BB 7 offset(14,54)A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		BRFG B 0{
		}goto magout;
	magout:
		BRFG B 4{
			invoker.weaponstatus[LIBS_MAG]=-1;
			invoker.weaponstatus[LIBS_RECASTS]=0;
			if(invoker.weaponstatus[0]&LIBF_JUSTUNLOAD)setweaponstate("reloaddone");
		}goto loadmag;


	loadmag:
		BRFG B 0 A_StartSound("weapons/pocket",9);
		BRFG BB 7 offset(14,54)A_MuzzleClimb(frandom(-0.2,0.4),frandom(-0.2,0.8));
		BRFG B 6 offset(12,52){
			let mmm=hdmagammo(findinventory("HD7mMag"));
			if(mmm){
				int minput=mmm.TakeMag(true);
				int rndcnt=minput%100;
				invoker.weaponstatus[LIBS_MAG]=rndcnt;
				invoker.weaponstatus[LIBS_RECASTS]=clamp(rndcnt-(minput/100),0,rndcnt);

				A_StartSound("weapons/rifleclick",8);
				A_StartSound("weapons/rifleload",8,CHANF_OVERLAP);
			}
		}
		BRFG B 2 offset(8,46) A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP);
		goto reloaddone;

	reloaddone:
		BRFG B 1 offset (4,40);
		BRFG A 1 offset (2,34);
		goto chamber_manual;


	altfire:
		BRFG A 1 offset(0,34){
			if(invoker.weaponstatus[0]&LIBF_NOLAUNCHER){
				invoker.weaponstatus[0]&=~(LIBF_GRENADEMODE|LIBF_GRENADELOADED);
				setweaponstate("nope");
			}else invoker.airburst=0;
		}
		BRFG A 1 offset(2,36);
		BRFG B 1 offset(4,40);
		BRFG B 1 offset(2,36);
		BRFG A 1 offset(0,34);
		BRFG A 0{
			invoker.weaponstatus[0]^=LIBF_GRENADEMODE;
			A_SetHelpText();
			A_Refire();
		}goto ready;
	althold:
		BRFG A 0;
		goto nope;

	CheckMag:
		BRFG B 2 A_Jumpif(!PressingReload(), "Nope");
		---- B 0 {if(invoker.weaponstatus[LIBS_MAG]>0)A_Overlay(102, "Dumb");if(invoker.weaponstatus[LIBS_CHAMBER]==2)A_Overlay(103, "Dumb2");}
		Loop;
	Dumb:
		STUP A 0 A_OverLayOffset(102,29,24);
		STUP A 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>2,1);
		Stop;
		STUP B 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>4,1);
		Stop;
		STUP C 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>6,1);
		Stop;
		STUP D 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>8,1);
		Stop;
		STUP E 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>10,1);
		Stop;
		STUP F 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>12,1);
		Stop;
		STUP G 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>14,1);
		Stop;
		STUP H 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>16,1);
		Stop;
		STUP I 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>18,1);
		Stop;
		STUP J 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>20,1);
		Stop;
		STUP K 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>22,1);
		Stop;
		STUP L 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>24,1);
		Stop;
		STUP M 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>26,1);
		Stop;
		STUP N 5 A_JumpIf(invoker.weaponstatus[LIBS_MAG]>28,1);
		Stop;
		STUP O 5;
		Stop;	
	
	Dumb2:
		STUP A 0 A_OverLayOffset(103, 32, 22);
		STUP Q 5;
		Stop;	

	firegrenade:
		BRFG B 2{
			if(invoker.weaponstatus[0]&LIBF_GRENADELOADED){
				A_FireHDGL();
				invoker.weaponstatus[0]&=~LIBF_GRENADELOADED;
			}else setweaponstate("nope");
		}
		BRFG B 2{
			if(invoker.weaponstatus[0]&LIBF_NOBULLPUP){
				A_ZoomRecoil(0.99);
				A_MuzzleClimb(
					0,0,
					-0.8,-2.,
					-0.4,-1.
				);
			}else{
				A_ZoomRecoil(0.95);
				A_MuzzleClimb(
					0,0,
					-1.2,-3.,
					-0.6,-1.4
				);
			}
		}
		BRFG A 0 A_Refire("nope");
		goto ready;
	altreload:
		BRFG A 0{
			if(!(invoker.weaponstatus[0]&LIBF_NOLAUNCHER)){
				invoker.weaponstatus[0]&=~LIBF_JUSTUNLOAD;
				setweaponstate("unloadgrenade");
			}
		}goto nope;
	unloadgrenade:
		BRFG A 1 offset(0,34){
			A_SetCrosshair(21);
			if(
				(
					//just unloading but no grenade
					invoker.weaponstatus[0]&LIBF_JUSTUNLOAD
					&&!(invoker.weaponstatus[0]&LIBF_GRENADELOADED)
				)||(
					//reloading but no ammo or already loaded
					!(invoker.weaponstatus[0]&LIBF_JUSTUNLOAD)
					&&(
						!countinv("HDRocketAmmo")
						||invoker.weaponstatus[0]&LIBF_GRENADELOADED
					)
				)
			){
				setweaponstate("nope");
			}
		}
		BRFG A 1 offset(-5,40);
		BRFG A 1 offset(-10,50);
		BRFG A 1 offset(-15,56);
		BRFG A 4 offset(-14,54){
			A_StartSound("weapons/pocket",9);
			A_StartSound("weapons/grenopen",8);
		}
		BRFG A 3 offset(-16,56){
			if(invoker.weaponstatus[0]&LIBF_GRENADELOADED){
				if(
					(PressingReload()||PressingUnload())
					&&!A_JumpIfInventory("HDRocketAmmo",0,"null")
				){
					A_GiveInventory("HDRocketAmmo");
					A_StartSound("weapons/pocket",9);
					A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
					A_SetTics(6);
				}else A_SpawnItemEx("HDRocketAmmo",
					cos(pitch)*12,0,gunheight()-2-12*sin(pitch),
					vel.x,vel.y,vel.z,
					0,SXF_SETTARGET|SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
				invoker.weaponstatus[0]&=~LIBF_GRENADELOADED;
			}
		}
		BRFG A 0{
			if(invoker.weaponstatus[0]&LIBF_JUSTUNLOAD)setweaponstate("altreloaddone");
		}
		BRFG AA 8 offset(-16,56)A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		BRFG A 18 offset(-14,54){
			if(!countinv("HDRocketAmmo"))return;
			A_StartSound("weapons/grenreload",8);
			A_TakeInventory("HDRocketAmmo",1,TIF_NOTAKEINFINITE);
			invoker.weaponstatus[0]|=LIBF_GRENADELOADED;
		}
		BRFG B 4 offset(-12,50)A_StartSound("weapons/grenopen",8);
	altreloaddone:
		BRFG A 1 offset(-15,56);
		BRFG A 1 offset(-10,50);
		BRFG A 1 offset(-5,40);
		BRFG A 1 offset(0,34);
		goto nope;

	spawn:
		BRFL ABCDEFGH -1 nodelay{
			if(invoker.weaponstatus[0]&LIBF_NOBULLPUP){
				sprite=getspriteindex("BRLLA0");
			}
			// A: -g +m +a
			// B: +g +m +a
			// C: -g -m +a
			// D: +g -m +a
			if(invoker.weaponstatus[0]&LIBF_NOLAUNCHER){
				if(invoker.weaponstatus[LIBS_MAG]<0)frame=2;
				else frame=0;
			}else{
				if(invoker.weaponstatus[LIBS_MAG]<0)frame=3;
				else frame=1;
			}

			// E: -g +m -a
			// F: +g +m -a
			// G: -g -m -a
			// H: +g -m -a
			if(invoker.weaponstatus[0]&LIBF_NOAUTO)frame+=4;

			if(
				invoker.makinground
				&&invoker.brass>0
				&&invoker.powders>=3
			)setstatelabel("chug");
		}
		BRLL ABCDEFGH -1;
		stop;
	}
	override void InitializeWepStats(bool idfa){
		if(!(weaponstatus[0]&LIBF_NOLAUNCHER))weaponstatus[0]|=LIBF_GRENADELOADED;
		weaponstatus[LIBS_MAG]=30;
		weaponstatus[LIBS_RECASTS]=0;
		weaponstatus[LIBS_CHAMBER]=2;
		if(!idfa&&!owner){
			weaponstatus[LIBS_ZOOM]=30;
			weaponstatus[LIBS_HEAT]=0;
			weaponstatus[LIBS_DROPADJUST]=127;
		}
	}
	override void loadoutconfigure(string input){
		int nogl=getloadoutvar(input,"nogl",1);
		//disable launchers if rocket grenades denylisted
		string denylist=hd_noloadout;
		if(denylist.IndexOf(HDLD_BLOOPER)>=0)nogl=1;
		if(!nogl){
			weaponstatus[0]&=~LIBF_NOLAUNCHER;
		}else if(nogl>0){
			weaponstatus[0]|=LIBF_NOLAUNCHER;
			weaponstatus[0]&=~LIBF_GRENADELOADED;
		}
		if(!(weaponstatus[0]&LIBF_NOLAUNCHER))weaponstatus[0]|=LIBF_GRENADELOADED;

		int nobp=getloadoutvar(input,"nobp",1);
		if(!nobp)weaponstatus[0]&=~LIBF_NOBULLPUP;
		else if(nobp>0)weaponstatus[0]|=LIBF_NOBULLPUP;
		if(weaponstatus[0]&LIBF_NOBULLPUP)bfitsinbackpack=false;
		else bfitsinbackpack=true;

		int altreticle=getloadoutvar(input,"altreticle",1);
		if(!altreticle)weaponstatus[0]&=~LIBF_ALTRETICLE;
		else if(altreticle>0)weaponstatus[0]|=LIBF_ALTRETICLE;

		int frontreticle=getloadoutvar(input,"frontreticle",1);
		if(!frontreticle)weaponstatus[0]&=~LIBF_FRONTRETICLE;
		else if(frontreticle>0)weaponstatus[0]|=LIBF_FRONTRETICLE;

		int bulletdrop=getloadoutvar(input,"bulletdrop",3);
		if(bulletdrop>=0)weaponstatus[LIBS_DROPADJUST]=clamp(bulletdrop,0,1200);

		int zoom=getloadoutvar(input,"zoom",3);
		if(zoom>=0)weaponstatus[LIBS_ZOOM]=
			(weaponstatus[0]&LIBF_FRONTRETICLE)?
			clamp(zoom,20,40):
			clamp(zoom,6,70);

		int xhdot=getloadoutvar(input,"dot",3);
		if(xhdot>=0)weaponstatus[LIBS_DOT]=xhdot;

		int firemode=getloadoutvar(input,"firemode",1);
		if(firemode>0)weaponstatus[0]|=LIBF_FULLAUTO;
		else weaponstatus[0]&=~LIBF_FULLAUTO;

		int semi=getloadoutvar(input,"semi",1);
		if(semi>0){
			weaponstatus[0]|=LIBF_NOAUTO;
			weaponstatus[0]&=~LIBF_FULLAUTO;
		}else weaponstatus[0]&=~LIBF_NOAUTO;

		int lefty=getloadoutvar(input,"lefty",1);
		if(
			lefty>0
			||(
				lefty<0
				&&(Wads.CheckNumForName("id",0)!=-1)
			)
		)weaponstatus[0]|=LIBF_LEFTY;
		else weaponstatus[0]&=~LIBF_LEFTY;
	}
}
enum liberatorstatus{
	LIBF_FULLAUTO=1,
	LIBF_JUSTUNLOAD=2,
	LIBF_GRENADELOADED=4,
	LIBF_NOLAUNCHER=8,
	LIBF_FRONTRETICLE=32,
	LIBF_ALTRETICLE=64,
	LIBF_GRENADEMODE=128,
	LIBF_UNLOADONLY=256,
	LIBF_NOBULLPUP=512,
	LIBF_NOAUTO=1024,
	LIBF_LEFTY=2048,
	LIBF_RECAST=4096,

	LIBS_FLAGS=0,
	LIBS_CHAMBER=1,
	LIBS_MAG=2, //-1 is ampty
	LIBS_ZOOM=3,
	LIBS_HEAT=4,
	LIBS_BRASS=5,
	LIBS_AIRBURST=6,
	LIBS_DROPADJUST=7,
	LIBS_DOT=8,
	LIBS_RECASTS=9,
};


class LiberatorNoGL:HDWeaponGiver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Liberator (no GL)"
		//$Sprite "BRFLA0"
		tag "$TAG_LIBNOGL";
		hdweapongiver.bulk (100.+(ENC_776MAG_LOADED+30.*ENC_776_LOADED));
		hdweapongiver.weapontogive "LiberatorRifle";
		hdweapongiver.weprefid HDLD_LIB;
		hdweapongiver.config "noglnobp0";
		inventory.icon "BRFLA0";
	}
}

class LiberatorNoBullpup:HDWeaponGiver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Liberator (Classic)"
		//$Sprite "BRLLB0"
		tag "$TAG_LIB_CLASSIC";
		hdweapongiver.bulk (145.+(ENC_776MAG_LOADED+30.*ENC_776_LOADED)+ENC_ROCKETLOADED);
		hdweapongiver.weapontogive "LiberatorRifle";
		hdweapongiver.config "nogl0nobp";
		inventory.icon "BRLLB0";
	}
}
class LiberatorNoBullpupNoGL:HDWeaponGiver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Liberator (Classic no GL)"
		//$Sprite "BRLLA0"
		tag "$TAG_LIB_CLASSICNOGL";
		hdweapongiver.bulk (120.+(ENC_776MAG_LOADED+30.*ENC_776_LOADED));
		hdweapongiver.weapontogive "LiberatorRifle";
		hdweapongiver.config "noglnobp";
		inventory.icon "BRLLA0";
	}
}

class LiberatorRandom:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let lll=LiberatorRifle(spawn("LiberatorRifle",pos,ALLOW_REPLACE));
			if(!lll)return;
			HDF.TransferSpecials(self,lll);
			if(!random(0,2))lll.weaponstatus[0]|=LIBF_FRONTRETICLE;
			if(!random(0,2))lll.weaponstatus[0]|=LIBF_ALTRETICLE;
			if(!random(0,2))lll.weaponstatus[0]|=LIBF_NOLAUNCHER;
			if(!random(0,3))lll.weaponstatus[0]|=LIBF_NOBULLPUP;
			if(!random(0,5))lll.weaponstatus[0]|=LIBF_NOAUTO;
			if(!random(0,5))lll.weaponstatus[0]|=LIBF_LEFTY;

			if(lll.weaponstatus[0]&LIBF_NOLAUNCHER){
				spawn("HD7mMag",pos+(7,0,0),ALLOW_REPLACE);
				spawn("HD7mMag",pos+(5,0,0),ALLOW_REPLACE);
			}else{
				spawn("HDRocketAmmo",pos+(10,0,0),ALLOW_REPLACE);
				spawn("HDRocketAmmo",pos+(8,0,0),ALLOW_REPLACE);
				spawn("HD7mMag",pos+(5,0,0),ALLOW_REPLACE);
			}
		}stop;
	}
}
