// ------------------------------------------------------------
// SMG
// ------------------------------------------------------------
class HDSMG:HDWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "SMG"
		//$Sprite "SMGNA0"

		+hdweapon.fitsinbackpack
		obituary "$OB_SMG";
		weapon.selectionorder 24;
		weapon.slotnumber 2;
		weapon.slotpriority 1;
		weapon.kickback 30;
		weapon.bobrangex 0.3;
		weapon.bobrangey 0.8;
		weapon.bobspeed 2.5;
		scale 0.55;
		inventory.pickupmessage "$PICKUP_SMG";
		hdweapon.barrelsize 26,0.5,1;
		hdweapon.refid HDLD_SMG;
		tag "$TAG_SMG";
		inventory.icon "SMGNA0";

		hdweapon.ammo1 "HD9mMag30",1;

		hdweapon.loadoutcodes "
			\cufiremode - 0-2, semi/burst/auto
			\cufireswitch - 0-4, default/semi/auto/full/all
			\cureflexsight - 0-1, no/yes
			\cudot - 0-5";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override double gunmass(){
		return 5+((weaponstatus[SMGS_MAG]<0)?-0.5:(weaponstatus[SMGS_MAG]*0.05));
	}
	override double weaponbulk(){
		int mg=weaponstatus[SMGS_MAG];
		if(mg<0)return 90;
		else return (90+ENC_9MAG30_LOADED)+mg*ENC_9_LOADED;
	}
	override void failedpickupunload(){
		failedpickupunloadmag(SMGS_MAG,"HD9mMag30");
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("HDPistolAmmo"))owner.A_DropInventory("HDPistolAmmo",amt*30);
			else owner.A_DropInventory("HD9mMag30",amt);
		}
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(weaponstatus[SMGS_AUTO]>0){
		switch(weaponstatus[SMGS_SWITCHTYPE]){
		case 1:
			weaponstatus[SMGS_AUTO]=0;
			break;
		case 2:
			weaponstatus[SMGS_AUTO]=1;
			break;
		case 3:
			weaponstatus[SMGS_AUTO]=2;
			break;
		default:
			break;
		}}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("HDPistolAmmo");
		ForceOneBasicAmmo("HD9mMag30");
	}
	override string,double getpickupsprite(bool usespare){
		int wep0=GetSpareWeaponValue(0,usespare);
		return ((wep0&SMGF_REFLEXSIGHT)?"SMSN":"SMGN")
			..((GetSpareWeaponValue(SMGS_MAG,usespare)<0)?"B":"A").."0",1.;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			int nextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD9mMag30")));
			if(nextmagloaded>=30){
				sb.drawimage("CLP3A0",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(3,3));
			}else if(nextmagloaded<1){
				sb.drawimage("CLP3B0",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,alpha:nextmagloaded?0.6:1.,scale:(3,3));
			}else sb.drawbar(
				"CLP3NORM","CLP3GREY",
				nextmagloaded,30,
				(-46,-3),-1,
				sb.SHADER_VERT,sb.DI_SCREEN_CENTER_BOTTOM
			);
			sb.drawnum(hpl.countinv("HD9mMag30"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(weaponstatus[SMGS_SWITCHTYPE]!=1)sb.drawwepcounter(hdw.weaponstatus[SMGS_AUTO],
			-22,-10,"RBRSA3A7","STBURAUT","STFULAUT"
		);
		sb.drawwepnum(hdw.weaponstatus[SMGS_MAG],30);
		if(hdw.weaponstatus[SMGS_CHAMBER]==2)sb.drawrect(-19,-11,3,1);
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRESHOOT
		..LWPHELP_RELOAD..StringTable.Localize("$SMGWH_FIRE")
		..LWPHELP_USE.."+"..LWPHELP_RELOAD..StringTable.Localize("$SMGWH_UPRELOAD")
		..LWPHELP_FIREMODE..StringTable.Localize("$SMGWH_FMODE")
		..LWPHELP_MAGMANAGER
		..LWPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		vector2 bobb=bob*1.18;
		if(weaponstatus[0]&SMGF_REFLEXSIGHT){
			double dotoff=max(abs(bob.x),abs(bob.y));
			if(dotoff<30){
				string whichdot=sb.ChooseReflexReticle(hdw.weaponstatus[SMGS_DOT]);
				sb.drawimage(
					whichdot,(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					alpha:0.8-dotoff*0.01,scale:(1.6,1.6),
					col:0xFF000000|sb.crosshaircolor.GetInt()
				);
			}
			sb.drawimage(
				"smgrearsight",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);
		}else{
			int cx,cy,cw,ch;
			[cx,cy,cw,ch]=screen.GetClipRect();
			sb.SetClipRect(
				-16+bob.x,-4+bob.y,32,16,
				sb.DI_SCREEN_CENTER
			);
			sb.drawimage(
				"smgfrntsit",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
			);
			sb.SetClipRect(cx,cy,cw,ch);
			sb.drawimage(
				"smgbaksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
				alpha:0.9
			);
		}
	}
	override void SetReflexReticle(int which){weaponstatus[SMGS_DOT]=which;}
	action void A_CheckReflexSight(){
		if(
			invoker.weaponstatus[0]&SMGF_REFLEXSIGHT
		)Player.GetPSprite(PSP_WEAPON).sprite=getspriteindex("SMSGA0");
		else Player.GetPSprite(PSP_WEAPON).sprite=getspriteindex("SMGGA0");
	}
	states{
	select0:
		SMGG A 0 A_CheckDefaultReflexReticle(SMGS_DOT);
		SMGG A 0 A_CheckReflexSight();
		goto select0small;
	deselect0:
		SMGG A 0 A_CheckReflexSight();
		goto deselect0small;
		SMGG AB 0;
		SMSG AB 0;

	ready:
		SMGG A 0 A_CheckReflexSight();
		#### A 1{
			A_SetCrosshair(21);
			invoker.weaponstatus[SMGS_RATCHET]=0;
			A_WeaponReady(WRF_ALL);
		}
		goto readyend;
	user3:
		---- A 0 A_MagManager("HD9mMag30");
		goto ready;
	altfire:
		goto chamber_manual;
	althold:
		goto nope;
	hold:
		#### A 0{
			if(
				invoker.weaponstatus[SMGS_CHAMBER]==2  //live round chambered
				&&(
					invoker.weaponstatus[SMGS_AUTO]==2  //full auto
					||(
						invoker.weaponstatus[SMGS_AUTO]==1  //burst
						&&invoker.weaponstatus[SMGS_RATCHET]<=2
					)
				)
			)setweaponstate("fire2");
		}goto nope;
	user2:
	firemode:
		---- A 1{
			int canaut=invoker.weaponstatus[SMGS_SWITCHTYPE];
			if(canaut==1){
				invoker.weaponstatus[SMGS_AUTO]=0;
				return;
			}
			int maxmode=(canaut>0)?(canaut-1):2;
			int aut=invoker.weaponstatus[SMGS_AUTO];
			if(aut>=maxmode)invoker.weaponstatus[SMGS_AUTO]=0;
			else if(aut<0)invoker.weaponstatus[SMGS_AUTO]=0;
			else if(canaut>0)invoker.weaponstatus[SMGS_AUTO]=maxmode;
			else invoker.weaponstatus[SMGS_AUTO]++;
		}goto nope;
	fire:
		#### A 0;
	fire2:
		#### B 1{
			if(invoker.weaponstatus[SMGS_CHAMBER]==2)A_GunFlash();
			else setweaponstate("chamber_manual");
		}
		#### A 1;
		#### A 0{
			if(invoker.weaponstatus[SMGS_CHAMBER]==1){
				A_EjectCasing("HDSpent9mm",
					frandom(-1,2),
					(frandom(0.2,0.3),-frandom(7,7.5),frandom(0,0.2)),
					(0,0,-2)
				);
				invoker.weaponstatus[SMGS_CHAMBER]=0;
			}
			if(invoker.weaponstatus[SMGS_MAG]>0){
				invoker.weaponstatus[SMGS_MAG]--;
				invoker.weaponstatus[SMGS_CHAMBER]=2;
			}
			if(invoker.weaponstatus[SMGS_AUTO]==2)A_SetTics(1);
		}
		#### A 0 A_ReFire();
		goto ready;
	flash:
		#### B 0{
			let bbb=HDBulletActor.FireBullet(self,"HDB_9",speedfactor:1.1);
			if(
				frandom(16,ceilingz-floorz)<bbb.speed*0.1
			)A_AlertMonsters(200);

			A_ZoomRecoil(0.995);
			A_StartSound("weapons/smg",CHAN_WEAPON,volume:0.7);
			invoker.weaponstatus[SMGS_RATCHET]++;
			invoker.weaponstatus[SMGS_CHAMBER]=1;
		}
		SMGF A 1 bright{
			HDFlashAlpha(-200);
			A_Light1();
		}
		TNT1 A 0 A_MuzzleClimb(-frandom(0.2,0.24),-frandom(0.3,0.36),-frandom(0.2,0.24),-frandom(0.3,0.36));
		goto lightdone;


	unloadchamber:
		#### B 4 A_JumpIf(invoker.weaponstatus[SMGS_CHAMBER]<1,"nope");
		#### B 10{
			class<actor>which=invoker.weaponstatus[SMGS_CHAMBER]>1?"HDPistolAmmo":"HDSpent9mm";
			invoker.weaponstatus[SMGS_CHAMBER]=0;
			A_SpawnItemEx(which,
				cos(pitch)*10,0,height*0.82-sin(pitch)*10,
				vel.x,vel.y,vel.z,
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
		}goto readyend;
	loadchamber:
		---- A 0 A_JumpIf(invoker.weaponstatus[SMGS_CHAMBER]>0,"nope");
		---- A 0 A_JumpIf(!countinv("HDPistolAmmo"),"nope");
		---- A 1 offset(0,34) A_StartSound("weapons/pocket",9);
		---- A 1 offset(2,36);
		---- A 1 offset(2,44);
		#### B 1 offset(5,58);
		#### B 2 offset(7,70);
		#### B 6 offset(8,80);
		#### A 10 offset(8,87){
			if(countinv("HDPistolAmmo")){
				A_TakeInventory("HDPistolAmmo",1,TIF_NOTAKEINFINITE);
				invoker.weaponstatus[SMGS_CHAMBER]=2;
				A_StartSound("weapons/smgchamber",8);
			}else A_SetTics(4);
		}
		#### A 3 offset(9,76);
		---- A 2 offset(5,70);
		---- A 1 offset(5,64);
		---- A 1 offset(5,52);
		---- A 1 offset(5,42);
		---- A 1 offset(2,36);
		---- A 2 offset(0,34);
		goto nope;
	user4:
	unload:
		#### A 0{
			invoker.weaponstatus[0]|=SMGF_JUSTUNLOAD;
			if(
				invoker.weaponstatus[SMGS_MAG]>=0
			)setweaponstate("unmag");
			else if(invoker.weaponstatus[SMGS_CHAMBER]>0)setweaponstate("unloadchamber");
		}goto nope;
	reload:
		#### A 0{
			if(PressingZoom())SetWeaponState("CheckMag");
			Else
			{
			invoker.weaponstatus[0]&=~SMGF_JUSTUNLOAD;
			bool nomags=HDMagAmmo.NothingLoaded(self,"HD9mMag30");
			if(invoker.weaponstatus[SMGS_MAG]>=30)setweaponstate("nope");
			else if(
				invoker.weaponstatus[SMGS_MAG]<1
				&&(
					pressinguse()
					||nomags
				)
			){
				if(
					countinv("HDPistolAmmo")
				)setweaponstate("loadchamber");
				else setweaponstate("nope");
			}else if(nomags)setweaponstate("nope");
			}
		}goto unmag;
	unmag:
		#### A 1 offset(0,34) A_SetCrosshair(21);
		#### A 1 offset(5,38);
		#### A 1 offset(10,42);
		#### B 2 offset(20,46) A_StartSound("weapons/smgmagclick",8);
		#### B 4 offset(30,52){
			A_MuzzleClimb(0.3,0.4);
			A_StartSound("weapons/smgmagmove",8,CHANF_OVERLAP);
		}
		#### B 0{
			int magamt=invoker.weaponstatus[SMGS_MAG];
			if(magamt<0){
				setweaponstate("magout");
				return;
			}
			invoker.weaponstatus[SMGS_MAG]=-1;
			if(
				(!PressingUnload()&&!PressingReload())
				||A_JumpIfInventory("HD9mMag30",0,"null")
			){
				HDMagAmmo.SpawnMag(self,"HD9mMag30",magamt);
				setweaponstate("magout");
			}else{
				HDMagAmmo.GiveMag(self,"HD9mMag30",magamt);
				A_StartSound("weapons/pocket",9);
				setweaponstate("pocketmag");
			}
		}
	pocketmag:
		#### BB 7 offset(34,54) A_MuzzleClimb(frandom(0.2,-0.8),frandom(-0.2,0.4));
	magout:
		#### B 0{
			if(invoker.weaponstatus[0]&SMGF_JUSTUNLOAD)setweaponstate("reloadend");
			else setweaponstate("loadmag");
		}

	loadmag:
		#### B 0 A_StartSound("weapons/pocket",9);
		#### B 6 offset(34,54) A_MuzzleClimb(frandom(0.2,-0.8),frandom(-0.2,0.4));
		#### B 7 offset(34,52) A_MuzzleClimb(frandom(0.2,-0.8),frandom(-0.2,0.4));
		#### B 10 offset(32,50);
		#### B 3 offset(32,49){
			let mmm=hdmagammo(findinventory("HD9mMag30"));
			if(mmm){
				invoker.weaponstatus[SMGS_MAG]=mmm.TakeMag(true);
				A_StartSound("weapons/smgmagclick",8,CHANF_OVERLAP);
			}
			if(
				invoker.weaponstatus[SMGS_MAG]<1
				||invoker.weaponstatus[SMGS_CHAMBER]>0
			)setweaponstate("reloadend");
		}
		goto reloadend;

	reloadend:
		#### B 3 offset(30,52);
		#### B 2 offset(20,46);
		#### A 1 offset(10,42);
		#### A 1 offset(5,38);
		#### A 1 offset(0,34);
		goto chamber_manual;

	chamber_manual:
		#### A 0 A_JumpIf(
			invoker.weaponstatus[SMGS_MAG]<1
			||invoker.weaponstatus[SMGS_CHAMBER]==2
		,"nope");
		#### B 2 offset(3,32){
			A_WeaponBusy();
			invoker.weaponstatus[SMGS_MAG]--;
			invoker.weaponstatus[SMGS_CHAMBER]=2;
		}
		#### B 3 offset(5,35) A_StartSound("weapons/smgchamber",8,CHANF_OVERLAP);
		#### A 1 offset(3,32);
		#### A 1 offset(2,31);
		goto nope;
		
	CheckMag:
		#### B 2 A_Jumpif(!PressingReload(), "Nope");
		#### B 0 {if(invoker.weaponstatus[SMGS_MAG]>0)A_Overlay(102, "Dumb");if(Invoker.weaponstatus[SMGS_CHAMBER] == 2)A_Overlay(103, "Dumb2");}
		Loop;
	Dumb:
		STUP A 0 A_OverLayOffset(102,29,24);
		STUP A 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>2,1);
		Stop;
		STUP B 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>4,1);
		Stop;
		STUP C 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>6,1);
		Stop;
		STUP D 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>8,1);
		Stop;
		STUP E 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>10,1);
		Stop;
		STUP F 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>12,1);
		Stop;
		STUP G 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>14,1);
		Stop;
		STUP H 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>16,1);
		Stop;
		STUP I 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>18,1);
		Stop;
		STUP J 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>20,1);
		Stop;
		STUP K 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>22,1);
		Stop;
		STUP L 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>24,1);
		Stop;
		STUP M 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>26,1);
		Stop;
		STUP N 5 A_JumpIf(invoker.weaponstatus[ZM66S_MAG]>28,1);
		Stop;
		STUP O 5;
		Stop;	
	
	Dumb2:
		STUP A 0 A_OverLayOffset(103, 32, 22);
		STUP Q 5;
		Stop;		


	spawn:
		TNT1 A 1;
		SMGN A -1{
			if(invoker.weaponstatus[SMGS_MAG]<0)frame=1;
			if(
				invoker.weaponstatus[0]&SMGF_REFLEXSIGHT
			)invoker.sprite=getspriteindex("SMSNA0");
		}
		SMSN # -1;
		stop;
	}
	override void initializewepstats(bool idfa){
		weaponstatus[SMGS_MAG]=30;
		weaponstatus[SMGS_CHAMBER]=2;
	}
	override void loadoutconfigure(string input){
		int firemode=getloadoutvar(input,"firemode",1);
		if(firemode>=0)weaponstatus[SMGS_AUTO]=clamp(firemode,0,2);

		int xhdot=getloadoutvar(input,"dot",3);
		int reflexsight=getloadoutvar(input,"reflexsight",1);
		if(
			!reflexsight
			&&xhdot<0
		)weaponstatus[0]&=~SMGF_REFLEXSIGHT;
		else{
			weaponstatus[0]|=SMGF_REFLEXSIGHT;
			if(xhdot>=0)weaponstatus[SMGS_DOT]=xhdot;
		}

		int fireswitch=getloadoutvar(input,"fireswitch",1);
		if(fireswitch>3)weaponstatus[SMGS_SWITCHTYPE]=0;
		else if(fireswitch>0)weaponstatus[SMGS_SWITCHTYPE]=clamp(fireswitch,0,3);
	}
}
enum smgstatus{
	SMGF_JUSTUNLOAD=1,
	SMGF_REFLEXSIGHT=2,

	SMGN_SEMIONLY=1,
	SMGN_BURSTONLY=2,
	SMGN_FULLONLY=3,

	SMGS_FLAGS=0,
	SMGS_MAG=1,
	SMGS_CHAMBER=2, //0 empty, 1 spent, 2 loaded
	SMGS_AUTO=3, //0 semi, 1 burst, 2 auto
	SMGS_RATCHET=4,
	SMGS_SWITCHTYPE=5,
	SMGS_DOT=6,
};

class HDSMGRandom:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let lll=HDSMG(spawn("HDSMG",pos,ALLOW_REPLACE));
			if(!lll)return;
			lll.special=special;
			lll.vel=vel;
			for(int i=0;i<5;i++)lll.args[i]=args[i];
			if(!random(0,2))lll.weaponstatus[0]|=SMGF_REFLEXSIGHT;
			if(!random(0,2))lll.weaponstatus[SMGS_SWITCHTYPE]=random(0,3);
		}stop;
	}
}

