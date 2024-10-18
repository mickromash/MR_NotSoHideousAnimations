// ------------------------------------------------------------
// ZM66 4.26mm UAC Standard Automatic Rifle
// ------------------------------------------------------------
const HDCONST_ZM66COOKOFF=21;
class ZM66ScopeHaver:HDWeapon{
	ui void ShowZMScope(
		int zoomamt,
		actor hpc,
		HDStatusBar sb,
		int scaledyoffset,
		vector2 bob
	){
		double degree=(zoomamt)*0.1;

		int scaledwidth=57;
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		sb.SetClipRect(
			-28+bob.x,19+bob.y,scaledwidth,scaledwidth,
			sb.DI_SCREEN_CENTER
		);

		sb.fill(color(255,0,0,0),
			bob.x-27,scaledyoffset+bob.y-27,
			54,54,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
		);

		texman.setcameratotexture(hpc,"HDXCAM_ZM66",degree);
		let cam  = texman.CheckForTexture("HDXCAM_ZM66",TexMan.Type_Any);
		sb.DrawCircle(cam,(0,scaledyoffset)+bob*3,.075,usePixelRatio:true);

		//This can only work if the hole texture could be offset,
		//and even then the scope picture would not be looking in the right direction.
		//let hole = texman.CheckForTexture("scophole",TexMan.Type_Any);
		//let holeScale = double(texman.GetSize(cam)) / double(texman.GetSize(hole));
		//sb.DrawCircle(hole, (0, scaledyoffset)+bob, .31*holeScale, bob*2, .78);


		sb.SetClipRect(cx,cy,cw,ch);

		int Light = Owner.Cursector.LightLevel * 1.75;
		sb.drawimage(
			"zm66scop",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
			scale:(0.82,0.82)
		);
		if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
		sb.drawimage(
			"zm66blk",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
			scale:(0.82,0.82), col:color(254-Light, 0,0,0)
		);
		sb.drawstring(
			sb.mAmountFont,string.format("%.1f",degree),
			(6+bob.x,74+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
			Font.CR_BLACK
		);
	}
}
class ZM66AssaultRifle:ZM66ScopeHaver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "ZM66 Rifle (All)"
		//$Sprite "RIGLA0"

		+hdweapon.fitsinbackpack
		weapon.selectionorder 20;
		weapon.slotnumber 4;
		weapon.slotpriority 2;
		inventory.pickupsound "misc/w_pkup";
		inventory.pickupmessage "$PICKUP_ZM66";
		scale 0.7;
		weapon.bobrangex 0.2;
		weapon.bobrangey 0.8;
		obituary "$OB_ZM66";
		hdweapon.refid HDLD_ZM66;
		tag "$TAG_ZM66";
		inventory.icon "RIGLA0";

		hdweapon.ammo1 "HD4mMag",1;
		hdweapon.ammo2 "HDRocketAmmo",1;

		hdweapon.loadoutcodes "
			\cunogl - 0/1, whether it has a launcher
			\cusemi - 0/1, whether it has a fire selector enabled
			\cufiremode - 0-2, semi/auto/burst
			\cuzoom - 16-70, 10x the resulting FOV in degrees
			\cudot - 0-5";
	}
	override void tick(){
		super.tick();
		drainheat(ZM66S_HEAT,12);
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override void postbeginplay(){
		super.postbeginplay();
		barrellength=25; //look at the sprites - GL does not extend beyond muzzle
		if(weaponstatus[0]&ZM66F_NOLAUNCHER){
			barrelwidth=0.5;
			barreldepth=1;
			weaponstatus[0]&=~(ZM66F_GLMODE|ZM66F_GRENADELOADED);
		}else{
			barrelwidth=1;
			barreldepth=3;
			bobrangex*=1.05;
			bobrangey*=1.2;
		}
	}
	override double gunmass(){
		if(weaponstatus[0]&ZM66F_NOLAUNCHER){
			return 6.2+weaponstatus[ZM66S_MAG]*0.02;
		}else{
			return 7.7+weaponstatus[ZM66S_MAG]*0.01+(weaponstatus[0]&ZM66F_GRENADELOADED?1.:0.);
		}
	}
	override void GunBounce(){
		super.GunBounce();
		if(!random(0,5))weaponstatus[0]&=~ZM66F_CHAMBERBROKEN;
	}
	override void OnPlayerDrop(){
		if(!random(0,15))weaponstatus[0]|=ZM66F_CHAMBERBROKEN;
		if(owner&&weaponstatus[ZM66S_HEAT]>HDCONST_ZM66COOKOFF)owner.dropinventory(self);
	}
	override string pickupmessage(){
		if(weaponstatus[0]&ZM66F_NOFIRESELECT)return Stringtable.Localize("$PICKUP_SEMIZM66");
		return super.pickupmessage();
	}
	override string,double getpickupsprite(bool usespare){
		string spr;

		int wep0=GetSpareWeaponValue(0,usespare);

		if(wep0&ZM66F_NOLAUNCHER){
			if(wep0&ZM66F_NOFIRESELECT)
				spr="RIFS";
			else spr="RIFL";
		}else{
			if(wep0&ZM66F_NOFIRESELECT)
				spr="RIGS";
			else spr="RIGL";
		}

		//set to no-mag frame
		if(GetSpareWeaponValue(ZM66S_MAG,usespare)<0)spr=spr.."D";
		else spr=spr.."A";

		return spr.."0",1.;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			int nextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD4mMag")));
			if(nextmagloaded>50){
				sb.drawimage("ZMAGA0",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(2,2));
			}else if(nextmagloaded<1){
				sb.drawimage("ZMAGC0",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,alpha:nextmagloaded?0.6:1.,scale:(2,2));
			}else sb.drawbar(
				"ZMAGNORM","ZMAGGREY",
				nextmagloaded,50,
				(-46,-3),-1,
				sb.SHADER_VERT,sb.DI_SCREEN_CENTER_BOTTOM
			);
			sb.drawnum(hpl.countinv("HD4mMag"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			if(!(hdw.weaponstatus[0]&ZM66F_NOLAUNCHER)){
				sb.drawimage("ROQPA0",(-62,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
				sb.drawnum(hpl.countinv("HDRocketAmmo"),-56,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			}
		}

		if(!(hdw.weaponstatus[0]&ZM66F_NOFIRESELECT))
		sb.drawwepcounter(hdw.weaponstatus[ZM66S_AUTO],
			-22,-10,"RBRSA3A7","STFULAUT","STBURAUT"
		);
		if(hdw.weaponstatus[0]&ZM66F_GRENADELOADED)sb.drawrect(-20,-14,4,2.6);
		int lod=clamp(hdw.weaponstatus[ZM66S_MAG]%100,0,50);
		sb.drawwepnum(lod,50);
		if(hdw.weaponstatus[0]&ZM66F_CHAMBER){
			sb.drawrect(-19,-10,3,1);
			lod++;
		}
		if(hdw.weaponstatus[ZM66S_MAG]>100)lod=random[shitgun](10,99);
		sb.drawnum(lod,-16,-22,sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_RED);
		if(hdw.weaponstatus[0]&ZM66F_GLMODE){
			DrawRifleGrenadeStatus(sb,hdw);
		}else sb.drawnum(hdw.weaponstatus[ZM66S_ZOOM],
			-30,-22,sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_DARKGRAY
		);
	}
	override string gethelptext(){
		bool gl=!(weaponstatus[0]&ZM66F_NOLAUNCHER);
		bool glmode=gl&&(weaponstatus[0]&ZM66F_GLMODE);
		LocalizeHelp();
		return
		LWPHELP_FIRESHOOT
		..(gl?(LWPHELP_ALTFIRE..(glmode?(StringTable.Localize("$ZMWH_ALTFIRE1")):(StringTable.Localize("$ZMWH_ALTFIRE2")))):"")
		..LWPHELP_RELOAD..StringTable.Localize("$ZMWH_RELOAD")
		..(gl?(LWPHELP_ALTRELOAD..StringTable.Localize("$ZMWH_ALTRELOAD")):"")
		..(glmode?(LWPHELP_FIREMODE.."+"..LWPHELP_UPDOWN..StringTable.Localize("$ZMWH_FMODPUD"))
			:(
			((weaponstatus[0]&ZM66F_NOFIRESELECT)?"":LWPHELP_FIREMODE..StringTable.Localize("$ZMWH_FMODE"))
			..LWPHELP_ZOOM.."+"..LWPHELP_FIREMODE.."+"..LWPHELP_UPDOWN..StringTable.Localize("$ZMWH_ZPFMOD")))
		..LWPHELP_MAGMANAGER
		..LWPHELP_UNLOAD..StringTable.Localize("$ZMWH_UNLOAD")..(glmode?StringTable.Localize("$ZMWH_GL"):StringTable.Localize("$ZMWH_MAG"))
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int scaledyoffset=47;
		if(hdw.weaponstatus[0]&ZM66F_GLMODE)sb.drawgrenadeladder(hdw.airburst,bob);
		else{
			double dotoff=max(abs(bob.x),abs(bob.y));
			if(dotoff<40){
				string whichdot=sb.ChooseReflexReticle(hdw.weaponstatus[ZM66S_DOT]);
				sb.drawimage(
					whichdot,(0,0)+bob*1.1,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					alpha:0.8-dotoff*0.01,
					col:0xFF000000|sb.crosshaircolor.GetInt()
				);
			}
			int Light = Owner.Cursector.LightLevel * 1.75;
			if(owner.player.fixedlightlevel==1)Light = 255;
			sb.drawimage(
				"z66site",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);
			if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
			sb.drawimage(
				"z66site",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
			col:color(254-Light, 0,0,0));
			if(scopeview)ShowZMScope(hdw.weaponstatus[ZM66S_ZOOM],hpc,sb,scaledyoffset,bob);
		}
	}
	override void SetReflexReticle(int which){weaponstatus[ZM66S_DOT]=which;}
	override double weaponbulk(){
		double blx=90;
		if(!(weaponstatus[0]&ZM66F_NOLAUNCHER)){
			blx+=25;
			if(weaponstatus[0]&ZM66F_GRENADELOADED)blx+=ENC_ROCKETLOADED;
		}
		int mgg=weaponstatus[ZM66S_MAG];
		return blx+(mgg<0?0:(ENC_426MAG_LOADED+mgg*ENC_426_LOADED));
	}
	override void failedpickupunload(){
		failedpickupunloadmag(ZM66S_MAG,"HD4mMag");
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("FourMilAmmo"))owner.A_DropInventory("FourMilAmmo",amt*50);
			else{
				double angchange=(weaponstatus[0]&ZM66F_NOLAUNCHER)?0:-10;
				if(angchange)owner.angle-=angchange;
				owner.A_DropInventory("HD4mMag",amt);
				if(angchange){
					owner.angle+=angchange*2;
					owner.A_DropInventory("HDRocketAmmo",amt);
					owner.angle-=angchange;
				}
			}
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("FourMilAmmo");
		if(weaponstatus[0]&ZM66F_NOLAUNCHER)hdammotype2=null;
		else owner.A_SetInventory("HDRocketAmmo",1);
		ForceOneBasicAmmo("HD4mMag");
	}
	action bool A_CheckCookoff(){
		if(
			invoker.weaponstatus[ZM66S_HEAT]>HDCONST_ZM66COOKOFF
			&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
			&&invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER
		){
			setweaponstate("cookoff");
			return true;
		}
		return false;
	}
	action bool brokenround(){
		if(!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBERBROKEN)){
			int hht=invoker.weaponstatus[ZM66S_HEAT];
			if(hht>240)invoker.weaponstatus[ZM66S_BORESTRETCHED]++;
			hht*=hht;hht>>=10;
			int rnd=
				(invoker.owner?1:10)
				+max(invoker.weaponstatus[ZM66S_AUTO],hht)
				+invoker.weaponstatus[ZM66S_BORESTRETCHED]
				+(invoker.weaponstatus[ZM66S_MAG]>100?10:0);
			if(random(0,2000)<rnd){
				invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_CHAMBERBROKEN;
			}
		}return invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBERBROKEN;
	}
	states{
	ready:
		RIFG A 1{
			if(A_CheckCookoff())return;
			if(pressingzoom())A_ZoomAdjust(ZM66S_ZOOM,16,70);
			else A_WeaponReady(WRF_ALL);
			if(invoker.weaponstatus[ZM66S_AUTO]>2)invoker.weaponstatus[ZM66S_AUTO]=2;
		}goto readyend;
	firemode:
		RIFG A 0 A_JumpIf(invoker.weaponstatus[0]&ZM66F_GLMODE,"abadjust");
		RIFG A 1{
			if(invoker.weaponstatus[0]&ZM66F_NOFIRESELECT){
				invoker.weaponstatus[ZM66S_AUTO]=0;
				return;
			}
			if(invoker.weaponstatus[ZM66S_AUTO]>=2)invoker.weaponstatus[ZM66S_AUTO]=0;
			else invoker.weaponstatus[ZM66S_AUTO]++;
			A_WeaponReady(WRF_NONE);
		}goto nope;


	select0:
		RIFG A 0{
			A_CheckDefaultReflexReticle(ZM66S_DOT);
			invoker.weaponstatus[0]&=~ZM66F_GLMODE;
			if(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER){
				invoker.weaponstatus[0]&=~ZM66F_GRENADELOADED;
				setweaponstate("select0small");
			}
		}goto select0big;
	deselect0:
		RIFG A 0{
			if(
				invoker.weaponstatus[ZM66S_HEAT]>HDCONST_ZM66COOKOFF
				&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				&&(
					invoker.weaponstatus[ZM66S_MAG]||
					invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER
				)
			){
				DropInventory(invoker);
				return;
			}
			if(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER)setweaponstate("deselect0small");
		}goto deselect0big;
	flash:
		RIFF A 1 bright{
			A_Light1();
			HDFlashAlpha(-16);
			A_StartSound("weapons/rifle",CHAN_WEAPON);
			A_ZoomRecoil(max(0.95,1.-0.05*min(invoker.weaponstatus[ZM66S_AUTO],3)));

			//shoot the bullet
			//copypaste any changes to spawnshoot as well!
			double brnd=max(invoker.weaponstatus[ZM66S_HEAT],invoker.weaponstatus[ZM66S_BORESTRETCHED])*0.01;
			HDBulletActor.FireBullet(self,"HDB_426",
				spread:brnd>1.2?brnd:0
			);

			A_MuzzleClimb(
				-frandom(0.1,0.1),-frandom(0,0.1),
				-0.2,-frandom(0.3,0.4),
				-frandom(0.4,1.4),-frandom(1.3,2.6)
			);

			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_CHAMBER;
			invoker.weaponstatus[ZM66S_HEAT]+=random(3,5);
			A_AlertMonsters();
		}
		goto lightdone;


	fire:
		RIFG A 2{
			if(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GLMODE)setweaponstate("firefrag");
			else if(invoker.weaponstatus[ZM66S_AUTO]>0)A_SetTics(3);
		}goto shootgun;
	hold:
		RIFG A 0 A_JumpIf(invoker.weaponstatus[0]&ZM66F_GLMODE,"FireFrag");
		RIFG A 0 A_JumpIf(invoker.weaponstatus[0]&ZM66F_NOFIRESELECT,"nope");
		RIFG A 0 A_JumpIf(invoker.weaponstatus[ZM66S_AUTO]>4,"nope");
		RIFG A 0 A_JumpIf(invoker.weaponstatus[ZM66S_AUTO],"shootgun");
	althold:
		---- A 1{
			if(!A_CheckCookoff())A_WeaponReady(WRF_NOFIRE);
		}
		---- A 0 A_Refire();
		goto ready;
	jam:
		RIFG B 1 offset(-1,36){
			A_StartSound("weapons/riflejam",CHAN_WEAPON,CHANF_OVERLAP);
			invoker.weaponstatus[0]|=ZM66F_CHAMBERBROKEN;
			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_CHAMBER;
		}
		RIFG B 1 offset(1,30) A_StartSound("weapons/riflejam",CHAN_WEAPON,CHANF_OVERLAP);
		goto nope;

	shootgun:
		RIFG A 1{
			if(
				//can neither shoot nor chamber
				invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN
				||(
					!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER)
					&&invoker.weaponstatus[ZM66S_MAG]<1
				)
			){
				setweaponstate("nope");
			}else if(!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER)){
				//no shot but can chamber
				setweaponstate("chamber_manual");
			}else{
				A_GunFlash();
				A_WeaponReady(WRF_NONE);
				if(invoker.weaponstatus[ZM66S_AUTO]>=2)invoker.weaponstatus[ZM66S_AUTO]++;
			}
		}
	chamber:
		RIFG B 0 offset(0,32){
			if(invoker.weaponstatus[ZM66S_MAG]<1){
				setweaponstate("nope");
				return;
			}
			if(invoker.weaponstatus[ZM66S_MAG]%100>0){
				if(invoker.weaponstatus[ZM66S_MAG]==51)invoker.weaponstatus[ZM66S_MAG]=50;
				invoker.weaponstatus[ZM66S_MAG]--;
				invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_CHAMBER;
			}else{
				invoker.weaponstatus[ZM66S_MAG]=min(invoker.weaponstatus[ZM66S_MAG],0);
				A_StartSound("weapons/rifchamber",CHAN_WEAPON,CHANF_OVERLAP);
			}
			if(brokenround()){
				setweaponstate("jam");
				return;
			}
			A_WeaponReady(WRF_NOFIRE); //not WRF_NONE: switch to drop during cookoff
		}
		RIFG B 0 A_CheckCookoff();
		RIFG B 0 A_JumpIf(invoker.weaponstatus[ZM66S_AUTO]<1,"nope");
		RIFG B 0 A_JumpIf(invoker.weaponstatus[ZM66S_AUTO]>4,"nope");
		RIFG B 2 A_JumpIf(invoker.weaponstatus[ZM66S_AUTO]>1,1);
		RIFG B 0 A_Refire();
		goto ready;

	cookoffaltfirelayer:
		TNT1 AAA 1{
			if(JustPressed(BT_ALTFIRE)){
				invoker.weaponstatus[0]^=ZM66F_GLMODE;
				A_SetTics(10);
			}else if(JustPressed(BT_ATTACK)&&invoker.weaponstatus[0]&ZM66F_GLMODE)A_Overlay(11,"nadeflash");
		}stop;
	cookoff:
		RIFG A 0{
			A_ClearRefire();
			if(
				(invoker.weaponstatus[ZM66S_MAG]>=0)	//something to detach
				&&(justpressed(BT_RELOAD)||justpressed(BT_UNLOAD))	//trying to detach
			){
				A_StartSound("weapons/rifleclick2",CHAN_WEAPON,CHANF_OVERLAP);
				A_StartSound("weapons/rifleunload",CHAN_WEAPON,CHANF_OVERLAP);
				HDMagAmmo.SpawnMag(self,"HD4mMag",invoker.weaponstatus[ZM66S_MAG]);
				invoker.weaponstatus[ZM66S_MAG]=-1;
			}else if(!(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER))A_Overlay(10,"cookoffaltfirelayer");
			setweaponstate("shootgun");
		}


	user3:
		RIFG A 0 A_MagManager("HD4mMag");
		goto ready;

	user4:
	unload:
		RIFG A 0{
			invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_UNLOADONLY;
			if(
				invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GLMODE
			){
				setweaponstate("unloadgrenade");
			}else if(
				invoker.weaponstatus[ZM66S_MAG]>=0
			){
				setweaponstate("unloadmag");
			}else if(
				invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER
				||invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBERBROKEN
			){
				setweaponstate("unloadchamber");
			}else{
				setweaponstate("unloadmag");
			}
		}
	reload:
		RIFG A 0{
			if(PressingZoom())SetWeaponState("CheckMag");
			else
			{
			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_UNLOADONLY;
			if(	//full mag, no jam, not unload-only - why hit reload at all?
				!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				&&invoker.weaponstatus[ZM66S_MAG]%100>=50
				&&!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_UNLOADONLY)
			){
				setweaponstate("nope");
			}else if(	//if jammed, treat as unloading
				invoker.weaponstatus[ZM66S_MAG]<0
				&&invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN
			){
				invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_UNLOADONLY;
				setweaponstate("unloadchamber");
			}else if(!HDMagAmmo.NothingLoaded(self,"HD4mMag")){
				setweaponstate("unloadmag");
			}
			}
		}goto nope;
	unloadmag:
		RIFG A 1 offset(0,33);
		RIFG A 1 offset(-3,34);
		RIFG A 1 offset(-8,37);
		RIFG B 2 offset(-11,39){
			if(	//no mag, skip unload
				invoker.weaponstatus[ZM66S_MAG]<0
			){
				setweaponstate("magout");
			}
			if(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_UNLOADONLY;
			A_MuzzleClimb(-0.3,-0.3);
			A_StartSound("weapons/rifleclick2",CHAN_WEAPON,CHANF_OVERLAP);
		}
		RIFG B 4 offset(-12,40){
			A_MuzzleClimb(-0.3,-0.3);
			A_StartSound("weapons/rifleunload",CHAN_WEAPON);
		}
		RIFG B 20 offset(-14,44){
			int inmag=invoker.weaponstatus[ZM66S_MAG];
			if(inmag>51)inmag=min(50,inmag%100);
			invoker.weaponstatus[ZM66S_MAG]=-1;
			if(
				!PressingUnload()&&!PressingReload()
				||A_JumpIfInventory("HD4mMag",0,"null")
			){
				HDMagAmmo.SpawnMag(self,"HD4mMag",inmag);
				A_SetTics(1);
			}else{
				HDMagAmmo.GiveMag(self,"HD4mMag",inmag);
				A_StartSound("weapons/pocket",CHAN_WEAPON);
				if(inmag<51)A_Log(StringTable.Localize("$426MAGMSG"),true);
			}
		}
	magout:
		RIFG B 0{
			if(
				invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_UNLOADONLY
				||!countinv("HD4mMag")
			)setweaponstate("reloadend");
		} //fallthrough to loadmag
	loadmag:
		---- A 12 offset(-15,44){
			let zmag=HD4mMag(findinventory("HD4mMag"));
			if(!zmag){setweaponstate("reloadend");return;}
			A_StartSound("weapons/pocket",CHAN_WEAPON);
			if(zmag.DirtyMagsOnly())invoker.weaponstatus[0]|=ZM66F_LOADINGDIRTY;
			else{
				invoker.weaponstatus[0]&=~ZM66F_LOADINGDIRTY;
				A_SetTics(10);
			}
		}
		---- A 2 offset(-15,44) A_JumpIf(invoker.weaponstatus[0]&ZM66F_LOADINGDIRTY,"loadmagdirty");
	loadmagclean:
		RIFG B 8 offset(-15,45)A_StartSound("weapons/rifleload",CHAN_WEAPON);
		RIFG B 1 offset(-14,44){
			let zmag=HD4mMag(findinventory("HD4mMag"));
			if(!zmag){setweaponstate("reloadend");return;}
			if(zmag.DirtyMagsOnly()){
				setweaponstate("loadmagdirty");
				return;
			}
			invoker.weaponstatus[ZM66S_MAG]=zmag.TakeMag(true);
			A_StartSound("weapons/rifleclick2",CHAN_WEAPON);
		}goto reloadend;
	loadmagdirty:
		RIFG B 0{
			if(PressingReload())invoker.weaponstatus[0]|=ZM66F_STILLPRESSINGRELOAD;
			else invoker.weaponstatus[0]&=~ZM66F_STILLPRESSINGRELOAD;
		}
		RIFG B 3 offset(-15,45)A_StartSound("weapons/rifleload",CHAN_WEAPON);
		RIFG B 1 offset(-15,42)A_WeaponMessage(StringTable.Localize("$ZM426MAGMSG"),70);
		RIFG BBBBBBBAAAA 1 offset(-15,41){
			bool prr=PressingReload();
			if(
				prr
				&&!(invoker.weaponstatus[0]&ZM66F_STILLPRESSINGRELOAD)
			){
				setweaponstate("reallyloadmagdirty");
			}
			else if(!PressingReload())invoker.weaponstatus[0]&=~ZM66F_STILLPRESSINGRELOAD;
		}
		goto nope;
	reallyloadmagdirty:
		RIFG B 1 offset(-14,44)A_StartSound("weapons/rifleclick2",CHAN_WEAPON);
		RIFG A 8 offset(-18,50){
			let zmag=HD4mMag(findinventory("HD4mMag"));
			if(!zmag){setweaponstate("reloadend");return;}
			invoker.weaponstatus[ZM66S_MAG]=zmag.TakeMag(true)+100;
			A_MuzzleClimb(
				-frandom(0.4,0.6),frandom(2.,3.)
				-frandom(0.2,0.3),frandom(1.,1.6)
			);
			A_StartSound("weapons/rifleclick2",CHAN_WEAPON,CHANF_OVERLAP);
			A_StartSound("weapons/smack",CHAN_WEAPON,CHANF_OVERLAP);

			string realmessage=StringTable.Localize("$426MAGMSG");
			realmessage=realmessage.left(random(13,20));
			realmessage.appendformat(StringTable.Localize("$ZMRELERROR")..random(0,9999)..StringTable.Localize("$ZMNOCARRIER"));
			A_WeaponMessage(realmessage,70);
		}
		RIFG A 4 offset(-17,49);
		goto chamber_manual;

	reloadend:
		RIFG B 2 offset(-11,39);
		RIFG A 1 offset(-8,37) A_MuzzleClimb(frandom(0.2,-2.4),frandom(0.2,-1.4));
		RIFG A 0 A_CheckCookoff();
		RIFG A 1 offset(-3,34);
		goto chamber_manual;

	chamber_manual:
		RIFG A 0 A_JumpIf(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER,"nope");
		RIFG A 3 offset(-1,36)A_WeaponBusy();
		RIFG B 4 offset(-3,42){
			if(!invoker.weaponstatus[ZM66S_MAG]%100)invoker.weaponstatus[ZM66S_MAG]=0;
			if(
				!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER)
				&& !(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER)
				&& invoker.weaponstatus[ZM66S_MAG]%100>0
			){
				A_StartSound("weapons/rifleclick",CHAN_WEAPON);
				if(invoker.weaponstatus[ZM66S_MAG]==51)invoker.weaponstatus[ZM66S_MAG]=49;
				else invoker.weaponstatus[ZM66S_MAG]--;
				invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_CHAMBER;
				brokenround();
			}else setweaponstate("nope");
		}
		RIFG A 2 offset(-1,36);
		RIFG A 0 offset(0,34);
		goto nope;


	unloadchamber:
		RIFG A 1 offset(-3,34);
		RIFG A 1 offset(-9,39);
		RIFG B 3 offset(-19,44) A_MuzzleClimb(frandom(-0.4,0.4),frandom(-0.4,0.4));
		RIFG A 2 offset(-16,42){
			A_MuzzleClimb(frandom(-0.4,0.4),frandom(-0.4,0.4));
			if(
				invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER
				&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
			){
				A_SpawnItemEx("ZM66DroppedRound",0,0,20,
					random(4,7),random(-2,2),random(-2,1),0,
					SXF_NOCHECKPOSITION
				);
				invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_CHAMBER;
				A_StartSound("weapons/rifleclick2",CHAN_WEAPON,CHANF_OVERLAP);
			}else if(!random(0,4)){
				invoker.weaponstatus[0]&=~ZM66F_CHAMBERBROKEN;
				invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_CHAMBER;
				A_StartSound("weapons/rifleclick",CHAN_WEAPON,CHANF_OVERLAP);
				for(int i=0;i<5;i++)A_SpawnItemEx("FourMilChunk",0,0,20,
					random(4,7),random(-2,2),random(-2,1),0,SXF_NOCHECKPOSITION
				);
				if(!random(0,5))A_SpawnItemEx("HDSmokeChunk",12,0,gunheight()-10,4,frandom(-2,2),frandom(2,4));
			}else if(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN){
				A_StartSound("weapons/smack",CHAN_WEAPON,CHANF_OVERLAP);
			}
		}goto reloadend;
	
	CheckMag:
		RIFG B 2 A_Jumpif(!PressingReload(), "Nope");
		---- B 0 {if(invoker.weaponstatus[ZM66S_MAG]>0)A_Overlay(102, "Dumb");if(Invoker.weaponstatus[0]&ZM66F_CHAMBER)A_Overlay(103, "Dumb2");}
		Loop;
	Dumb:
		STUP A 0 A_OverLayOffset(102,29,24);
		STUP A 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>4,1);
		Stop;
		STUP B 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>10,1);
		Stop;
		STUP C 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>13,1);
		Stop;
		STUP D 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>16,1);
		Stop;
		STUP E 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>19,1);
		Stop;
		STUP F 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>22,1);
		Stop;
		STUP G 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>25,1);
		Stop;
		STUP H 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>28,1);
		Stop;
		STUP I 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>31,1);
		Stop;
		STUP J 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>34,1);
		Stop;
		STUP K 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>37,1);
		Stop;
		STUP L 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>40,1);
		Stop;
		STUP M 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>43,1);
		Stop;
		STUP N 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>46,1);
		Stop;
		STUP O 5;
		Stop;	
	Dumb2:
		STUP A 0 A_OverLayOffset(103, 32, 22);
		STUP Q 5;
		Stop;	

	firefrag:
		RIFG B 2{
			if(!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GRENADELOADED)){
				setweaponstate("nope");
				return;
			}
			A_FireHDGL();
			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_GRENADELOADED;
			A_StartSound("weapons/grenadeshot",CHAN_WEAPON);
		}
		RIFG B 3{
			A_ZoomRecoil(0.95);
			A_MuzzleClimb(
				0,0,0,0,
				-1.2,-3.,
				-1.,-2.8
			);
		}
		goto nope;


	altfire:
		RIFG A 1 offset(0,34){
			if(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER)return;
			invoker.weaponstatus[0]^=ZM66F_GLMODE;
			invoker.airburst=0;
			A_SetCrosshair(21);
			A_SetHelpText();
		}goto nope;


	altreload:
		RIFG A 0{
			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_UNLOADONLY;
			if(
				!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_NOLAUNCHER)
				&&!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GRENADELOADED)
				&&countinv("HDRocketAmmo")
			)setweaponstate("unloadgrenade");
		}goto nope;
	unloadgrenade:
		RIFG B 0{
			A_SetCrosshair(21);
			A_MuzzleClimb(-0.3,-0.3);
		}
		RIFG B 2 offset(0,34);
		RIFG B 1 offset(4,38){
			A_MuzzleClimb(-0.3,-0.3);
		}
		RIFG B 2 offset(8,48){
			A_StartSound("weapons/grenopen",CHAN_WEAPon,CHANF_OVERLAP);
			A_MuzzleClimb(-0.3,-0.3);
			if(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GRENADELOADED)A_StartSound("weapons/grenreload",CHAN_WEAPON);
		}
		RIFG B 10 offset(10,49){
			if(!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GRENADELOADED)){
				if(!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_UNLOADONLY))A_SetTics(3);
				return;
			}
			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_GRENADELOADED;
			if(
				!PressingUnload()
				||A_JumpIfInventory("HDRocketAmmo",0,"null")
			){
				A_SpawnItemEx("HDRocketAmmo",
					cos(pitch)*10,0,gunheight()-2-10*sin(pitch),vel.x,vel.y,vel.z,0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}else{
				A_StartSound("weapons/pocket",CHAN_WEAPON,CHANF_OVERLAP);
				A_GiveInventory("HDRocketAmmo",1);
				A_MuzzleClimb(frandom(0.8,-0.2),frandom(0.4,-0.2));
			}
		}
		RIFG B 0 A_JumpIf(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_UNLOADONLY,"greloadend");
	loadgrenade:
		RIFG B 4 offset(10,50) A_StartSound("weapons/pocket",CHAN_WEAPON,CHANF_OVERLAP);
		RIFG BBB 8 offset(10,50) A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		RIFG B 18 offset(8,50){
			if(!countinv("HDRocketAmmo"))return;
			A_TakeInventory("HDRocketAmmo",1,TIF_NOTAKEINFINITE);
			invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_GRENADELOADED;
			A_StartSound("weapons/grenreload",CHAN_WEAPON);
		}
	greloadend:
		RIFG B 4 offset(4,44) A_StartSound("weapons/grenopen",CHAN_WEAPON);
		RIFG B 1 offset(0,40);
		RIFG A 1 offset(0,34) A_MuzzleClimb(frandom(-2.4,0.2),frandom(-1.4,0.2));
		goto nope;

	spawn:
		RIFL DCBA 0;
		RIGL DCBA 0;
		RIFS DCBA 0;
		RIGS DA 0;
		---- A 0{
			//don't jam just because
			if(
				!(invoker.weaponstatus[0]&ZM66F_CHAMBER)
				&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				&&invoker.weaponstatus[ZM66S_MAG]>0
				&&invoker.weaponstatus[ZM66S_MAG]<51
			){
				invoker.weaponstatus[ZM66S_MAG]--;
				invoker.weaponstatus[0]|=ZM66F_CHAMBER;
				brokenround();
			}
		}
	spawn2:
		---- A -1{
			//set sprite
			if(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER){
				if(invoker.weaponstatus[0]&ZM66F_NOFIRESELECT)
					sprite=getspriteindex("RIFSA0");
				else sprite=getspriteindex("RIFLA0");
			}else{
				if(invoker.weaponstatus[0]&ZM66F_NOFIRESELECT)
					sprite=getspriteindex("RIGSA0");
				else sprite=getspriteindex("RIGLA0");
			}

			//set to no-mag frame
			if(invoker.weaponstatus[ZM66S_MAG]<0){
				frame=3;
			}

			if(
				invoker.weaponstatus[0]&ZM66F_CHAMBER
				&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				&&invoker.weaponstatus[ZM66S_HEAT]>HDCONST_ZM66COOKOFF
			)setstatelabel("spawnshoot");
		}
	spawnshoot:
		#### C 1 bright light("SHOT"){
			if(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER){
				sprite=getspriteindex("RIFLA0");
			}else sprite=getspriteindex("RIGLA0");

			//shoot the bullet
			//copy any changes to flash as well!
			double brnd=invoker.weaponstatus[ZM66S_HEAT]*0.01;
			let bbb=HDBulletActor.FireBullet(self,"HDB_426",
				spread:brnd>1.2?invoker.weaponstatus[ZM66S_HEAT]*0.1:0
			);

			//if overlapping owner, treat owner as shooter
			let targ=invoker.target;
			if(
				targ
				&&abs(targ.pos.x-invoker.pos.x)<=targ.radius
				&&abs(targ.pos.y-invoker.pos.y)<=targ.radius
			){
				bbb.target=targ;
			}
			A_ChangeVelocity(
				frandom(-0.4,0.1)*cos(pitch),
				frandom(-0.1,0.08),
				sin(pitch)+frandom(-1.,1.),CVF_RELATIVE
			);
			A_StartSound("weapons/rifle",CHAN_VOICE);
			invoker.weaponstatus[ZM66S_HEAT]+=random(3,5);
			angle+=frandom(2,-7);
			pitch+=frandom(-4,4);
		}
		#### B 0{
//			if(invoker.weaponstatus[ZM66S_AUTO]>1)A_SetTics(0);
			invoker.weaponstatus[0]&=~(ZM66F_CHAMBER|ZM66F_CHAMBERBROKEN);
			if(invoker.weaponstatus[ZM66S_MAG]%100>0){
				invoker.weaponstatus[ZM66S_MAG]--;
				invoker.weaponstatus[0]|=ZM66F_CHAMBER;
				brokenround();
			}
		}goto spawn2;
	}

	override inventory CreateTossable(int amt){
		let owner=self.owner;
		let zzz=zm66assaultrifle(super.createtossable());
		if(!zzz)return null;
		zzz.target=owner;
		return zzz;
	}

	override void InitializeWepStats(bool idfa){
		if(!(weaponstatus[0]&ZM66F_NOLAUNCHER))weaponstatus[0]|=ZM66F_GRENADELOADED;
		weaponstatus[ZM66S_MAG]=51;
		if(!idfa && !owner){
			weaponstatus[ZM66S_ZOOM]=30;
			weaponstatus[ZM66S_AUTO]=0;
			weaponstatus[ZM66S_HEAT]=0;
		}
		if(idfa)weaponstatus[0]&=~ZM66F_CHAMBERBROKEN;
	}
	override void loadoutconfigure(string input){
		int nogl=getloadoutvar(input,"nogl",1);
		//disable launchers if rocket grenades denylisted
		string denylist=hd_noloadout;
		if(denylist.IndexOf(HDLD_BLOOPER)>=0)nogl=1;
		if(!nogl){
			weaponstatus[0]&=~ZM66F_NOLAUNCHER;
		}else if(nogl>0){
			weaponstatus[0]|=ZM66F_NOLAUNCHER;
			weaponstatus[0]&=~ZM66F_GRENADELOADED;
		}
		if(!(weaponstatus[0]&ZM66F_NOLAUNCHER)){
			weaponstatus[0]|=ZM66F_GRENADELOADED;
			hdammotype2=null;
		}

		int zoom=getloadoutvar(input,"zoom",3);
		if(zoom>=0)weaponstatus[ZM66S_ZOOM]=clamp(zoom,16,70);

		int xhdot=getloadoutvar(input,"dot",3);
		if(xhdot>=0)weaponstatus[ZM66S_DOT]=xhdot;

		int semi=getloadoutvar(input,"semi",1);
		if(semi>0){
			weaponstatus[ZM66S_AUTO]=-1;
			weaponstatus[0]|=ZM66F_NOFIRESELECT;
		}else{
			int firemode=getloadoutvar(input,"firemode",1);
			if(firemode>=0){
				weaponstatus[0]&=~ZM66F_NOFIRESELECT;
				weaponstatus[ZM66S_AUTO]=clamp(firemode,0,2);
			}
		}
		if(
			!(weaponstatus[0]&ZM66F_CHAMBER)
			&&weaponstatus[ZM66S_MAG]>0
		){
			weaponstatus[0]|=ZM66F_CHAMBER;
			if(weaponstatus[ZM66S_MAG]==51)weaponstatus[ZM66S_MAG]=49;
			else weaponstatus[ZM66S_MAG]--;
		}
	}
}
enum zm66status{
	ZM66F_CHAMBER=1,
	ZM66F_CHAMBERBROKEN=2,
	ZM66F_DIRTYMAG=4,
	ZM66F_GRENADELOADED=8,
	ZM66F_NOLAUNCHER=16,
	ZM66F_NOFIRESELECT=32,
	ZM66F_GLMODE=64,
	ZM66F_UNLOADONLY=128,
	ZM66F_STILLPRESSINGRELOAD=256,
	ZM66F_LOADINGDIRTY=512,

	ZM66S_FLAGS=0,
	ZM66S_MAG=1, //-1 is empty
	ZM66S_AUTO=2, //2 is burst, 2-5 counts ratchet
	ZM66S_ZOOM=3,
	ZM66S_HEAT=4,
	ZM66S_AIRBURST=5,
	ZM66S_BORESTRETCHED=6,
	ZM66S_DOT=7,
};



class ZM66Semi:HDWeaponGiver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "ZM66 Rifle (Semi)"
		//$Sprite "RIFSA0"
		tag "ZM66 assault rifle (semi only)";
		hdweapongiver.bulk (90.+(ENC_426MAG_LOADED+50.*ENC_426_LOADED));
		hdweapongiver.weapontogive "ZM66AssaultRifle";
		hdweapongiver.weprefid HDLD_ZM66;
		hdweapongiver.config "noglsemi";
		inventory.icon "RIFSA0";
	}
}
class ZM66Regular:ZM66Semi{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "ZM66 Rifle (No GL)"
		//$Sprite "RIFLA0"
		tag "ZM66 assault rifle (no GL)";
		hdweapongiver.config "noglsemi0";
		inventory.icon "RIFLA0";
	}
}
class ZM66Irregular:ZM66Semi{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "ZM66 Rifle (Semi GL)"
		//$Sprite "RIGSA0"
		tag "ZM66 assault rifle (semi with GL)";
		hdweapongiver.config "nogl0semi";
		inventory.icon "RIGSA0";
	}
}
class ZM66Random:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let zzz=ZM66AssaultRifle(spawn("ZM66AssaultRifle",pos,ALLOW_REPLACE));
			if(!zzz)return;
			zzz.special=special;
			for(int i=0;i<5;i++)zzz.args[i]=args[i];
			if(!random(0,2)){
				zzz.weaponstatus[0]|=ZM66F_NOLAUNCHER;
				if(!random(0,3))zzz.weaponstatus[0]|=ZM66F_NOFIRESELECT;
			}
			if(zzz.weaponstatus[0]&ZM66F_NOLAUNCHER){
				spawn("HD4mMag",pos+(7,0,0),ALLOW_REPLACE);
				spawn("HD4mMag",pos+(5,0,0),ALLOW_REPLACE);
			}else{
				spawn("HDRocketAmmo",pos+(10,0,0),ALLOW_REPLACE);
				spawn("HDRocketAmmo",pos+(8,0,0),ALLOW_REPLACE);
				spawn("HD4mMag",pos+(5,0,0),ALLOW_REPLACE);
			}
		}stop;
	}
}


//just for testing cookoff effects
class ZM66CookOff:Inventory{
	override void AttachToOwner(actor other){
		let zzz=ZM66AssaultRifle(other.findinventory("ZM66AssaultRifle"));
		zzz.weaponstatus[0]&=~ZM66F_CHAMBERBROKEN;
		zzz.weaponstatus[0]|=ZM66F_CHAMBER;
		zzz.weaponstatus[ZM66S_HEAT]=99;
		zzz.weaponstatus[ZM66S_MAG]=50;
		destroy();
	}
}

class FourMilChunk:WallChunk{
	default{scale 0.12;translation "ZMRound";}
}
