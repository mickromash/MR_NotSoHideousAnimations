// ------------------------------------------------------------
// CRAAAAAAAAAAAWWWWLING IN MY SKIN
// ------------------------------------------------------------
extend class HDHandlers{
	void PlayDead(hdplayerpawn ppp){
		if(!ppp||ppp.incapacitated>0)return;
		ppp.A_Incapacitated(hdplayerpawn.HDINCAP_FAKING);
	}
}
const HDCONST_MINSTANDHEALTH=12;
const HDCONST_INCAPFRAME=((11-6)<<2); //first fall-down frame # multiplied by 4
extend class HDPlayerPawn{
	int incapacitated;
	int incaptimer;
	inventory invselbak;
	void IncapacitatedCheck(){

		//abort if there's nothing at all to do
		if(
			!incapacitated
			&&incaptimer<1
		)return;


		double fullheight=max(1,default.height*heightmult);
		double downedheight=max(1,16*heightmult);


		//deplete and damage
		if(incaptimer>0){
			incaptimer--;
			muzzleclimb1.y+=(level.time&1)?-1:1;
			if(
				incaptimer>TICRATE*60*10
				||health>70
			){
				damagemobj(null,null,1,"maxhpdrain");
				incaptimer-=(incaptimer>>4);
			}
		}

		//fall down and stay down
		if(incapacitated>0){
			A_SetSize(radius,max(downedheight,height-3));
			if(!countinv("HDIncapWeapon")){
				A_SetInventory("HDIncapWeapon",1);
				if(player&&player.readyweapon){
					if(
						!HDFist(player.readyweapon)&&(
							player.cmd.buttons&(
								BT_ATTACK|BT_ALTATTACK|BT_RELOAD|BT_ZOOM
								|BT_USER1|BT_USER2|BT_USER3|BT_USER4
							)||(
								hdweapon(player.readyweapon)
								&&hdweapon(player.readyweapon).bweaponbusy
							)
						)
					)DropInventory(player.readyweapon);
					else player.setpsprite(PSP_WEAPON,player.readyweapon.findstate("deselect"));
				}
			}
			A_SelectWeapon("HDIncapWeapon");
		}else{
			//get up
			A_SetSize(radius,min(fullheight,height+3));
		}
		player.viewz=min(ceilingz-6,pos.z+viewheight*(height/fullheight)+wepbob.y*0.1);


		//clear selected inventory so you can't use things easily
		if(invsel){
			invselbak=invsel;
			invsel=null;
		}


		//set the appropriate frame
		if(incapacitated){
			frame=clamp(6+abs(incapacitated>>2),6,11);

			//update if in the process of getting up
			if(incapacitated<0){
				if(
					incapacitated<0
					&&countinv("HDZerk")>HDZerk.HDZERK_COOLOFF
				)incapacitated=min(0,incapacitated+4);
			}
			incapacitated++;

			//set stuff
			runwalksprint=-1;
			speed=0.02;
			userange=20*heightmult;

		}else if(incaptimer>0){

			//set stuff - hobbling
			runwalksprint=-1;
			speed=0.2+(0.001*heightmult)*health;
			userange=20*heightmult;
		}


		//jitters
		if(
			incaptimer>0
			&&pitch<70
			&&!fallroll
		)muzzleclimb1.y+=frandom(0.1,0.4);


		//check for ability to stand despite incap
		double mshbak=maxstepheight;
		maxstepheight=20;
		int maxincaptimerstand=(
			health>HDCONST_MINSTANDHEALTH
			&&!checkmove(
				self.pos.xy+(cos(angle),sin(angle))*8,false
			)
			&&(
				!blockingmobj
				||!blockingmobj.bismonster
				||blockingmobj.isfriend(self)
				||blockingmobj.player  //what if an opponent wanted to do this?
			)
		?(TICRATE*900):1);
		maxstepheight=mshbak;


		//conditions for getting back up
		if(
			health>HDCONST_MINSTANDHEALTH+1
			&&incapacitated>0
			&&incaptimer<maxincaptimerstand
			&&fatigue<HDCONST_WALKFATIGUE
			&&(
				player.cmd.buttons&BT_JUMP
				||player.bot
				||(
					countinv("HDZerk")>HDZerk.HDZERK_COOLOFF
					&&!random(0,255)
				)
			)
		){
			scale.y=skinscale.y*heightmult;
			incapacitated=-HDCONST_INCAPFRAME;
			fatigue+=5;
		}

		//conditions for falling back down
		if(
			!incapacitated
			&&incaptimer>maxincaptimerstand
		)incapacitated=1;


		if(
			incaptimer>0
			&&health>HDCONST_MINSTANDHEALTH
			&&health<HDCONST_MINSTANDHEALTH+3
		){
			damagemobj(null,null,min(5,health-10),"maxhpdrain");
		}

		if(
			!incapacitated
			||countinv("HDZerk")>HDZerk.HDZERK_COOLOFF
		){
			A_Capacitated();
		}
	}
	void A_Capacitated(){
		incapacitated=0;
		A_TakeInventory("HDIncapWeapon");
		A_SetSize(default.radius*heightmult,default.height*heightmult);
		userange=default.userange*heightmult;
		player.viewheight=viewheight*player.crouchfactor;
		if(invselbak&&invselbak.owner==self)invsel=invselbak;else{
			for(let item=inv;item!=null;item=item.inv){
				if(
					item.binvbar
				){
					invsel=item;
					break;
				}
			}
		}
		if(pos.z+height>ceilingz)player.crouchfactor=((ceilingz-pos.z)/height);
	}
	void A_Incapacitated(int flags=0,int incaptime=35){
		let ppp=player;
		if(!ppp)return;
		if(
			!(flags&HDINCAP_FAKING)
			&&!random(0,15)
		)Disarm(self);
		else{
			let www=hdweapon(ppp.readyweapon);
			if(www)www.OnPlayerDrop();
			if(flags&HDINCAP_SCREAM){
				if(!fallroll)A_StartSound(deathsound,CHAN_VOICE);
				else A_StartSound(painsound,CHAN_VOICE);
			}
		}
		if(
			!(flags&HDINCAP_FAKING)
			&&health<10
		)GiveBody(7);
		incapacitated=1;

		if((flags&HDINCAP_FAKING))fatigue+=2;
		else incaptimer=max(incaptimer,incaptime);

		setstatelabel("spawn");
	}
	enum IncapFlags{
		HDINCAP_FAKING=1,
		HDINCAP_SCREAM=2,
	}
}


class HDIncapWeapon:SelfBandage{
	String NSHStim, NSHBers;
	
	class<actor> injecttype;
	class<actor> spentinjecttype;
	class<inventory> inventorytype;
	default{
		+hdweapon.reverseguninertia
		weapon.bobspeed 0.7;
	}
	action void A_PickInventoryType(){
		static const class<inventory> types[]={
			"HDIncapWeapon",
			"NSHPortableBerserkpack",
			"NSHPortableStimpack",
			"DERPUsable",
			"HDFragGrenadeAmmo"
		};

		if(
			!invoker.weaponstatus[INCS_INDEX]
			&&!countinv("NSHPortableStimpack")
			&&countinv("PortableMedikit")
		){
			player.cmd.buttons|=BT_USE;
			UseInventory(findinventory("PortableMedikit"));
			invoker.spentinjecttype="SpentStim";
			invoker.injecttype="InjectStimDummy";
			return;
		}

		int which=invoker.weaponstatus[INCS_INDEX];
		do{
			which++;
			if(which>=types.size())which=0;
		}while(!countinv(types[which]));
		invoker.weaponstatus[INCS_INDEX]=which;

		let inventorytype=types[which];
		if(
			!countinv(inventorytype)
		){
			inventorytype="HDIncapWeapon";
			return;
		}else if(inventorytype==invoker.NSHBers){
			invoker.spentinjecttype="SpentZerk";
			invoker.injecttype="InjectZerkDummy";
		}
		else if(inventorytype==invoker.NSHStim){
			invoker.spentinjecttype="SpentStim";
			invoker.injecttype="InjectStimDummy";
		}
		else if(inventorytype=="HDFragGrenadeAmmo"){
			invoker.spentinjecttype="HDFragSpoon";
			invoker.injecttype="HDFragGrenadeRoller";
		}
		else if(inventorytype=="DERPUsable"){
			invoker.spentinjecttype="";
			invoker.injecttype="DERPUsable";
		}
		invoker.inventorytype=inventorytype;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		super.DrawHUDStuff(sb,hdw,hpl);
		if(hpl.player.cmd.buttons&BT_ATTACK)return;
		int yofss=weaponstatus[INCS_YOFS]-((hpl.player.cmd.buttons&BT_ALTATTACK)?(50+5*hpl.flip):60);
		vector2 bob=(hpl.wepbob.x*0.2,hpl.wepbob.y*0.2+yofss);
		if(inventorytype=="HDFragGrenadeAmmo"){
			sb.drawimage(
				(weaponstatus[0]&INCF_PINOUT)?"FRAGF0":"FRAGA0",
				bob,sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.6,1.6)
			);
		}else if(inventorytype==NSHBers){
			sb.drawimage("PSTRA0",bob,sb.DI_SCREEN_CENTER_BOTTOM,scale:(2.,2.));
		}else if(inventorytype==NSHStim){
			sb.drawimage("STIMA0",bob,sb.DI_SCREEN_CENTER_BOTTOM,scale:(2.,2.));
		}else if(inventorytype=="DERPUsable"){
			sb.drawimage("DPICA5",bob,sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TRANSLATABLE,scale:(2.,2.));
		}
	}
	override string gethelptext(){LocalizeHelp();
		return
		LWPHELP_FIRE..StringTable.Localize("$CRAWWH_FIRE")
		..LWPHELP_RELOAD..StringTable.Localize("$CRAWWH_RELOAD")
		..LWPHELP_ALTFIRE..StringTable.Localize("$CRAWWH_ALTFIRE")
		..LWPHELP_FIREMODE..StringTable.Localize("$CRAWWH_FMODE")
		..((
			hdplayerpawn(owner)
			&&hdplayerpawn(owner).incapacitated
			&&hdplayerpawn(owner).incaptimer<1
		)?(WEPHELP_BTCOL..StringTable.Localize("$CRAWWH_JUMP")..WEPHELP_RGCOL..StringTable.Localize("$CRAWWH_GETUP")):"")
		;
	}
	Override Void PostBeginPlay()
	{
		NSHStim = "NSHPortableStimpack";
		NSHBers = "PortableBerserkpack";
		Super.PostBeginPlay();
	}
	states{
	nope:
		---- A 1 A_ClearRefire();
		---- A 0{
			if(player.cmd.buttons&(
					BT_ATTACK|
					BT_ALTATTACK|
					BT_RELOAD|
					BT_ZOOM|
					BT_USER1|
					BT_USER2|
					BT_USER3|
					BT_USER4|
					BT_JUMP
			))setweaponstate("nope");
			else setweaponstate("ready");
		}
	select:
		TNT1 A 30;
		goto nope;
	ready:
		TNT1 A 0 A_WeaponReady(WRF_ALLOWUSER2|WRF_ALLOWRELOAD|WRF_DISABLESWITCH);
		TNT1 A 1{
			invoker.weaponstatus[INCS_YOFS]=invoker.weaponstatus[INCS_YOFS]*2/3;
			A_SetHelpText();
		}
		goto readyend;
	try2:
		TNT1 A 0 A_SetTics(max(0,random(0,100-health)));
		goto super::try2;
	firemode:
		TNT1 A 1{
			int yofs=max(4,invoker.weaponstatus[INCS_YOFS]*3/2);
			if(
				yofs>100
				&&pressingfiremode()
			)setweaponstate("fumbleforsomething");
			else invoker.weaponstatus[INCS_YOFS]=yofs;
		}
		TNT1 A 0 A_JumpIf(pressingfiremode(),"firemode");
		goto readyend;
	fumbleforsomething:
		TNT1 A 20 A_StartSound("weapons/pocket",CHAN_WEAPON);
		TNT1 A 0 A_PickInventoryType();
		goto nope;
	altfire:
	althold:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&INCF_PINOUT,"holdfrag");
		TNT1 A 10 A_JumpIf(health<HDCONST_MINSTANDHEALTH&&!random(0,7),"nope");
		TNT1 A 20 A_StartSound("weapons/pocket",CHAN_WEAPON);
		TNT1 A 0 A_JumpIf(!countinv(invoker.inventorytype),"fumbleforsomething");
		TNT1 A 0 A_JumpIf(invoker.inventorytype=="DERPUsable","throwderp");
		TNT1 A 0 A_JumpIf(invoker.inventorytype=="HDFragGrenadeAmmo","pullpin");
		TNT1 A 0 A_JumpIf(
			!HDWoundFixer.CheckCovered(self,true)
			&&(
				invoker.inventorytype=="PortableStimpack"
				||invoker.inventorytype=="PortableBerserkpack"
			)
			,"injectstim");
		goto nope;
	injectstim:
		TNT1 A 1{
			A_SetBlend("7a 3a 18",0.1,4);
			A_MuzzleClimb(0,2,wepdot:false);
			A_PlaySkinSound(SKINSOUND_MEDS,"*usemeds");
			A_StartSound("misc/bulletflesh",CHAN_WEAPON,CHANF_OVERLAP);

			actor a=spawn(invoker.injecttype,pos,ALLOW_REPLACE);
			a.accuracy=40;a.target=self;
		}
		TNT1 A 4 A_MuzzleClimb(0,-0.5,0,-0.5,0,-0.5,0,-0.5,wepdot:false);
		TNT1 A 6;
		TNT1 A 0{
			let iii=HDWeapon(findinventory(invoker.inventorytype));
			if(!!iii){
				iii.weaponstatus[0]|=INJECTF_SPENT;
				DropInventory(iii,1);
			}
			invoker.inventorytype="";
		}
		goto nope;
	pullpin:
		TNT1 A 3 A_JumpIf(health<HDCONST_MINSTANDHEALTH&&!random(0,4),"readyend");
		TNT1 A 0{
			if(!countinv(invoker.inventorytype))return;
			invoker.weaponstatus[0]|=INCF_PINOUT;
			A_StartSound("weapons/fragpinout",CHAN_WEAPON,CHANF_OVERLAP);
			A_TakeInventory(invoker.inventorytype,1);
		}
		//fallthrough
	holdfrag:
		TNT1 A 2 A_ClearRefire();
		TNT1 A 0{
			int buttons=player.cmd.buttons;
			if(buttons&BT_RELOAD)setweaponstate("pinbackin");
			else if(buttons&BT_ALTFIRE)setweaponstate("holdfrag");
		}
		TNT1 A 10;
		TNT1 A 0{invoker.DropFrag();}
		goto readyend;
	pinbackin:
		TNT1 A 10;
		TNT1 A 0 A_JumpIf(health<HDCONST_MINSTANDHEALTH&&!random(0,2),"holdfrag");
		TNT1 A 20{
			A_StartSound("weapons/fragpinout",CHAN_WEAPON);
			invoker.weaponstatus[0]&=~INCF_PINOUT;
			A_GiveInventory("HDFragGrenadeAmmo",1);
		}
		goto nope;
	throwderp:
		TNT1 A 4 A_StartSound("weapons/pismagclick",CHAN_WEAPON);
		TNT1 A 2 A_StartSound("derp/crawl",CHAN_WEAPON,CHANF_OVERLAP);
		TNT1 A 1{
			let derpvoker=DERPUsable(findinventory("DERPUsable"));
			if(!derpvoker)return;
			if(derpvoker.weaponstatus[0]&DERPF_BROKEN){
				setweaponstate("readytorepair");
				return;
			}

			actor a;int b;
			[b,a]=A_SpawnItemEx("DERPBot",12,0,height*0.8,
				cos(pitch)*6,0,-sin(pitch)*6,0,
				SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|
				SXF_SETMASTER|SXF_TRANSFERTRANSLATION|SXF_SETTARGET
			);
			let derp=derpbot(a);
			derp.vel+=vel;
			derp.cmd=derpvoker.weaponstatus[DERPS_MODE];
			derp.botid=derpvoker.weaponstatus[DERPS_BOTID];
			derp.ammo=derpvoker.weaponstatus[DERPS_AMMO];

			DERPController.GiveController(self);

			derpvoker.goawayanddie();
			invoker.inventorytype="";
		}
		goto nope;
	}
	override void OwnerDied(){
		DropFrag();
		super.OwnerDied();
	}
	override void DetachFromOwner(){
		DropFrag();
		super.DetachFromOwner();
	}
	override inventory CreateTossable(){
		if(owner){
			owner.A_DropInventory("PortableMedikit");
			owner.A_DropInventory("HDMedikitter");
		}
		return null;
	}
	void DropFrag(){
		if(
			!(weaponstatus[0]&INCF_PINOUT)
			||!owner
		)return;
		weaponstatus[0]&=~INCF_PINOUT;
		//create the spoon
		owner.A_SpawnItemEx(spentinjecttype,
			-4,-3,owner.height-8,
			1,2,3,
			frandom(33,45),SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		//create the grenade
		owner.A_SpawnItemEx(injecttype,
			0,0,owner.height,
			2,0,-2,
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		inventorytype="";
	}
	enum CrawlingInts{
		INCF_PINOUT=1,
		INCS_YOFS=1,
		INCS_INDEX=2,
	}
}

