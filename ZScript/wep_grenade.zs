// ------------------------------------------------------------
// GRENADE!
// ------------------------------------------------------------
class HDGrenadeThrower:HDWeapon{
	class<inventory> grenadeammotype;
	property ammotype:grenadeammotype;
	class<actor> throwtype;
	property throwtype:throwtype;
	class<actor> spoontype;
	property spoontype:spoontype;
	class<weapon> wiretype;
	property wiretype:wiretype;
	string pinsound;
	property pinsound:pinsound;
	string spoonsound;
	property spoonsound:spoonsound;
	default{
		+weapon.no_auto_switch +weapon.noalert +weapon.wimpy_weapon
		+hdweapon.dontdisarm
		+hdweapon.dontnull
		+nointeraction
		weapon.bobstyle "Alpha";
		weapon.bobspeed 2.5;
		weapon.bobrangex 0.1;
		weapon.bobrangey 0.5;

		//adding the frag grenade defaults here to prevent needless crashes
		hdgrenadethrower.ammotype "HDFragGrenadeAmmo";
		hdgrenadethrower.throwtype "HDFragGrenade";
		hdgrenadethrower.spoontype "HDFragSpoon";
		hdgrenadethrower.wiretype "TripwireFrag";
		hdgrenadethrower.pinsound "weapons/fragpinout";
		hdgrenadethrower.spoonsound "weapons/fragspoonoff";
	}
	override void DoEffect(){
		if(weaponstatus[0]&FRAGF_SPOONOFF){
			weaponstatus[FRAGS_TIMER]++;
			if(
				owner.health<1
				||weaponstatus[FRAGS_TIMER]>136
			)TossGrenade(true);
		}else if(
			weaponstatus[0]&FRAGF_INHAND
			&&weaponstatus[0]&FRAGF_PINOUT
			&&owner.player.cmd.buttons&BT_ATTACK
			&&owner.player.cmd.buttons&BT_ALTFIRE
			&&!(owner.player.oldbuttons&BT_ALTFIRE)
		){
			StartCooking();
		}
		super.doeffect();
	}
	override string,double getpickupsprite(){return "FRAGA0",0.6;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage(
				(weaponstatus[0]&FRAGF_SPOONOFF)?"FRAGB0D0":
				(weaponstatus[0]&FRAGF_PINOUT)?"FRAGF0":"FRAGA0",
				(-52,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6)
			);
			sb.drawnum(hpl.countinv("HDFragGrenadeAmmo"),-45,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		sb.drawwepnum(
			hpl.countinv("HDFragGrenadeAmmo"),
			(HDCONST_MAXPOCKETSPACE/ENC_FRAG)
		);
		sb.drawwepnum(hdw.weaponstatus[FRAGS_FORCE],50,posy:-10,alwaysprecise:true);
		if(!(hdw.weaponstatus[0]&FRAGF_SPOONOFF)){
			sb.drawrect(-21,-19,5,4);
			if(!(hdw.weaponstatus[0]&FRAGF_PINOUT))sb.drawrect(-25,-18,3,2);
		}else{
			int timer=hdw.weaponstatus[FRAGS_TIMER];
			if(timer%3)sb.drawwepnum(140-timer,140,posy:-15,alwaysprecise:true);
		}
	}
	override string gethelptext(){
		LocalizeHelp();
		if(weaponstatus[0]&FRAGF_SPOONOFF)return
		LWPHELP_FIRE..StringTable.Localize("$GRENWH_FIRE1")..WEPHELP_RGCOL..")";
		return
		LWPHELP_FIRE..StringTable.Localize("$GRENWH_FIRE2")
		..LWPHELP_ALTFIRE..StringTable.Localize("$GRENWH_ALTFIRE")
		..LWPHELP_RELOAD..StringTable.Localize("$GRENWH_RELOAD")
		..LWPHELP_ZOOM..StringTable.Localize("$GRENWH_ZOOM")
		;
	}
	override inventory CreateTossable(int amt){
		ReturnHandToOwner();
		owner.A_DropInventory(grenadeammotype,owner.countinv(grenadeammotype));
		owner.A_GiveInventory("HDFist");
		owner.A_SelectWeapon("HDFist");
		return null;
	}
	override void InitializeWepStats(bool idfa){
		//if(idfa)owner.A_SetInventory(grenadeammotype,max(3,owner.countinv(grenadeammotype)));
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			owner.A_DropInventory(grenadeammotype,1);
		}
	}
	override void ForceBasicAmmo(){
		owner.A_SetInventory(grenadeammotype,1);
	}
	//for involuntary dropping
	override void OnPlayerDrop(){
		if(
			weaponstatus[0]&FRAGF_SPOONOFF
			||weaponstatus[0]&FRAGF_PINOUT
		)TossGrenade(true);
	}
	void DropGrenade(){
		if(
			weaponstatus[0]&FRAGF_SPOONOFF
			||weaponstatus[0]&FRAGF_PINOUT
		){
			TossGrenade(true);
		}else{
			bool inhand=weaponstatus[0]&FRAGF_INHAND;
			if(inhand||owner.countinv(grenadeammotype)){
				if(!inhand)A_TakeInventory(grenadeammotype,1);
				A_DropItem(grenadeammotype);
			}
			weaponstatus[0]&=~FRAGF_INHAND;
		}
	}
	//any reset should do this
	action void A_ReturnHandToOwner(){invoker.ReturnHandToOwner();}
	void ReturnHandToOwner(){
		if(!owner)return;
		int wepstat=weaponstatus[0];
		if(wepstat&FRAGF_INHAND){
			if(wepstat&FRAGF_SPOONOFF)TossGrenade(true);
			else{
				if(wepstat&FRAGF_PINOUT){
					owner.A_StartSound(pinsound,8);
					weaponstatus[0]&=~FRAGF_PINOUT;
				}
				if(
					owner.A_JumpIfInventory(grenadeammotype,0,"null")
				)owner.A_DropItem(grenadeammotype);
				else HDF.Give(owner,grenadeammotype,1);
			}
		}
		weaponstatus[0]&=~FRAGF_INHAND;
		weaponstatus[FRAGS_FORCE]=0;
		weaponstatus[FRAGS_REALLYPULL]=0;
	}
	vector3 SwingThrow(){
		vector2 iyy=(owner.angle,owner.pitch);
		double cosp=cos(iyy.y);
		vector3 oldpos=(
			cosp*cos(iyy.x),
			cosp*sin(iyy.x),
			sin(iyy.y)
		);
		iyy+=(
				owner.getplayerinput(MODINPUT_YAW),
				owner.getplayerinput(MODINPUT_PITCH)
			)
			*(360./65536.);
		cosp=cos(iyy.y);
		vector3 newpos=(
			cosp*cos(iyy.x),
			cosp*sin(iyy.x),
			sin(iyy.y)
		);
		return newpos-oldpos;
	}
	//because it's tedious to type each time
	action bool NoFrags(){
		return !(invoker.weaponstatus[0]&FRAGF_INHAND)&&!countinv(invoker.grenadeammotype);
	}
	//pull the pin
	action void A_PullPin(){
		invoker.weaponstatus[FRAGS_REALLYPULL]=0;
		invoker.weaponstatus[0]|=(FRAGF_PINOUT|FRAGF_INHAND);
		A_TakeInventory(invoker.grenadeammotype,1,TIF_NOTAKEINFINITE);
		A_StartSound(invoker.pinsound,8);
	}
	//drop the spoon
	action void A_StartCooking(){
		invoker.StartCooking();
		A_SetHelpText();
	}
	void StartCooking(){
		if(!owner)return;
		bool gbg;actor spn;
		double ptch=owner.pitch;
		double cpp=cos(ptch);double spp=sin(ptch);
		[gbg,spn]=owner.A_SpawnItemEx(spoontype,
			cpp*4,-1,gunheight()+2-spp*4,
				cpp*4+vel.x,
				0,
				-sin(pitch)*4+vel.z,
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		spn.vel+=owner.vel;
		weaponstatus[0]|=FRAGF_SPOONOFF;
		if(DoHelpText(owner))A_WeaponMessage(StringTable.Localize("$GREN_FUZE"),100);
		owner.A_StartSound(spoonsound,8,attenuation:20);
	}
	//we need to start from the inventory itself so it can go into DoEffect
	action void A_TossGrenade(bool oshit=false){
		invoker.TossGrenade(oshit);
		A_SetHelpText();
	}
	void TossGrenade(bool oshit=false){
		if(!owner)return;
		int garbage;actor ggg;
		double cpp=cos(owner.pitch);
		double spp=sin(owner.pitch);

		//create the spoon
		if(!(weaponstatus[0]&FRAGF_SPOONOFF)){
			[garbage,ggg]=owner.A_SpawnItemEx(
				spoontype,cpp*-4,-3,owner.height*0.88-spp*-4,
				cpp*3,0,-sin(owner.pitch+random(10,20))*3,
				frandom(33,45),SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
			ggg.vel+=owner.vel;
		}

		//create the grenade
		[garbage,ggg]=owner.A_SpawnItemEx(throwtype,
			0,0,owner.height*0.88,
			cpp*4,
			0,
			-spp*4,
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		ggg.vel+=owner.vel;

		//force calculation
		double gforce=clamp(weaponstatus[FRAGS_FORCE]*0.5,1,40+owner.health*0.1);
		if(oshit)gforce=min(gforce,frandom(4,20));
		if(hdplayerpawn(owner))gforce*=hdplayerpawn(owner).strength;

		let grenade=HDFragGrenade(ggg);if(!grenade)return;
		grenade.fuze=weaponstatus[FRAGS_TIMER];

		if(owner.player){
			grenade.vel+=SwingThrow()*gforce;
		}
		grenade.a_changevelocity(
			cpp*gforce*0.6,
			0,
			-spp*gforce*0.6,
			CVF_RELATIVE
		);
		weaponstatus[FRAGS_TIMER]=0;
		weaponstatus[FRAGS_FORCE]=0;
		weaponstatus[0]&=~FRAGF_PINOUT;
		weaponstatus[0]&=~FRAGF_SPOONOFF;
		weaponstatus[FRAGS_REALLYPULL]=0;

		weaponstatus[0]&=~FRAGF_INHAND;
		weaponstatus[0]|=FRAGF_JUSTTHREW;
	}
	Action void A_Dumb(bool work=true){invoker.ActuallyDumb(work);}
	void ActuallyDumb(bool work=true){if(owner.health>0)setweaponstate("TakeAnother");}
	states{
	Exploding1:
		TNT1 AAAAAAAAAAAA 1 A_JumpIf(Health < 1, "Exploding");
		Stop;
	Explode:
		GRNG D 3 A_OverLay(27,"Exploding1");
	Exploding:	
		GRND BCDECBDCEDBCDEBCDECBDCEDBCDE 2 A_OverLayOffset(27,0,30);
		GRND FG 3;
		---- # 2 A_JumpIf(Health > 0, "TakeAnother");
	Dead:
		GRND G 1 A_Dumb();
		Loop;
	HandUp:
		GRNH C 1 A_OverLayOffset(26, -20, 20);
		GRNH C 1 A_OverLayOffset(26, -15, 15);
		GRNH C 1 A_OverLayOffset(26, -10, 10);
		GRNH C 1 A_OverLayOffset(26, -5, 5);
		Stop;
	GranUp:
		GRNG A 1 A_OverLayOffset(25, 20, 20);
		GRNG A 1 A_OverLayOffset(25, 15, 15);
		GRNG A 1 A_OverLayOffset(25, 10, 10);
		GRNG A 1 A_OverLayOffset(25, 5, 5);
		Stop;
	TakeAnother:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		GRNG D 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>136,"Explode");
		TNT1 A 0 A_OverLay(26, "HandUp");
		TNT1 A 0 A_OverLay(25, "GranUp");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		TNT1 A 3;
		Goto Ready;
	select0:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 1{
			if(!countinv("NulledWeapon"))A_SetTics(tics+4);
			A_TakeInventory("NulledWeapon");
			invoker.weaponstatus[FRAGS_REALLYPULL]=0;
			invoker.weaponstatus[FRAGS_FORCE]=0;
		}
		//TNT1 A 0 A_OverLay(26, "HandUp");
		TNT1 A 1 A_Raise(0);
		TNT1 A 1 A_Raise(18);
		Goto TakeAnother;
	selectinstant:
		TNT1 A 0 A_WeaponBusy(false);
	readytodonothing:
		//TNT1 A 0 A_JumpIf(pressing(BT_SPEED)||pressingfire()||pressingaltfire()||pressingreload()||pressingzoom(),2);
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		TNT1 A 0 A_JumpIf(NoFrags(),"readytodonothing");
		Goto TakeAnother;
		TNT1 A 0 A_SelectWeapon("HDFist");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		wait;
	HandDown:
		GRNH C 1 A_OverLayOffset(26, -10, 10);
		GRNH C 1 A_OverLayOffset(26, -15, 20);
		GRNH C 1 A_OverLayOffset(26, -20, 30);
		Stop;	
	deselect0:
		GRNG A 0{
			if(invoker.weaponstatus[0]&FRAGF_PINOUT)A_SetTics(8);
			else if(NoFrags())setweaponstate("deselectinstant");
			invoker.ReturnHandToOwner();
		}
		TNT1 A 0 A_OverLay(26, "HandDown");
		GRNG A 1 A_Lower(30);
		GRNG A 1 A_Lower(50);
		GRNG A 1 A_Lower(60);
		GRNG A 1 A_Lower(72);
		wait;
	deselectinstant:
		TNT1 A 0 A_Lower(999);
		wait;
	Non:
		TNT1 A 1;
		Stop;
	HandReady:
		GRNG D 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>135,"Non");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_SPOONOFF, "Non");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT, "HandReadyPin");
		GRNH C 1 A_OverLayOffset(26,0,0);
		GRNG D 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>135,"Non");
		Loop;
	HandReadyPin:
		GRNG D 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>135,"Non");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_SPOONOFF, "Non");
		GRNH D 1 A_OverLayOffset(26,-27,12);
		GRNG D 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>135,"Non");
		Loop;
	ready:
		GRNG D 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>135,"Explode");
		GRNG A 0{
			invoker.weaponstatus[FRAGS_FORCE]=0;
			invoker.weaponstatus[FRAGS_REALLYPULL]=0;
			If(!(invoker.weaponstatus[0]&FRAGF_SPOONOFF))A_OverLay(26,"HandReady");
			}
		GRNG D 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_SPOONOFF,3);
		GRNG B 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,2);
		GRNG A 0;
		GRNG # 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>135,"Explode");
		GRNG # 1 A_WeaponReady(WRF_ALL);
		GRNG # 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>135,"Explode");
		goto ready3;
	ready3:
		---- A 0{
			invoker.weaponstatus[0]&=~FRAGF_JUSTTHREW;
			A_WeaponBusy(false);
		}goto readyend;

	zoom:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 0{
			let wiretype=invoker.wiretype;
			A_GiveInventory(wiretype);
			A_SelectWeapon(wiretype);
			A_WeaponReady(WRF_NOFIRE);
		}goto nope;

	pinout:
		GRNG B 1 A_WeaponReady(WRF_ALLOWRELOAD);
		loop;

	altfire:
		GRNG C 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_SPOONOFF,"readyend");
		GRNG B 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"startcooking");
		GRNG A 0 A_JumpIf(NoFrags(),"selectinstant");
		GRNG A 0 A_Refire();
		goto ready;
	althold:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_SPOONOFF,"nope");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"nope");
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 0 A_OverLay(26, "HandPinOut1");
		GRNG A 1 offset(-3,2);
		#### A 1 offset(-6,4);
		#### A 1 offset(-9,6);
		goto startpull;
	startpull:
		TNT1 A 0 A_OverLay(26, "HandPinHolding");
		GRNG A 1{
			if(invoker.weaponstatus[FRAGS_REALLYPULL]>=16)setweaponstate("endpull");
			else invoker.weaponstatus[FRAGS_REALLYPULL]++;
		}
		GRNG A 0 A_Refire("startpull");
		TNT1 A 0 A_OverLay(26, "HandPinOutAbort");
		GRNG A 1 offset(-9,6);
		#### A 1 offset(-6,4);
		#### A 1 offset(-3,2);
		goto ready;
	endpull:
		TNT1 A 0 A_OverLay(26, "HandPinOutAlready");
		GRNG A 1;
		#### A 3;
		#### B 3 A_PullPin();
		GRNG B 0 A_Refire("Nope");
		goto ready;
	HandCook:
		GRNH D 1 A_OverLayOffset(26, -20, 12);
		GRNH D 1 A_OverLayOffset(26, -25, 17);
		GRNH D 1 A_OverLayOffset(26, -30, 24);
		GRNH D 1 A_OverLayOffset(26, -35, 30);
		GRNH D 1 A_OverLayOffset(26, -40, 40);
		GRNH D 1 A_OverLayOffset(26, -45, 50);
		Stop;
	startcooking:
		GRNG C 0 A_OverLay(26, "HandCook");
		GRNG C 6 A_StartCooking();
		//GRNG C 0 A_Refire("Nope");
		goto ready;
	HandPinOut1:
		GRNH C 1 A_OverLayOffset(26, 4, -2);
		GRNH C 1 A_OverLayOffset(26, 7, -4);
		GRNH C 1 A_OverLayOffset(26, 11, -6);
		GRNH C 1 A_OverLayOffset(26, 14, -8);
		GRNH C 1 A_OverLayOffset(26, 18, -10);
		Stop;
	HandPinOutAbort:
		GRNH C 1 A_OverLayOffset(26, 18, -10);
		GRNH C 1 A_OverLayOffset(26, 14, -8);
		GRNH C 1 A_OverLayOffset(26, 11, -6);
		GRNH C 1 A_OverLayOffset(26, 7, -4);
		GRNH C 1 A_OverLayOffset(26, 4, -2);
		Stop;	
	HandPinHolding:
		GRNH D 1 A_OverLayOffset(26, 0, 0);
		Stop;
	HandPinOutAlready:
		GRNH D 3 A_OverLayOffset(26, -1, 1);
		GRNH D 1 A_OverLayOffset(26, -3, 2);
		GRNH D 1 A_OverLayOffset(26, -6, 3);
		GRNH D 1 A_OverLayOffset(26, -15, 8);
		Goto HandReady;	
	HandPinOut2:
		GRNH C 1 A_OverLayOffset(26, 14, -8);
		GRNH C 1 A_OverLayOffset(26, 18, -10);
		GRNH D 3 {A_OverLayOffset(26, 0, 0); A_SetTics(hdplayerpawn(self)?int(5./hdplayerpawn(self).strength):6);}
		GRNH D 3 {A_OverLayOffset(26, -1, 1); A_SetTics(hdplayerpawn(self)?int(5./hdplayerpawn(self).strength):6);}
		GRNH D 1 A_OverLayOffset(26, -3, 2);
		GRNH D 1 A_OverLayOffset(26, -6, 3);
		GRNH D 1 A_OverLayOffset(26, -15, 8);
	HandPinOut4:	
		GRNH D 1 A_OverLayOffset(26, -31, 10);
		GRNH D 1 A_OverLayOffset(26, -36, 8);
		GRNH D 1 A_OverLayOffset(26, -42, 6);
		GRNH D 1 A_OverLayOffset(26, -50, 4);
		GRNH D 2 A_OverLayOffset(26, -57, 2);
		GRNH D 2 A_OverLayOffset(26, -65, 0);
		Stop;	
	HandPinOut3:
		GRNH C 1 A_OverLayOffset(26, 14, -8);
		GRNH C 1 A_OverLayOffset(26, 18, -10);
		GRNH D 3 A_OverLayOffset(26, 0, 0);
		GRNH D 3 A_OverLayOffset(26, -1, 1);
		GRNH D 1 A_OverLayOffset(26, -3, 2);
		GRNH D 1 A_OverLayOffset(26, -6, 3);
		GRNH D 1 A_OverLayOffset(26, -15, 8);
		Goto HandReady;
	HandPoint:
		GRNH A 1 {If(invoker.weaponstatus[FRAGS_FORCE]>=40) A_OverLayOffset(26, -20, 0); 
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=37)A_OverLayOffset(26, -20, 2);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=35)A_OverLayOffset(26, -21, 5);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=32)A_OverLayOffset(26, -22, 8);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=30)A_OverLayOffset(26, -23, 10);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=27)A_OverLayOffset(26, -24, 12);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=25)A_OverLayOffset(26, -25, 15);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=22)A_OverLayOffset(26, -26, 18);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=20)A_OverLayOffset(26, -27, 20);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=18)A_OverLayOffset(26, -28, 23);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=15)A_OverLayOffset(26, -29, 25);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=12)A_OverLayOffset(26, -30, 28);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=10)A_OverLayOffset(26, -31, 30);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=8)A_OverLayOffset(26, -32, 32);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=5)A_OverLayOffset(26, -33, 35);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=2)A_OverLayOffset(26, -34, 38);
				Else If(invoker.weaponstatus[FRAGS_FORCE]>=0)A_OverLayOffset(26, -35, 40);}
		Stop;
	fire:
		#### # 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_JUSTTHREW,"nope");
		#### # 0 A_JumpIf(NoFrags(),"selectinstant");
		#### # 0 A_JumpIf(hdplayerpawn(self)&&hdplayerpawn(self).strength>1.7,3);
		#### # 0 A_JumpIf(hdplayerpawn(self)&&hdplayerpawn(self).strength>1.3,2);
		#### # 1;
		TNT1 A 0 A_Refire("PreHold");
		goto ready;
	GranHold:
		GRNG D 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_SPOONOFF,2);
		GRNG B 0;
		GRNG # 1 A_OverLayOffset(25, 7, 5);
		GRNG # 1 A_OverLayOffset(25, 15, 10);
		GRNG # 1 A_OverLayOffset(25, 22, 15);
		GRNG # 1 A_OverLayOffset(25, 30, 20);
		GRNG # 1 A_OverLayOffset(25, 37, 25);
		GRNG # 1 A_OverLayOffset(25, 45, 30);
		GRNG # 1 A_OverLayOffset(25, 53, 35);
		GRNG # 1 A_OverLayOffset(25, 60, 40);
		Stop;
	hold21:
		TNT1 A 0 A_OverLay(25,"GranHold");
		TNT1 A 0 A_OverLay(26,"Non");
		TNT1 A 8;
		Goto Hold2;
	PreHold:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"hold21");
	hold:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_JUSTTHREW,"nope");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"hold2");
		TNT1 A 0 A_OverLay(26, "HandPinOut1");
		GRNG A 1 offset(-3,2);
		#### A 1 offset(-6,4);
		#### A 1 offset(-9,6);
		TNT1 A 0 A_OverLay(26, "HandPinOut2");
		GRNG A 4 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=1,"hold2");
		GRNG A 4 A_SetTics(hdplayerpawn(self)?int(5./hdplayerpawn(self).strength):6);
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		GRNG B 3 A_PullPin();
		TNT1 A 0 A_OverLay(25,"GranHold");
		#### # 8;
		Goto Hold2;
	hold2:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		FRGG E 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=40,"hold3a");
		FRGG D 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=30,"hold3a");
		FRGG C 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=20,"hold3");
		FRGG B 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=10,"hold3");
		goto hold3;
	hold3a:
		FRGG # 0{
			if(invoker.weaponstatus[FRAGS_FORCE]<50)invoker.weaponstatus[FRAGS_FORCE]++;
		}
	hold3:
		TNT1 # 0 A_OverLay(26,"HandPoint");
		/*FRGG #*/
		TNT1 A 1{
			A_WeaponReady(
				invoker.weaponstatus[0]&FRAGF_SPOONOFF?WRF_NOFIRE:WRF_NOFIRE|WRF_ALLOWRELOAD
			);
			if(invoker.weaponstatus[FRAGS_FORCE]<50)invoker.weaponstatus[FRAGS_FORCE]++;
		}
		TNT1 A 0 A_Refire();
		goto throw;
	HandThrow:
		GRNH A 1 A_OverLayOffset(26, -35, 19);
		GRNH A 1 A_OverLayOffset(26, -48, 37);
		GRNH A 1 A_OverLayOffset(26, -56, 46);
		Stop;
	GranThrow:
		GRNG E 1 A_OverLayOffset(25, 10, -10);
		GRNG E 1 A_OverLayOffset(25, 0, 0);
		GRNG E 1 A_OverLayOffset(25, -10, 10);
		GRNG F 1 A_OverLayOffset(25, 7, 0);
		GRNG F 1 A_OverLayOffset(25, 2, 10);
		GRNG F 1 A_OverLayOffset(25, -2, 20);
		GRNG F 1 A_OverLayOffset(25, -5, 30);
		GRNG F 1 A_OverLayOffset(25, -10, 40);
		GRNG F 1 A_OverLayOffset(25, -15, 50);
		Stop;
	throw:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 0 A_OverLay(26,"HandThrow");
		TNT1 A 0 A_OverLay(25, "GranThrow");
		FRGG A 2 offset(0,0);
		FRGG A 0 A_TossGrenade();
		FRGG A 6;
		//FRGG A 0 A_Refire();
		goto TakeAnother;
	reload:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_SPOONOFF,"Ready");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=1,"pinbackin");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"altpinbackin");
		goto ready;
	HandPinBack:
		GRNH D 1 A_OverLayOffset(26, -64, -26);
		GRNH D 1 A_OverLayOffset(26, -58, -20);
		GRNH D 1 A_OverLayOffset(26, -50, -10);
		GRNH D 1 A_OverLayOffset(26, -36, -7);
		GRNH D 1 A_OverLayOffset(26, -15, 8);
		GRNH D 1 A_OverLayOffset(26, -3, 2);
		GRNH D 3 A_OverLayOffset(26, -1, 1);
		GRNH D 1 A_OverLayOffset(26, 0, 0);
		GRNH C 1 A_OverLayOffset(26, 18, -10);
		GRNH C 1 A_OverLayOffset(26, 12, -2);
		GRNH C 1 A_OverLayOffset(26, 11, -6);
		GRNH C 1 A_OverLayOffset(26, 7, -4);
		GRNH C 1 A_OverLayOffset(26, 4, -2);
		Stop;	
	GranPinBack:
		TNT1 A 2;
		GRNG B 1 A_OverLayOffset(25, 53, 35);
		GRNG B 1 A_OverLayOffset(25, 45, 30);
		GRNG B 1 A_OverLayOffset(25, 37, 25);
		GRNG B 1 A_OverLayOffset(25, 30, 20);
		GRNG B 0 A_ReturnHandToOwner();
		GRNG B 3 A_OverLayOffset(25, 7, 5);
		GRNG B 2 A_OverLayOffset(25, 22, 15);
		GRNG B 2 A_OverLayOffset(25, 15, 10);
		GRNG B 1 A_OverLayOffset(25, 10, 5);
		GRNG B 1 A_OverLayOffset(25, 5, 2);
		Stop;	
	pinbackin:
		TNT1 A 0 {A_OverLay(25, "GranPinBack"); A_OverLay(26, "HandPinBack");}
		TNT1 A 1;
		TNT1 A 14;
		GRNG A 0 A_OverLay(26, "HandReady");
		GRNG A 1;
		GRNG A 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>0,"juststopthrowing");
		GRNG A 0 A_Refire("nope");
		goto ready;
	HandPinBack2:
		GRNH D 2 A_OverLayOffset(26, -10, 7);
		GRNH D 2 A_OverLayOffset(26, -7, 7);
		GRNH D 1 A_OverLayOffset(26, -6, 6);
		GRNH C 1 A_OverLayOffset(26, 18, -10);
		GRNH C 1 A_OverLayOffset(26, 12, -2);
		GRNH C 1 A_OverLayOffset(26, 4, -6);
		Goto HandReady;	
	GranPinBack2:
		GRNG B 2 A_OverLayOffset(25, -2, 2);
		GRNG B 0 A_ReturnHandToOwner();
		GRNG B 3 A_OverLayOffset(25, -5, 5);
		GRNG A 2 A_OverLayOffset(25, -2, 2);
		Stop;		
	altpinbackin:
		FRGG A 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>0,"juststopthrowing");
		TNT1 A 0 {A_OverLay(25, "GranPinBack2"); A_OverLay(26, "HandPinBack2");}
		TNT1 A 7;
		GRNG A 0 A_OverLay(26, "HandReady");
		GRNG A 1;
		GRNG A 0 A_Refire("nope");
		goto ready;
	juststopthrowing:
		TNT1 A 10;
		FRGG A 0{invoker.weaponstatus[FRAGS_FORCE]=0;}
		TNT1 A 0 A_Refire();
		FRGG B 1 offset(0,38);
		FRGG B 1 offset(0,36);
		FRGG B 1 offset(0,34);
		goto ready;
	spawn:
		TNT1 A 1;
		TNT1 A 0 A_SpawnItemEx(invoker.grenadeammotype,SXF_NOCHECKPOSITION);
		stop;
	}
}
enum GrenadeWepNums{
	FRAGF_INHAND=1,
	FRAGF_PINOUT=2,
	FRAGF_SPOONOFF=4,
	FRAGF_JUSTTHREW=8,

	FRAGS_REALLYPULL=1,
	FRAGS_TIMER=2,
	FRAGS_FORCE=3,
}




// ------------------------------------------------------------
// The only grenades in base HD.
// ------------------------------------------------------------
extend class HDActor{
	void A_SpawnChunksFrags(
		class<actor> type="HDB_frag",
		int number=360,
		double mult=1.
	){
		let ddd=getdefaultbytype(type);
		double dsp=ddd.speed*mult;
		A_SpawnChunks(type,number,dsp*ddd.deathheight,dsp);
	}
}
class HDFragGrenades:HDGrenadethrower{
	default{
		weapon.selectionorder 1020;
		weapon.slotnumber 0;
		tag "$TAG_GREFRAG";
		hdgrenadethrower.ammotype "HDFragGrenadeAmmo";
		hdgrenadethrower.throwtype "HDFragGrenade";
		hdgrenadethrower.spoontype "HDFragSpoon";
		hdgrenadethrower.wiretype "Tripwire";
		inventory.icon "FRAGA0";
	}
}
class HDFragGrenadeRoller:HDActor{
	int fuze;
	vector3 keeprolling;
	default{
		-noextremedeath -floorclip +shootable +noblood +forcexybillboard
		+activatemcross -noteleport +noblockmonst +explodeonwater
		+missile +bounceonactors +usebouncestate
			bouncetype "doom";bouncesound "misc/fragknock";
		radius 2;height 2;damagetype "none";
		scale 0.3;
		obituary "%o was fragged by %k.";
		radiusdamagefactor 0.04;pushfactor 1.4;maxstepheight 2;mass 30;
	}
	override bool used(actor user){
		angle=user.angle;
		A_StartSound(bouncesound);
		if(hdplayerpawn(user)&&hdplayerpawn(user).incapacitated)A_ChangeVelocity(4,0,1,CVF_RELATIVE);
		else A_ChangeVelocity(12,0,4,CVF_RELATIVE);
		return true;
	}
	states{
	spawn:
		FRAG A 0 nodelay{
			HDMobAI.Frighten(self,512);
		}
	spawn2:
		#### BCD 2{
			if(abs(vel.z-keeprolling.z)>10)A_StartSound("misc/fragknock",CHAN_BODY);
			else if(floorz>=pos.z)A_StartSound("misc/fragroll");
			keeprolling=vel;
			if(abs(vel.x)<0.4 && abs(vel.y)<0.4) setstatelabel("death");
		}loop;
	bounce:
		---- A 0{
			bmissile=false;
			vel*=0.3;
		}goto spawn2;
	death:
		---- A 2{
			if(abs(vel.z-keeprolling.z)>3){
				A_StartSound("misc/fragknock",CHAN_BODY);
				keeprolling=vel;
			}
			if(abs(vel.x)>0.4 || abs(vel.y)>0.4) setstatelabel("spawn");
		}wait;
	destroy:
		TNT1 A 1{
			bsolid=false;bpushable=false;bmissile=false;bnointeraction=true;bshootable=false;
			HDFragGrenade.FragBlast(self);
			actor xpl=spawn("WallChunker",self.pos-(0,0,1),ALLOW_REPLACE);
				xpl.target=target;xpl.master=master;xpl.stamina=stamina;
			xpl=spawn("HDExplosion",self.pos-(0,0,1),ALLOW_REPLACE);
				xpl.target=target;xpl.master=master;xpl.stamina=stamina;
			A_SpawnChunks("BigWallChunk",14,4,12);
		}
		stop;
	}
	override void tick(){
		if(isfrozen())return;
		else if(bnointeraction){
			NextTic();
			return;
		}else{
			fuze++;
			if(fuze>=140 && !bnointeraction){
				setstatelabel("destroy");
				NextTic();
				return;
			}else super.tick();
		}
	}
}
class HDFragGrenade:SlowProjectile{
	int fuze;
	vector3 keeprolling;
	class<actor> rollertype;
	property rollertype:rollertype;
	default{
		-noextremedeath -floorclip +bloodlessimpact
		+shootable -noblockmap +noblood
		+activatemcross -noteleport
		radius 5;height 5;damagetype "none";
		scale 0.3;
		obituary "%o was fragged by %k.";
		mass 500;
		hdfraggrenade.rollertype "HDFragGrenadeRoller";
	}
	static void FragBlast(HDActor caller){
		distantnoise.make(caller,"world/rocketfar");
		DistantQuaker.Quake(caller,4,35,512,10);
		caller.A_StartSound("world/explode",CHAN_BODY,CHANF_OVERLAP);
		caller.A_AlertMonsters();
		caller.A_SpawnChunksFrags();
		caller.A_HDBlast(
			pushradius:256,pushamount:128,fullpushradius:96,
			fragradius:HDCONST_ONEMETRE*12
		);
	}
	override void tick(){
		ClearInterpolation();
		if(isfrozen())return;
		if(!bmissile){
			hdactor.tick();return;
		}else if(fuze<140){
			fuze++;
			keeprolling=vel;
			super.tick();
		}else{
			if(inthesky){
				FragBlast(self);
				destroy();return;
			}
			let gr=HDFragGrenadeRoller(spawn(rollertype,pos,ALLOW_REPLACE));
			gr.target=self.target;gr.master=self.master;gr.vel=self.vel;
			gr.fuze=fuze;
			destroy();return;
		}
	}
	override void postbeginplay(){
		hdactor.postbeginplay();
		divrad=1./(radius*1.9);
		grav=getgravity();
	}
	states{
	spawn:
		FRAG BCD 2;
		loop;
	death:
		TNT1 A 10{
			bmissile=false;
			let gr=HDFragGrenadeRoller(spawn(rollertype,self.pos,ALLOW_REPLACE));
			if(!gr)return;
			gr.target=self.target;gr.master=self.master;
			gr.fuze=self.fuze;
			gr.vel=self.keeprolling;
			gr.keeprolling=self.keeprolling;
			gr.A_StartSound("misc/fragknock",CHAN_BODY);
			HDMobAI.Frighten(gr,512);
		}stop;
	}
}
class HDFragSpoon:HDDebris{
	default{
		scale 0.3;bouncefactor 0.6;
		bouncesound "misc/casing4";
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_StartSound("weapons/grenopen",CHAN_VOICE);
	}
	states{
	spawn:
		FRGP A 2{roll+=40;}wait;
	death:
		FRGP A -1;
	}
}

class HDFragGrenadeAmmo:HDAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Frag Grenade"
		//$Sprite "FRAGA0"

		+forcexybillboard
		inventory.icon "FRAGA0";
		inventory.amount 1;
		scale 0.3;
		inventory.maxamount 50;
		inventory.pickupmessage "$PICKUP_GRENADE";
		inventory.pickupsound "weapons/pocket";
		tag "$TAG_GREFRAG";
		hdpickup.refid HDLD_GREFRAG;
		hdpickup.bulk ENC_FRAG;
	}
	override bool IsUsed(){return true;}
	states{
	spawn:
		FRAG A -1;stop;
	}
}
class FragP:HDUPK{
	default{
		+forcexybillboard
		scale 0.3;height 3;radius 3;
		hdupk.amount 1;
		hdupk.pickuptype "HDFragGrenadeAmmo";
		hdupk.pickupmessage "$PICKUP_GRENADE";
		hdupk.pickupsound "weapons/rifleclick2";
		stamina 1;
	}
	override void postbeginplay(){
		super.postbeginplay();
		pickupmessage=getdefaultbytype(pickuptype).pickupmessage();
	}
	states{
	spawn:
		FRAG A -1;
	}
}

