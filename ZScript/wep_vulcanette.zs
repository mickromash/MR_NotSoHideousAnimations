// ------------------------------------------------------------
// Vulcanette
// ------------------------------------------------------------
enum vulcstatus{
	VULCF_FAST=1,
	VULCF_SPINNINGFAST=2,
	VULCF_JUSTUNLOAD=4,
	VULCF_LOADCELL=8,

	VULCF_DIRTYMAG=16,

	VULCS_MAG1=1,
	VULCS_MAG2=2,
	VULCS_MAG3=3,
	VULCS_MAG4=4,
	VULCS_MAG5=5,

	VULCS_CHAMBER1=6,
	VULCS_CHAMBER2=7,
	VULCS_CHAMBER3=8,
	VULCS_CHAMBER4=9,
	VULCS_CHAMBER5=10,

	VULCS_BATTERY=11,
	VULCS_ZOOM=12,
	VULCS_HEAT=13,
	VULCS_BREAKCHANCE=14,
	VULCS_PERMADAMAGE=15,

	VULCS_DOT=16,
};
class Vulcanette:ZM66ScopeHaver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Vulcanette"
		//$Sprite "VULCA0"

		+hdweapon.hinderlegs
		scale 0.8;
		inventory.pickupmessage "$PICKUP_VULC";
		weapon.selectionorder 40;
		weapon.slotnumber 4;
		weapon.slotpriority 1;
		weapon.kickback 24;
		weapon.bobrangex 1.2;
		weapon.bobrangey 1.7;
		weapon.bobspeed 2.1;
		weapon.bobstyle "normal";
		obituary "$OB_VULC";
		hdweapon.barrelsize 30,3,4;
		hdweapon.refid HDLD_VULCETT;
		tag "$TAG_VULC";

		hdweapon.ammo1 "HD4mMag",1;
		hdweapon.ammo2 "HDBattery",1;

		hdweapon.loadoutcodes"
			\cufast - 0/1, whether to start in \"fuller auto\" mode
			\cuzoom - 16-70, 10x the resulting FOV in degrees
			\cudot - 0-5";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override string pickupmessage(){
		int bc=weaponstatus[VULCS_BREAKCHANCE];
		string msg=Stringtable.Localize((bc>100?"$PICKUP_VULC_MEH":"$PICKUP_VULC"));
		if(!bc)return msg..Stringtable.Localize("$PICKUP_VULC_PERFECT");
		else if(bc>500)return msg..Stringtable.Localize("$PICKUP_VULC_BROKEN");
		else if(bc>200)return msg..Stringtable.Localize("$PICKUP_VULC_DAMAGED");
		else if(bc>100)return msg..Stringtable.Localize("$PICKUP_VULC_WORN");
		return msg;
	}
	override void tick(){
		super.tick();
		drainheat(VULCS_HEAT,18);
	}
	override void DoEffect(){
		let hdp=hdplayerpawn(owner);
		if(hdp){
			//droop downwards
			if(
				!hdp.gunbraced
				&&!!hdp.player
				&&hdp.player.readyweapon==self
				&&hdp.strength
				&&hdp.pitch<frandom(5,8)
			)hdp.A_MuzzleClimb((
				frandom(-0.05,0.05),
				frandom(0.1,clamp(1-pitch,0.06/hdp.strength,0.12))
			),(0,0),(0,0),(0,0));
		}
		Super.DoEffect();
	}
	override inventory createtossable(){
		let ctt=vulcanette(super.createtossable());
		if(!ctt)return null;
		if(ctt.bmissile)ctt.weaponstatus[VULCS_BREAKCHANCE]+=random(0,70);
		return ctt;
	}

	override double gunmass(){
		double amt=10+(weaponstatus[VULCS_BATTERY]<0?0:1);
		for(int i=VULCS_MAG1;i<=VULCS_MAG5;i++){
			if(weaponstatus[i]>=0)amt+=3;
		}
		return amt;
	}
	override double weaponbulk(){
		double blx=200+(weaponstatus[VULCS_BATTERY]>=0?ENC_BATTERY_LOADED:0);
		for(int i=VULCS_MAG1;i<=VULCS_MAG5;i++){
			int wsi=weaponstatus[i];
			if(wsi>=0)blx+=ENC_426_LOADED*wsi+ENC_426MAG_LOADED;
		}
		return blx;
	}
	override string,double getpickupsprite(){return "VULCA0",1.;}
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
			sb.drawbattery(-64,-4,sb.DI_SCREEN_CENTER_BOTTOM,reloadorder:true);
			sb.drawnum(hpl.countinv("HD4mMag"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			sb.drawnum(hpl.countinv("HDBattery"),-56,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		bool bat=hdw.weaponstatus[VULCS_BATTERY]>0;
		for(int i=0;i<5;i++){
			if(i>0&&hdw.weaponstatus[VULCS_MAG1+i]>=0)sb.drawrect(-19-i*4,-14,3,2);
			if(hdw.weaponstatus[VULCS_CHAMBER1+i]>0)sb.drawrect(-15,-14+i*2,1,1);
		}
		sb.drawwepnum(
			hdw.weaponstatus[VULCS_MAG1],
			50,posy:-9
		);
		sb.drawwepcounter(hdw.weaponstatus[0]&VULCF_FAST,
			-28,-16,"blank","STFULAUT"
		);
		if(bat){
			int lod=min(50,hdw.weaponstatus[VULCS_MAG1]);
			if(lod>=0&&hdw.weaponstatus[0]&VULCF_DIRTYMAG)lod=random[shitgun](10,99);
			if(lod>=0)sb.drawnum(lod,-20,-22,
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_RED
			);
			sb.drawwepnum(hdw.weaponstatus[VULCS_BATTERY],20);
		}else if(!hdw.weaponstatus[VULCS_BATTERY])sb.drawstring(
			sb.mamountfont,"00000",(-16,-8),
			sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);
		sb.drawnum(hdw.weaponstatus[VULCS_ZOOM],
			-30,-22,
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,
			Font.CR_DARKGRAY
		);
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRESHOOT
		..LWPHELP_RELOAD..StringTable.Localize("$VULWH_RELOAD")
		..LWPHELP_ALTRELOAD..StringTable.Localize("$VULWH_ALTRELOAD")
		..LWPHELP_FIREMODE..StringTable.Localize("$VULWH_SWITCH")..(weaponstatus[0]&VULCF_FAST?"700":"2100")..StringTable.Localize("$VULWH_RPM")
		..LWPHELP_ZOOM.."+"..LWPHELP_FIREMODE.."+"..LWPHELP_UPDOWN..StringTable.Localize("$VULWH_ZPFMODPUD")
		..LWPHELP_ZOOM.."+"..LWPHELP_UNLOAD..StringTable.Localize("$VULWH_ZPUNL")
		..LWPHELP_MAGMANAGER
		..LWPHELP_UNLOADUNLOAD
		..LWPHELP_USE.."+"..LWPHELP_UNLOAD..StringTable.Localize("$VULWH_OR")..LWPHELP_USE.."+"..LWPHELP_ALTRELOAD..StringTable.Localize("$VULWH_UNLBAT")
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int Light = Owner.CurSector.LightLevel*1.75;
		if(owner.player.fixedlightlevel==1)Light = 255;
		double dotoff=max(abs(bob.x),abs(bob.y));
		if(dotoff<40){
			string whichdot=sb.ChooseReflexReticle(hdw.weaponstatus[VULCS_DOT]);
			sb.drawimage(
				whichdot,(0,0)+bob*1.1,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				alpha:0.8-dotoff*0.01,
				col:0xFF000000|sb.crosshaircolor.GetInt()
			);
		}
		sb.drawimage(
			"z66site",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
		);
		if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
		sb.drawimage(
			"z66site",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER, col:Color(254-Light, 0,0,0)
		);
		int scaledyoffset=47;

		if(scopeview)ShowZMScope(hdw.weaponstatus[VULCS_ZOOM],hpc,sb,scaledyoffset,bob);
	}
	override void SetReflexReticle(int which){weaponstatus[VULCS_DOT]=which;}
	override void consolidate(){
		CheckBFGCharge(VULCS_BATTERY);
		if(weaponstatus[VULCS_BREAKCHANCE]>0){
			int bc=weaponstatus[VULCS_BREAKCHANCE];
			if(bc>weaponstatus[VULCS_PERMADAMAGE])weaponstatus[VULCS_PERMADAMAGE]+=max(1,bc>>7);
			int oldbc=bc;
			weaponstatus[VULCS_BREAKCHANCE]=random(bc*2/3,bc)+weaponstatus[VULCS_PERMADAMAGE];
			if(!owner)return;
			string msg="You try to unwarp some of the parts of your Vulcanette";
			if(bc>oldbc)msg=msg..", but only made things worse.";
			else if(bc<oldbc*9/10)msg=msg..". It seems to scroll more smoothly now.";
			else msg=msg..", to little if any avail.";
			owner.A_Log(msg,true);
		}
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("FourMilAmmo"))owner.A_DropInventory("FourMilAmmo",50);
			else{
				owner.angle-=10;
				owner.A_DropInventory("HD4mMag",1);
				owner.angle+=20;
				owner.A_DropInventory("HDBattery",1);
				owner.angle-=10;
			}
		}
	}
	states{
	select0:
		GTLG A 0 A_CheckDefaultReflexReticle(VULCS_DOT);
		goto select0bfg;
	deselect0:
		GTLG A 0;
		goto deselect0bfg;

	ready:
		GTLG A 1{
			A_SetCrosshair(21);
			if(pressingzoom())A_ZoomAdjust(VULCS_ZOOM,16,70);
			else if(justpressed(BT_FIREMODE|BT_ALTFIRE)){
				invoker.weaponstatus[0]^=VULCF_FAST;
				A_StartSound("weapons/fmswitch",CHAN_WEAPON,CHANF_OVERLAP,0.4);
				A_SetHelpText();
				A_WeaponReady(WRF_NONE);
			}else A_WeaponReady(WRF_ALL);
		}
		goto readyend;

	fire:
		GTLG A 1{
			A_WeaponReady(WRF_NONE);
			if(
				invoker.weaponstatus[VULCS_BATTERY]>0 
				&&!random(0,max(0,700-(invoker.weaponstatus[VULCS_BREAKCHANCE]>>1)))
			)invoker.weaponstatus[VULCS_BATTERY]--;
		}goto shoot;
	hold:
		GTLG A 0{
			if(invoker.weaponstatus[VULCS_BATTERY]<1)setweaponstate("nope");
		}
	shoot:
		GTLG A 2{
			A_WeaponReady(WRF_NOFIRE);
			if(
				invoker.weaponstatus[VULCS_BATTERY]>0    
				&&!random(0,invoker.weaponstatus[0]&VULCF_SPINNINGFAST?200:210)
			)invoker.weaponstatus[VULCS_BATTERY]--;
			invoker.weaponstatus[0]&=~VULCF_SPINNINGFAST;

			//check speed and then shoot
			if(
				invoker.weaponstatus[0]&VULCF_FAST
				&&invoker.weaponstatus[VULCS_BATTERY]>=4
				&&invoker.weaponstatus[VULCS_BREAKCHANCE]<random(100,5000)
			){
				A_SetTics(1);
				invoker.weaponstatus[0]|=VULCF_SPINNINGFAST;
			}else if(invoker.weaponstatus[VULCS_BATTERY]<2){
				A_SetTics(random(3,4));
			}else if(invoker.weaponstatus[VULCS_BATTERY]<3){
				A_SetTics(random(2,3));
			}
			VulcShoot();
			VulcNextRound();
		}
		GTLG B 1{
			A_WeaponReady(WRF_NOFIRE);
			//check speed and then shoot
			if(
				invoker.weaponstatus[0]&VULCF_SPINNINGFAST
			){
				A_SetTics(1);
				VulcShoot(true);
				VulcNextRound();
			}else if(invoker.weaponstatus[VULCS_BATTERY]<2){
				A_SetTics(random(3,4));
			}else if(invoker.weaponstatus[VULCS_BATTERY]<3){
				A_SetTics(random(2,3));
			}
		}
		GTLG B 1{
			A_WeaponReady(WRF_NONE);
			if(invoker.weaponstatus[VULCS_BATTERY]<1)setweaponstate("spindown");
			else A_Refire("holdswap");
		}goto spindown;
	holdswap:
		GTLG A 0{
			if(invoker.weaponstatus[VULCS_MAG1]<1){
				VulcNextMag();
				A_StartSound("weapons/vulcshunt",CHAN_WEAPON,CHANF_OVERLAP);
			}
		}goto hold;
	spindown:
		GTLG B 0{
			A_ClearRefire();
			if(!(invoker.weaponstatus[0]&VULCF_SPINNINGFAST))setweaponstate("nope");
			invoker.weaponstatus[0]&=~VULCF_SPINNINGFAST;
		}
		GTLG AB 1{
			A_WeaponReady(WRF_NONE);
			A_MuzzleClimb(frandom(0.4,0.6),-frandom(0.4,0.6));
		}
		GTLG ABAABB 2 A_WeaponReady(WRF_NOFIRE|WRF_NOSWITCH);
		goto ready;


	flash2:
		VULF B 0;
		goto flashfollow;
	flash:
		VULF A 0;
		goto flashfollow;
	flashfollow:
		---- A 0{
			A_MuzzleClimb(0,0,-frandom(0.1,0.3),-frandom(0.4,0.8));
			A_ZoomRecoil(0.99);
			HDFlashAlpha(invoker.weaponstatus[VULCS_HEAT]*48);
			A_WeaponBusy(false);
		}
		---- A 1 bright A_Light2();
		goto lightdone;


	reload:
		GTLG A 0{
			if(PressingZoom())SetWeaponState("CheckMag");
			else if(
				//abort if all mag slots taken or no spare ammo
				(
					invoker.weaponstatus[VULCS_MAG1]>=0
					&&invoker.weaponstatus[VULCS_MAG2]>=0
					&&invoker.weaponstatus[VULCS_MAG3]>=0
					&&invoker.weaponstatus[VULCS_MAG4]>=0
					&&invoker.weaponstatus[VULCS_MAG5]>=0
				)
				||!countinv("HD4mMag")
			)setweaponstate("nope");else{
				invoker.weaponstatus[0]&=~(VULCF_JUSTUNLOAD|VULCF_LOADCELL);
				setweaponstate("lowertoopen");
			}
		}
	altreload:
	cellreload:
		GTLG A 0{
			int batt=invoker.weaponstatus[VULCS_BATTERY];
			if(
				player.cmd.buttons&BT_USE
			){
				invoker.weaponstatus[0]|=VULCF_JUSTUNLOAD;
				invoker.weaponstatus[0]|=VULCF_LOADCELL;
				setweaponstate("lowertoopen");
				return;
			}else if(
				batt<20
				&&countinv("HDBattery")
			){
				invoker.weaponstatus[0]&=~VULCF_JUSTUNLOAD;
				invoker.weaponstatus[0]|=VULCF_LOADCELL;
				setweaponstate("lowertoopen");
				return;
			}
			setweaponstate("nope");
		}
	unload:
		GTLG A 0{
			if(player.cmd.buttons&BT_USE)invoker.weaponstatus[0]|=VULCF_LOADCELL;
			else invoker.weaponstatus[0]&=~VULCF_LOADCELL;
			invoker.weaponstatus[0]|=VULCF_JUSTUNLOAD;
			setweaponstate("lowertoopen");
		}
	//what key to use for cellunload???
	cellunload:
		GTLG A 0{
			//abort if no cell to unload
			if(invoker.weaponstatus[VULCS_BATTERY]<0)
			setweaponstate("nope");else{
				invoker.weaponstatus[0]|=VULCF_JUSTUNLOAD;
				invoker.weaponstatus[0]|=VULCF_LOADCELL;
				setweaponstate("uncell");
			}
		}

	//lower the weapon, open it, decide what to do
	lowertoopen:
		GTLG A 2 offset(0,36);
		GTLG A 2 offset(4,38){
			A_StartSound("weapons/rifleclick2",CHAN_WEAPON);
			A_MuzzleClimb(-frandom(1.2,1.8),-frandom(1.8,2.4));
		}
		GTLG A 6 offset(9,41)A_StartSound("weapons/pocket",CHAN_WEAPON);
		GTLG A 8 offset(12,43)A_StartSound("weapons/vulcopen1",CHAN_WEAPON,CHANF_OVERLAP);
		GTLG A 5 offset(10,41)A_StartSound("weapons/vulcopen2",CHAN_WEAPON,CHANF_OVERLAP);
		GTLG A 0 A_JumpIf(
			invoker.weaponstatus[VULCS_CHAMBER1]<1
			&&invoker.weaponstatus[VULCS_CHAMBER2]<1
			&&invoker.weaponstatus[VULCS_CHAMBER3]<1
			&&invoker.weaponstatus[VULCS_CHAMBER4]<1
			&&invoker.weaponstatus[VULCS_CHAMBER5]<1
			&&invoker.weaponstatus[VULCS_BATTERY]<0
			&&invoker.weaponstatus[VULCS_MAG1]<0
			&&invoker.weaponstatus[VULCS_MAG2]<0
			&&invoker.weaponstatus[VULCS_MAG3]<0
			&&invoker.weaponstatus[VULCS_MAG4]<0
			&&invoker.weaponstatus[VULCS_MAG5]<0
			&&pressingzoom()
			,"openforrepair"
		);
		GTLG A 0{
			if(invoker.weaponstatus[0]&VULCF_LOADCELL)setweaponstate("uncell");
			else if(invoker.weaponstatus[0]&VULCF_JUSTUNLOAD)setweaponstate("unmag");
		}goto loadmag;

	uncell:
		GTLG A 10 offset(11,42){
			int btt=invoker.weaponstatus[VULCS_BATTERY];
			invoker.weaponstatus[VULCS_BATTERY]=-1;
			if(btt<0)setweaponstate("cellout");
			else if(
				!PressingUnload()
				&&!PressingAltReload()
				&&!PressingReload()
			){
				A_SetTics(4);
				HDMagAmmo.SpawnMag(self,"HDBattery",btt);
				
			}else{
				A_StartSound("weapons/pocket",CHAN_WEAPON);
				HDMagAmmo.GiveMag(self,"HDBattery",btt);
			}
		}goto cellout;

	cellout:
		GTLG A 0 offset(10,40) A_JumpIf(invoker.weaponstatus[0]&VULCF_JUSTUNLOAD,"reloadend");
	loadcell:
		GTLG A 0{
			let bbb=HDMagAmmo(findinventory("HDBattery"));
			if(bbb)invoker.weaponstatus[VULCS_BATTERY]=bbb.TakeMag(true);
		}goto reloadend;

	reloadend:
		GTLG A 3 offset(9,41);
		GTLG A 2 offset(6,38);
		GTLG A 3 offset(2,34);
	reloadendend:
		GTLG A 0 A_JumpIf(!pressingreload()&&!pressingunload(),"ready");
		GTLG A 0 A_ReadyEnd();
		GTLG A 1 A_WeaponReady(WRF_NONE);
		loop;


	unchamber:
		GTLG B 4{
			A_StartSound("weapons/vulcextract",CHAN_AUTO,CHANF_DEFAULT,0.3);
			VulcNextRound();
		}GTLG A 4;
		GTLG A 0 A_JumpIf(PressingUnload(),"unchamber");
		goto nope;
	unmag:
		//if no mags, remove battery
		//if not even battery, remove rounds from chambers
		GTLG A 0{
			if(
				invoker.weaponstatus[VULCS_MAG1]<0
				&&invoker.weaponstatus[VULCS_MAG2]<0
				&&invoker.weaponstatus[VULCS_MAG3]<0
				&&invoker.weaponstatus[VULCS_MAG4]<0
				&&invoker.weaponstatus[VULCS_MAG5]<0
			){
				if(invoker.weaponstatus[VULCS_BATTERY]>=0)setweaponstate("cellunload");    
				else setweaponstate("unchamber");
			}
		}
		//first, check if there's a mag2-5.
		//if there's no mag2 but stuff after that, shunt everything over until there is.
		//if there's nothing but mag1, unload mag1.
		GTLG A 6 offset(10,40){
			if(
				!invoker.weaponstatus[0]&VULCF_JUSTUNLOAD
			)setweaponstate("loadmag");
			A_StartSound("weapons/vulcmag",CHAN_WEAPON,CHANF_OVERLAP);
			A_MuzzleClimb(-frandom(1.2,1.8),-frandom(1.8,2.4));
		}
	//remove mag #2 first, #1 only if out of options
	unmagpick:
		GTLG A 0{
			if(invoker.weaponstatus[VULCS_MAG2]>=0)setweaponstate("unmag2");
			else if(
				invoker.weaponstatus[VULCS_MAG3]>=0
				||invoker.weaponstatus[VULCS_MAG4]>=0
				||invoker.weaponstatus[VULCS_MAG5]>=0
			)setweaponstate("unmagshunt");
			else if(
				invoker.weaponstatus[VULCS_MAG1]>=0    
			)setweaponstate("unmag1");
		}goto reloadend;
	unmagshunt:
		GTLG A 0{
			for(int i=VULCS_MAG2;i<VULCS_MAG5;i++){
				invoker.weaponstatus[i]=invoker.weaponstatus[i+1];
			}
			invoker.weaponstatus[VULCS_MAG5]=-1;
			A_StartSound("weapons/vulcshunt",CHAN_WEAPON,CHANF_OVERLAP);
		}
		GTLG AB 2 offset(4,37) A_MuzzleClimb(-frandom(0.4,0.6),frandom(0.4,0.6));
		goto ready;

	unmag2:
		VULC A 0{
			int mg=invoker.weaponstatus[VULCS_MAG2];
			invoker.weaponstatus[VULCS_MAG2]=-1;
			if(mg<0){
				setweaponstate("mag2out");
				return;
			}
			if(
				!PressingUnload()
				&&!PressingReload()
			){
				HDMagAmmo.SpawnMag(self,"HD4mMag",mg);
				setweaponstate("mag2out");
			}else{
				HDMagAmmo.GiveMag(self,"HD4mMag",mg);
				setweaponstate("pocketmag");
			}
		}goto mag2out;
	unmag1:
		VULC A 0{
			int mg=invoker.weaponstatus[VULCS_MAG1];
			invoker.weaponstatus[VULCS_MAG1]=-1;
			if(mg<0){
				setweaponstate("reloadend");
				return;
			}
			if(
				!PressingUnload()
				&&!PressingReload()
			){
				HDMagAmmo.SpawnMag(self,"HD4mMag",mg);
				setweaponstate("mag2out");
			}else{
				HDMagAmmo.GiveMag(self,"HD4mMag",mg);
				setweaponstate("pocketmag");
			}
		}goto reloadend;
	pocketmag:
		GTLG A 0 A_StartSound("weapons/pocket");
		GTLG AA 6 offset(10,40) A_MuzzleClimb(frandom(0.4,0.6),-frandom(0.4,0.6));
		goto mag2out;
	mag2out:
		GTLG A 1 offset(10,40){
			for(int i=VULCS_MAG2;i<VULCS_MAG5;i++){
				invoker.weaponstatus[i]=invoker.weaponstatus[i+1];
			}
			invoker.weaponstatus[VULCS_MAG5]=-1;
			A_StartSound("weapons/vulcshunt",CHAN_WEAPON,CHANF_OVERLAP);
		}
		GTLG AB 2 offset(10,40) A_MuzzleClimb(-frandom(0.4,0.6),frandom(0.4,0.6));
		GTLG A 6 offset(10,40) A_JumpIf(invoker.weaponstatus[VULCS_MAG2]<0,"reloadend");
		goto unmag2;

	loadmag:
		//pick the first empty slot and fill that
		GTLG A 0 A_StartSound("weapons/pocket");
		GTLG AA 6 offset(10,40) A_MuzzleClimb(-frandom(0.4,0.6),frandom(-0.4,0.4));
		GTLG A 6 offset(10,41){
			if(HDMagAmmo.NothingLoaded(self,"HD4mMag")){setweaponstate("reloadend");return;}
			A_StartSound("weapons/vulcmag",CHAN_WEAPON,CHANF_OVERLAP);
			int lod=HDMagAmmo(findinventory("HD4mMag")).TakeMag(true);

			int magslot=-1;
			for(int i=VULCS_MAG1;i<=VULCS_MAG5;i++){
				if(invoker.weaponstatus[i]<0){
					magslot=i;
					break;
				}
			}
			if(magslot<0){
				setweaponstate("reloadend");
				return;
			}

			if(lod<51){
				if(!random(0,7)){
					A_StartSound("weapons/vulcforcemag",CHAN_WEAPON,CHANF_OVERLAP);
					lod=max(0,lod-random(0,1));
					A_Log(StringTable.Localize("$426MAGMSG"),true);
					if(magslot==VULCS_MAG1)invoker.weaponstatus[0]|=VULCF_DIRTYMAG;
				}
			}else if(magslot==VULCS_MAG1)invoker.weaponstatus[0]&=~VULCF_DIRTYMAG;
			invoker.weaponstatus[magslot]=lod;

			A_MuzzleClimb(-frandom(0.4,0.8),-frandom(0.5,0.7));
		}
		GTLG A 8 offset(9,38){
			A_StartSound("weapons/rifleclick",CHAN_WEAPON,CHANF_OVERLAP);
			A_MuzzleClimb(
				-frandom(0.2,0.8),-frandom(0.2,0.3)
				-frandom(0.2,0.8),-frandom(0.2,0.3)
			);
		}
		GTLG A 0{
			if(
				(
					PressingReload()
					||PressingUnload()
					||PressingFire()
					||!countinv("HD4mMag")
				)||(
					invoker.weaponstatus[VULCS_MAG1]>=0
					&&invoker.weaponstatus[VULCS_MAG2]>=0
					&&invoker.weaponstatus[VULCS_MAG3]>=0
					&&invoker.weaponstatus[VULCS_MAG4]>=0
					&&invoker.weaponstatus[VULCS_MAG5]>=0
				)
			)setweaponstate("reloadend");
		}goto loadmag;
		
	CheckMag:
		#### B 2 A_Jumpif(!PressingReload(), "Nope");
		#### # 0 {if(invoker.weaponstatus[VULCS_MAG1]>0)A_Overlay(102, "Dumb");if(Invoker.weaponstatus[VULCS_BATTERY]>0)A_Overlay(103, "Dumb2");
		if(invoker.weaponstatus[VULCS_MAG2]>=0)A_Overlay(104, "Dumb3");}
		Loop;
	Dumb:
		STUP A 0 A_OverLayOffset(102,29,22);
		STUP A 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>4,1);
		Stop;
		STUP B 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>10,1);
		Stop;
		STUP C 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>13,1);
		Stop;
		STUP D 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>16,1);
		Stop;
		STUP E 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>19,1);
		Stop;
		STUP F 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>22,1);
		Stop;
		STUP G 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>25,1);
		Stop;
		STUP H 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>28,1);
		Stop;
		STUP I 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>31,1);
		Stop;
		STUP J 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>34,1);
		Stop;
		STUP K 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>37,1);
		Stop;
		STUP L 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>40,1);
		Stop;
		STUP M 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>43,1);
		Stop;
		STUP N 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG1]>46,1);
		Stop;
		STUP O 5;
		Stop;	
	Dumb2:	
		STUP A 0 A_OverLayOffset(103,29,24);
		STUP A 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>1,1);
		Stop;
		STUP B 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>3,1);
		Stop;
		STUP C 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>4,1);
		Stop;
		STUP D 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>6,1);
		Stop;
		STUP E 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>7,1);
		Stop;
		STUP F 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>9,1);
		Stop;
		STUP G 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>10,1);
		Stop;
		STUP H 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>12,1);
		Stop;
		STUP I 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>14,1);
		Stop;
		STUP J 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>15,1);
		Stop;
		STUP K 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>16,1);
		Stop;
		STUP L 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>17,1);
		Stop;
		STUP M 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>18,1);
		Stop;
		STUP N 5 A_JumpIf(invoker.weaponstatus[VULCS_BATTERY]>19,1);
		Stop;
		STUP O 5;
		Stop;	
	Dumb3:
		STUP A 0 A_OverLayOffset(104,29,20);
		STUP S 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG3]>=0,1);
		Stop;
		STUP T 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG4]>=0,1);
		Stop;
		STUP U 5 A_JumpIf(invoker.weaponstatus[VULCS_MAG5]>=0,1);
		Stop;
		STUP V 5;
		Stop;

	user3:
		VULC A 0 A_MagManager("HD4mMag");
		goto ready;


	openforrepair:
		GTLG A 0{
			let bbb=invoker.weaponstatus[VULCS_BREAKCHANCE];
			string msg="decent in there.";
			if(bbb>400)msg="ready for scrap, to be honest.";
			else if(bbb>150)msg="pretty bad.";
			else if(bbb>40)msg="like it needs some repairs.";
			else if(bbb>0)msg="like it could use a tune-up.";
			A_Log("This Vulcanette looks "..msg,true);
			A_WeaponBusy();
		}
	readytorepair:
		GTLG A 1 offset(11,42){
			if(
				invoker.weaponstatus[VULCS_BREAKCHANCE]<1
				||!pressingzoom()
			){
				setweaponstate("reloadend");
				return;
			}
			if(
				pressingfire()
				||pressingunload()
			){
				if(
					!random(0,23)
					&&invoker.weaponstatus[VULCS_BREAKCHANCE]>0
				){
					invoker.weaponstatus[VULCS_BREAKCHANCE]--;
					A_StartSound("weapons/vulcfix",CHAN_WEAPONBODY,CHANF_OVERLAP);
					VulcRepairMsg();
				}else if(!random(0,95))invoker.weaponstatus[VULCS_PERMADAMAGE]++;
				if(hd_debug)A_Log("Break chance: "..invoker.weaponstatus[VULCS_BREAKCHANCE],true);
				switch(random(0,4)){
				case 1:setweaponstate("tryfix1");break;
				case 2:setweaponstate("tryfix2");break;
				case 3:setweaponstate("tryfix3");break;
				default:setweaponstate("tryfix0");break;
				}
			}
		}wait;
	tryfix0:
		GTLG B 4 offset(10,43)A_StartSound("weapons/vulctryfix",CHAN_WEAPONBODY,CHANF_OVERLAP);
		GTLG A 10 offset(11,42)A_MuzzleClimb(0.3,0.3,-0.3,-0.3,0.3,0.3,-0.3,-0.3);
		goto readytorepair;
	tryfix1:
		GTLG B 0 A_MuzzleClimb(1,1,-1,-1,1,1,-1,-1);
		GTLG B 2 offset(10,43)A_StartSound("weapons/vulcbelt",CHAN_WEAPONBODY,CHANF_OVERLAP);
		GTLG AABBAABABABAABBAABBBAAAA 1 offset(11,44);
		goto readytorepair;
	tryfix2:
		GTLG B 4 offset(11,43)A_MuzzleClimb(frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1));
		GTLG B 10 offset(12,43)A_StartSound("weapons/vulctryfix2",CHAN_WEAPONBODY,CHANF_OVERLAP);
		GTLG A 10 offset(13,45)A_MuzzleClimb(frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1));
		GTLG B 15 offset(14,47)A_MuzzleClimb(frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1),frandom(-1,1));
		GTLG BA 3 offset(12,44)A_StartSound("weapons/vulctryfix2",CHAN_WEAPONBODY,CHANF_OVERLAP);
		GTLG B 10 offset(12,43);
		goto readytorepair;
	tryfix3:
		GTLG B 0 A_MuzzleClimb(1,1,-1,-1,1,1,-1,-1);
		GTLG B 1 offset(11,45);
		GTLG B 1 offset(11,48)A_StartSound("weapons/vulctryfix1",CHAN_WEAPONBODY,CHANF_OVERLAP);
		GTLG B 2 offset(12,54);
		GTLG B 0 A_MuzzleClimb(1,1,-1,-1,1,1,-1,-1);
		GTLG B 4 offset(15,58);
		GTLG B 3 offset(14,56);
		GTLG B 2 offset(12,52);
		GTLG B 1 offset(11,50);
		GTLG B 1 offset(10,48);
		goto readytorepair;


	spawn:
		VULC A -1;
	}


	override void InitializeWepStats(bool idfa){
		weaponstatus[VULCS_BATTERY]=20;
		weaponstatus[VULCS_ZOOM]=30;
		weaponstatus[VULCS_MAG1]=51;
		weaponstatus[VULCS_MAG2]=51;
		weaponstatus[VULCS_MAG3]=51;
		weaponstatus[VULCS_MAG4]=51;
		weaponstatus[VULCS_MAG5]=51;
		int chm=idfa?1:0;
		weaponstatus[VULCS_CHAMBER1]=chm;
		weaponstatus[VULCS_CHAMBER2]=chm;
		weaponstatus[VULCS_CHAMBER3]=chm;
		weaponstatus[VULCS_CHAMBER4]=chm;
		weaponstatus[VULCS_CHAMBER5]=chm;
		weaponstatus[0]&=~VULCF_DIRTYMAG;
	}
	override void loadoutconfigure(string input){
		int fast=getloadoutvar(input,"fast",1);
		if(!fast)weaponstatus[0]&=~VULCF_FAST;
		else if(fast>0)weaponstatus[0]|=VULCF_FAST;

		int zoom=getloadoutvar(input,"zoom",3);
		if(zoom>=0)weaponstatus[VULCS_ZOOM]=clamp(zoom,16,70);

		int xhdot=getloadoutvar(input,"dot",3);
		if(xhdot>=0)weaponstatus[VULCS_DOT]=xhdot;

		if(getage()<1){
			weaponstatus[VULCS_MAG1]=45;
			weaponstatus[VULCS_CHAMBER1]=1;
			weaponstatus[VULCS_CHAMBER2]=1;
			weaponstatus[VULCS_CHAMBER3]=1;
			weaponstatus[VULCS_CHAMBER4]=1;
			weaponstatus[VULCS_CHAMBER5]=1;
		}
	}

	//shooting and cycling actions
	//move this somewhere sensible
	action void VulcShoot(bool flash2=false){
		invoker.weaponstatus[VULCS_BREAKCHANCE]+=random(0,random(0,invoker.weaponstatus[VULCS_HEAT]/256));

		int ccc=invoker.weaponstatus[VULCS_CHAMBER1];
		if(ccc<1)return;
		if(ccc>1){
			invoker.weaponstatus[VULCS_BREAKCHANCE]+=random(0,7);
			if(hd_debug)A_Log("Break chance: "..invoker.weaponstatus[VULCS_BREAKCHANCE]);
			return;
		}

		if(random(random(1,500),5000)<invoker.weaponstatus[VULCS_BREAKCHANCE]){
			setweaponstate("nope");
			return;
		}
		if(!random(0,255))invoker.weaponstatus[VULCS_BREAKCHANCE]++;

		if(flash2)A_GunFlash("flash2");else A_GunFlash("flash");
		A_StartSound("weapons/vulcanette",CHAN_WEAPON,CHANF_OVERLAP);
		A_AlertMonsters();

		double cm=IsMoving.Count(self);if(
			invoker.weaponstatus[0]&VULCF_FAST
		)cm*=hdplayerpawn(self)?2./hdplayerpawn(self).strength:2.;
		double offx=frandom(-0.1,0.1)*cm;
		double offy=frandom(-0.1,0.1)*cm;

		int heat=min(50,invoker.weaponstatus[VULCS_HEAT]);
		HDBulletActor.FireBullet(self,"HDB_426",zofs:height-8,
			spread:heat>20?heat*0.1:0,
			distantsound:"world/vulcfar"
		);
		invoker.weaponstatus[VULCS_HEAT]+=2;

		if(random(0,8192)<min(10,heat))invoker.weaponstatus[VULCS_BATTERY]++;

		invoker.weaponstatus[VULCS_CHAMBER1]=0;
	}
	action void VulcNextRound(){
		int thisch=invoker.weaponstatus[VULCS_CHAMBER1];
		if(thisch>0){
			//spit out a misfired, wasted or broken round
			if(thisch>1){
				for(int i=0;i<5;i++){
					A_SpawnItemEx("TinyWallChunk",3,0,height-18,
						random(4,7),random(-2,2),random(-2,1),
						-30,SXF_NOCHECKPOSITION
					);
				}
			}else{
				A_SpawnItemEx("ZM66DroppedRound",3,0,height-18,
					random(4,7),random(-2,2),random(-2,1),
					-30,SXF_NOCHECKPOSITION
				);
			}
			A_MuzzleClimb(frandom(0.6,2.4),frandom(1.2,2.4));
		}

		//cycle all chambers
		for(int i=VULCS_CHAMBER1;i<VULCS_CHAMBER5;i++){
			invoker.weaponstatus[i]=invoker.weaponstatus[i+1];
		}

		//check if mag is clean
		int inmag=invoker.weaponstatus[VULCS_MAG1];
		if(inmag==51){
			invoker.weaponstatus[VULCS_MAG1]=50; //open the seal
			invoker.weaponstatus[0]&=~VULCF_DIRTYMAG;
			inmag=50;
		}

		//extract a round from the mag
		if(inmag>0){
			invoker.weaponstatus[VULCS_MAG1]--;
			A_StartSound("weapons/vulcchamber",CHAN_WEAPON,CHANF_OVERLAP);
			if(random(0,2000)<=
				1+(invoker.weaponstatus[0]&VULCF_DIRTYMAG?(invoker.weaponstatus[0]&VULCF_FAST?13:9):0)
			)invoker.weaponstatus[VULCS_CHAMBER5]=2;
			else invoker.weaponstatus[VULCS_CHAMBER5]=1;
		}else invoker.weaponstatus[VULCS_CHAMBER5]=0;
	}
	action void VulcNextMag(){
		int thismag=invoker.weaponstatus[VULCS_MAG1];
		if(thismag>=0){
			double cp=cos(pitch);double ca=cos(angle+60);
			double sp=sin(pitch);double sa=sin(angle+60);
			actor mmm=HDMagAmmo.SpawnMag(self,"HD4mMag",thismag);
			mmm.setorigin(pos+(
				cp*ca*16,
				cp*sa*16,
				height-12-12*sp
			),false);
			mmm.vel=vel+(
				cp*cos(angle+random(55,65)),
				cp*sin(angle+random(55,65)),
				sp
			);
		}
		for(int i=VULCS_MAG1;i<VULCS_MAG5;i++){
			invoker.weaponstatus[i]=invoker.weaponstatus[i+1];
		}
		invoker.weaponstatus[VULCS_MAG5]=-1;

		if(invoker.weaponstatus[VULCS_MAG1]<51)invoker.weaponstatus[0]|=VULCF_DIRTYMAG;
	}

	action void VulcRepairMsg(){
		static const string vordinals[]={"first","second","third","fourth","fifth"};
		static const string vverbs[]={"remove some","buff out","realign","secure","grease","grab a spare part to replace","fiddle around and eventually suspect a problem with","forcibly un-warp","reassemble"};
		static const string vdebris[]={"debris","grease","dust","steel filings","powder","blood","pus","hair","dead insects","blueberry jam","cheese puff powder","tiny Bosses"};
		static const string vpart[]={"crank shaft","main gear","magazine feeder","mag scanner head","barrel shroud","cylinder","cylinder feed port","motor power feed","CPU auxiliary power turbine","misfire ejector lug"};
		static const string vpart2[]={"barrel feed port","chamber","extractor","extruder","barrel feed port seal","barrel","transfer gear","firing pin","safety scanner"};

		string msg="You ";
		if(!random(0,3))msg=msg.."attempt to ";
		int which=random(0,vverbs.size()-1);
		msg=msg..vverbs[which].." ";
		if(!which)msg=msg..vdebris[abs(random(1,vdebris.size())-random(1,vdebris.size()))].." from ";
		msg=msg.."the ";

		which=random(0,vpart.size());
		if(which==vpart.size())msg=msg..vordinals[random(0,4)].." "..vpart2[random(0,vpart2.size()-1)];
		else msg=msg..vpart[which];

		A_Log(msg..".",true);
	}
}


