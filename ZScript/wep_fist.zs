// ------------------------------------------------------------
// Fist
// ------------------------------------------------------------
class HDFistPuncher:IdleDummy{
	default{
		+bloodlessimpact +nodecal +hittracer +puffonactors
		stamina 1;
	}
}

//Generalized for mod purposes
class HDWeaponGrabber:HDWeapon{
	actor grabbed;
	double grabangle;
	action void A_CheckGrabbing(){
		let grabbed=invoker.grabbed;
		let grabangle=invoker.grabangle;

		let grabrange=36.;
		if(hdplayerpawn(self))grabrange*=hdplayerpawn(self).heightmult;

		//if no grab target, find one
		if(!grabbed){
			flinetracedata glt;
			linetrace(
				angle,
				grabrange,
				pitch,
				TRF_ALLACTORS,
				height*0.67,
				data:glt
			);
			if(!glt.hitactor){
				A_ClearGrabbing();
				return;
			}
			let grbd=glt.hitactor;
			grabbed=grbd;
			grabangle=grbd.angle;
			invoker.grabangle=grabangle;
			invoker.grabbed=grbd;
		}

		//don't allow drag if standing on top of the thing being dragged
		if(
			pos.z-floorz>10
			&&!(pos.z-(grabbed.pos.z+grabbed.height))
			&&max(
				abs(pos.x-grabbed.pos.x),
				abs(pos.y-grabbed.pos.y)
			)<radius+grabbed.radius
		)return;

		bool resisting=(
			(
				grabbed.bismonster
				&&!grabbed.bnofear&&!grabbed.bghost //*ERPs use both of these flags
				&&grabbed.health>0
			)||(
				grabbed.player
				&&(
					!hdplayerpawn(grabbed)
					||!hdplayerpawn(grabbed).incapacitated
				)&&(
					grabbed.player.cmd.forwardmove
					||grabbed.player.cmd.sidemove
					||grabbed.player.cmd.pitch
					||grabbed.player.cmd.yaw
				)
			)
		);
		//chance to break away
		if(resisting){
			vel+=(frandom(-1,1),frandom(-1,1),frandom(-1,1));
			let grabbedmass=grabbed.mass;
			double strength=hdplayerpawn(self)?hdplayerpawn(self).strength:1.;
			if(frandom(grabbedmass*0.1,grabbedmass)>frandom(mass*0.6,mass*strength)){
				vector2 thrustforce=(cos(angle),sin(angle))*frandom(0.,2.);
				grabbed.vel.xy+=thrustforce*min(mass/grabbed.mass,1.);
				vel.xy-=thrustforce;
				A_ClearGrabbing();
				return;
			}
			if(absangle(angle,grabangle)>10)invoker.grabangle-=frandom(10,20);
			if(!random(0,7)){
				grabbed.damagemobj(self,self,1,"jointlock");
				double newgrangle=(grabbed.angle+angle)*0.5;
				grabbed.angle=newgrangle;
				invoker.grabangle=newgrangle;
			}
		}
		double massfactor=max(1.,grabbed.mass*(1./200.));
		if(massfactor>7.){
			A_ClearGrabbing();
			return;
		}

		double grangle=grabbed.angle*2;
		grabbed.A_SetAngle((grabangle+grangle)*0.333333333333333,SPF_INTERPOLATE);

		//drag
		double mindist=grabbed.radius+radius;

		double dragfactor=min(0.8,0.8*speed*mass/grabbed.mass);
		usercmd cmd=player.cmd;
		int fm=cmd.forwardmove>0?1:cmd.forwardmove<0?-1:0;
		int sm=cmd.sidemove>0?1:cmd.sidemove<0?-1:0;
		if(!sm&&fm<0)dragfactor*=1.7;

		vector2 dragmove=rotatevector((dragfactor*fm,-dragfactor*sm),angle)*player.crouchfactor;
		if(trymove(pos.xy+dragmove,true)){
			let p=HDPlayerPawn(self);
			if(p)p.movehijacked=true;
		}

		let gdst=grabbed.maxstepheight;
		let gddo=grabbed.bnodropoff;
		grabbed.maxstepheight=maxstepheight;
		grabbed.bnodropoff=false;
		grabbed.trymove(grabbed.pos.xy+dragmove,true);
		grabbed.maxstepheight=gdst;
		grabbed.bnodropoff=gddo;
		grabbed.setz(max(grabbed.pos.z,grabbed.floorz));

		string grbng=StringTable.Localize("$FIST_DRAG");
		if(grabbed.bcorpse){grbng=grbng..StringTable.Localize("$FIST_CORPSE"); setweaponstate("Grabcorpse");}
		else if(inventory(grabbed)||hdupk(grabbed)){grbng=grbng..StringTable.Localize("$FIST_ITEM"); setweaponstate("Grabitem");}
		else {grbng=grbng..StringTable.Localize("$FIST_OBJECT"); setweaponstate("Grabcorpse");}
		if(hd_debug>0)grbng=grbng.."\n"..HDMath.GetName(grabbed);
		A_WeaponMessage(grbng.."...",3);

		if(
			absangle(angle,angleto(grabbed))>60.
			||distance3d(grabbed)>(mindist+16)
		){
			A_ClearGrabbing();
			return;
		}
		invoker.grabangle=angle;
	}
	action void A_ClearGrabbing(){
		let p=HDPlayerPawn(self);if(p)p.movehijacked=false;
		invoker.grabbed=null;
		A_WeaponMessage("");
	}
	action void A_CheckDragging(){
		let grabbed=invoker.grabbed;
		let grabangle=invoker.grabangle;

		let grabrange=36.;
		if(hdplayerpawn(self))grabrange*=hdplayerpawn(self).heightmult;

		//if no grab target, find one
		if(!grabbed){
			flinetracedata glt;
			linetrace(
				angle,
				grabrange,
				pitch,
				TRF_ALLACTORS,
				height*0.67,
				data:glt
			);
			if(!glt.hitactor){
				A_ClearGrabbing();
				return;
			}
			let grbd=glt.hitactor;
			grabbed=grbd;
			grabangle=grbd.angle;
			invoker.grabangle=grabangle;
			invoker.grabbed=grbd;
		}

		//don't allow drag if standing on top of the thing being dragged
		if(
			pos.z-floorz>10
			&&!(pos.z-(grabbed.pos.z+grabbed.height))
			&&max(
				abs(pos.x-grabbed.pos.x),
				abs(pos.y-grabbed.pos.y)
			)<radius+grabbed.radius
		)return;

		bool resisting=(
			(
				grabbed.bismonster
				&&!grabbed.bnofear&&!grabbed.bghost //*ERPs use both of these flags
				&&grabbed.health>0
			)||(
				grabbed.player
				&&(
					!hdplayerpawn(grabbed)
					||!hdplayerpawn(grabbed).incapacitated
				)&&(
					grabbed.player.cmd.forwardmove
					||grabbed.player.cmd.sidemove
					||grabbed.player.cmd.pitch
					||grabbed.player.cmd.yaw
				)
			)
		);
		//chance to break away
		if(resisting){
			vel+=(frandom(-1,1),frandom(-1,1),frandom(-1,1));
			let grabbedmass=grabbed.mass;
			double strength=hdplayerpawn(self)?hdplayerpawn(self).strength:1.;
			if(frandom(grabbedmass*0.1,grabbedmass)>frandom(mass*0.6,mass*strength)){
				vector2 thrustforce=(cos(angle),sin(angle))*frandom(0.,2.);
				grabbed.vel.xy+=thrustforce*min(mass/grabbed.mass,1.);
				vel.xy-=thrustforce;
				A_ClearGrabbing();
				return;
			}
			if(absangle(angle,grabangle)>10)invoker.grabangle-=frandom(10,20);
			if(!random(0,7)){
				grabbed.damagemobj(self,self,1,"jointlock");
				double newgrangle=(grabbed.angle+angle)*0.5;
				grabbed.angle=newgrangle;
				invoker.grabangle=newgrangle;
			}
		}
		double massfactor=max(1.,grabbed.mass*(1./200.));
		if(massfactor>7.){
			A_ClearGrabbing();
			return;
		}

		double grangle=grabbed.angle*2;
		grabbed.A_SetAngle((grabangle+grangle)*0.333333333333333,SPF_INTERPOLATE);

		//drag
		double mindist=grabbed.radius+radius;

		double dragfactor=min(0.8,0.8*speed*mass/grabbed.mass);
		usercmd cmd=player.cmd;
		int fm=cmd.forwardmove>0?1:cmd.forwardmove<0?-1:0;
		int sm=cmd.sidemove>0?1:cmd.sidemove<0?-1:0;
		if(!sm&&fm<0)dragfactor*=1.7;

		vector2 dragmove=rotatevector((dragfactor*fm,-dragfactor*sm),angle)*player.crouchfactor;
		if(trymove(pos.xy+dragmove,true)){
			let p=HDPlayerPawn(self);
			if(p)p.movehijacked=true;
		}

		let gdst=grabbed.maxstepheight;
		let gddo=grabbed.bnodropoff;
		grabbed.maxstepheight=maxstepheight;
		grabbed.bnodropoff=false;
		grabbed.trymove(grabbed.pos.xy+dragmove,true);
		grabbed.maxstepheight=gdst;
		grabbed.bnodropoff=gddo;
		grabbed.setz(max(grabbed.pos.z,grabbed.floorz));

		string grbng=StringTable.Localize("$FIST_DRAG");
		if(grabbed.bcorpse){grbng=grbng..StringTable.Localize("$FIST_CORPSE"); setweaponstate("Draggingcorpse");}
		else if(inventory(grabbed)||hdupk(grabbed)){grbng=grbng..StringTable.Localize("$FIST_ITEM"); setweaponstate("Draggingitem");}
		else {grbng=grbng..StringTable.Localize("$FIST_OBJECT"); setweaponstate("Draggingcorpse");}
		if(hd_debug>0)grbng=grbng.."\n"..HDMath.GetName(grabbed);
		A_WeaponMessage(grbng.."...",3);

		if(
			absangle(angle,angleto(grabbed))>60.
			||distance3d(grabbed)>(mindist+16)
		){
			A_ClearGrabbing();
			return;
		}
		invoker.grabangle=angle;
	}
	states{
	grab:
		#### A 0 A_ClearGrabbing();
	grab2:
		#### A 1 offset(0,52) A_CheckGrabbing();
		/*#### A 1 offset(0,32);
		#### A 1 offset(0,40);
		#### A 1 offset(0,52);*/
		goto grabhold;
	grabhold:
		TNT1 V 1 A_CheckGrabbing();
		#### A 0 A_JumpIf(pressingfire(),"fire");
		#### A 0 A_JumpIf(pressingfiremode(),"grabhold");
		goto nope;
		
	DraggingCorpseH:
		PUNG U 1 {A_OverlayOffset(26,/*(+angle*2)+*/0, (-pitch*2)+100); invoker.bobrangex=invoker.default.bobrangex*0; invoker.bobrangey=invoker.default.bobrangey*0;}
		#### # 0 {invoker.bobrangex=invoker.default.bobrangex;; invoker.bobrangey=invoker.default.bobrangey;}
		Stop;
	grabcorpse:
		#### A 0 A_JumpIf(pressingfire(),"fire");
		#### A 0 A_JumpIf(!pressingfiremode(),"nope");
		PUNG YZ 1;
		PUNG [ 2;
	draggingcorpse:
		#### A 0 A_JumpIf(pressingfire(),"fire");
		#### A 0 A_JumpIf(!pressingfiremode(),"UnGrabCorpse");
		#### A 0 A_OverLay(26, "DraggingCorpseH");
		TNT1 V 1;
		#### # 0 A_CheckDragging();
	UnGrabCorpse:
		PUNG [ 2;
		PUNG ZY 2;
		Goto Nope;	
		
	DraggingItemH:
		PUNG T 1 {A_OverlayOffset(26, /*(+angle*2)+*/0, (-pitch*2)+100); invoker.bobrangex=invoker.default.bobrangex*0; invoker.bobrangey=invoker.default.bobrangey*0;}
		#### # 0 {invoker.bobrangex=invoker.default.bobrangex;; invoker.bobrangey=invoker.default.bobrangey;}
		Stop;
	grabitem:
		#### A 0 A_JumpIf(pressingfire(),"fire");
		#### A 0 A_JumpIf(!pressingfiremode(),"nope");
		PUNG VWX 1;
	draggingitem:
		#### A 0 A_JumpIf(pressingfire(),"fire");
		#### A 0 A_JumpIf(!pressingfiremode(),"UnGrabItem");
		#### A 0 A_OverLay(26, "DraggingItemH");
		TNT1 V 1;
		#### # 0 A_CheckDragging();
	UnGrabItem:
		PUNG XWV 2;
		Goto Nope;
	}
}


class HDFist:HDWeaponGrabber replaces Fist{
	int targettimer;
	int targethealth;
	int targetspawnhealth;
	bool flicked;
	bool washolding;
	default{
		+ambush
		+WEAPON.MELEEWEAPON +WEAPON.NOALERT +WEAPON.NO_AUTO_SWITCH
		+hdweapon.dontdisarm
		+hdweapon.dontnull
		+nointeraction
		obituary "$OB_FIST";
		weapon.selectionorder 100;
		weapon.kickback 120;
		weapon.bobstyle "Alpha";
		weapon.bobspeed 2.6;
		weapon.bobrangex 0.1;
		weapon.bobrangey 0.5;
		weapon.slotnumber 1;
		weapon.slotpriority 2;
		tag "$TAG_FIST";
		hdweapon.refid HDLD_FIST;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		let ww=HDFist(hdw);
		if(ww.targethealth)sb.drawwepnum(ww.targethealth,ww.targetspawnhealth);
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRE..StringTable.Localize("$FISTWH_FIRE")
		..LWPHELP_ALTFIRE..StringTable.Localize("$FISTWH_ALTFIRE")
		..LWPHELP_RELOAD..StringTable.Localize("$FISTWH_RELOAD")
		..LWPHELP_FIREMODE..StringTable.Localize("$FISTWH_FMODE")
		..LWPHELP_UNLOAD..StringTable.Localize("$FISTWH_UNLOAD")
		..LWPHELP_ZOOM.."+"..LWPHELP_SPEED.."+"..LWPHELP_USE..StringTable.Localize("$FISTWH_ZPSPED")
		..LWPHELP_ZOOM.."+"..LWPHELP_DROP..StringTable.Localize("$FISTWH_ZPDROP")
		;
	}
	override inventory CreateTossable(int amt){
		if(
			!owner
			||!owner.player
			||!(owner.player.cmd.buttons&BT_ZOOM)
		)return null;
		array<inventory> items;items.clear();
		for(inventory item=owner.inv;item!=null;item=!item?null:item.inv){
			if(
				inventory(item)
				&&item.binvbar
				&&!item.bishealth
			){
				items.push(item);
			}
		}
		if(!items.size()){
			if(!HDWoundFixer.DropMeds(owner,0))owner.A_DropInventory("SpareWeapons");
			return null;
		}
		double aang=owner.angle;
		double ch=items.size()?20.:0;
		owner.angle-=ch*(items.size()-1)*0.5;
		owner.player.cmd.buttons&=~BT_ZOOM;
		for(int i=0;i<items.size();i++){
			owner.a_dropinventory(items[i].getclassname(),items[i].amount);
			owner.angle+=ch;
		}
		owner.angle=aang;
		return null;
	}
	double strength;
	bool zerk;
	action void A_StrengthTics(int mintics,int maxtics=-1){
		if(invoker.strength==1.)return;
		if(maxtics<0)maxtics=tics;
		int ttt=min(maxtics,int(tics/invoker.strength));
		A_SetTics(max(mintics,int(ttt)));
	}
	override void DoEffect(){
		super.DoEffect();
		if(targettimer<70)targettimer++;else{
			tracer=null;
			targettimer=0;
			targethealth=0;
		}
		let hdp=hdplayerpawn(owner);

		strength=hdp?hdp.strength:1.;
		zerk=HDZerk.IsZerk(owner);

		if(zerk){
			strength*=1.2;
			if(!random[zrkbs](0,70)){
				string zrkbs[]={"$FIST_KILL1","$FIST_KILL2","$FIST_KILL3","$FIST_KILL4","$FIST_KILL5","$FIST_KILL6","$FIST_KILL7","$FIST_KILL8","$FIST_KILL9","$FIST_KILL10","$FIST_KILL11","$FIST_KILL12","$FIST_KILL13","$FIST_KILL14","$FIST_KILL15","$FIST_KILL16","$FIST_KILL17","$FIST_KILL18","$FIST_KILL19"};
				hdp.usegametip("\cr"..Stringtable.Localize(zrkbs[random(0,zrkbs.size()-1)]));
			}
		}
	}
	action void A_DontFreedoomFrameB(){
		if(
			Wads.CheckNumForName("freedoom",0)!=-1
			&&player.findPSprite(PSP_WEAPON).sprite==getspriteindex("PUNGA0")
		)player.findPSprite(PSP_WEAPON).frame++;
	}
	action void A_CheckFistSprite(statelabel st,int layer=PSP_WEAPON){
		if(!player)return;
		bool usegender=false;
		int fspr;
		let hpl=hdplayerpawn(self);
		if(!hpl)usegender=true;else{
			fspr=hpl.fistsprite;  //set the fist sprite
			if(fspr<0){
				//if no valid fist sprite indicated, use mugshot
				string mugshot=hpl.mugshot;
				if(mugshot~=="STF")fspr=getspriteindex("PUNGA0");
				else if(mugshot~=="SFF")fspr=getspriteindex("PUNFA0");
				else if(mugshot~=="STC")fspr=getspriteindex("PUNCA0");
				else usegender=true;  //if mugshot is not determinative, use gender
			}
		}
		if(usegender)switch(player.getgender()){
			case 0:fspr=getspriteindex("PUNGA0");break;
			case 1:fspr=getspriteindex("PUNFA0");break;
			case 2:fspr=getspriteindex("PUNFA0");break;
			case 3:fspr=getspriteindex("PUNCA0");break;
			default:fspr=getspriteindex("PUNCA0");break;
		}
		player.findPSprite(layer).sprite=fspr;
	}
	action void HDPunch(double dmg){
		let punchrange=48.;
		if(hdplayerpawn(self))punchrange*=hdplayerpawn(self).heightmult;

		flinetracedata punchline;
		bool punchy=linetrace(
			angle,punchrange,pitch,
			TRF_NOSKY,
			offsetz:height*0.77,
			data:punchline
		);
		if(!punchy)return;

		//actual puff effect if the shot connects
		LineAttack(
			angle,
			punchrange,
			pitch,
			punchline.hitline?(int(frandom(5,15)*invoker.strength)):0,
			"none",
			(invoker.strength>1.5)?"BulletPuffMedium":"BulletPuffSmall",
			flags:LAF_NORANDOMPUFFZ|LAF_OVERRIDEZ,
			offsetz:height*0.78
		);

		if(!punchline.hitactor){
			HDF.Give(self,"WallChunkAmmo",1);
			if(punchline.hitline)doordestroyer.CheckDirtyWindowBreak(punchline.hitline,0.03+0.01*invoker.strength,punchline.hitlocation);
			return;
		}
		actor punchee=punchline.hitactor;


		//charge!
		if(invoker.flicked)dmg*=1.5;
		else dmg+=HDMath.TowardsEachOther(self,punchee)*3;

		//come in swinging
		let onr=hdplayerpawn(self);
		double ptch=0.;
		double pyaw=0.;
		if(onr){
			ptch=deltaangle(onr.lastpitch,onr.pitch);
			pyaw=deltaangle(onr.lastangle,onr.angle);
			double iy=max(abs(ptch),abs(pyaw));
			if(pyaw<0)iy*=1.6;
			if(player.onground)dmg+=min(abs(iy)*5,dmg*3);
		}

		//shit happens
		dmg*=invoker.strength*frandom(1.,1.2);

		//other effects
		if(
			onr
			&&!punchee.bdontthrust
			&&(
				punchee.mass<200
				||(
					punchee.radius*2<punchee.height
					&& punchline.hitlocation.z>punchee.pos.z+punchee.height*0.6
				)
			)
		){
			if(abs(pyaw)>(0.5)){
				punchee.A_SetAngle(clamp(normalize180(punchee.angle-pyaw*100),-50,50),SPF_INTERPOLATE);
			}
			if(abs(ptch)>(0.5*65535/360)){
				punchee.A_SetPitch(clamp((punchee.angle+ptch*100)%90,-30,30),SPF_INTERPOLATE);
			}
		}

		let hdmp=hdmobbase(punchee);

		//headshot lol
		if(
			!punchee.bnopain
			&&punchee.health>0
			&&(
				!hdmp
				||!hdmp.bheadless
			)
			&&punchline.hitlocation.z>punchee.pos.z+punchee.height*0.75
		){
			if(hd_debug)A_Log("HEAD SHOT");
			hdmobbase.forcepain(punchee);
			dmg*=frandom(1.1,1.8);
			if(hdmp)hdmp.stunned+=(int(dmg)>>2);
		}

		if(hd_debug)A_Log("Punched "..punchee.getclassname().." for "..int(dmg).." damage!");

		bool puncheewasalive=!punchee.bcorpse&&punchee.health>0;

		if(dmg*2>punchee.health)punchee.A_StartSound("misc/bulletflesh",CHAN_AUTO);
		punchee.damagemobj(self,self,int(dmg),"melee");

		if(!punchee)invoker.targethealth=0;else{
			invoker.targethealth=punchee.health;
			invoker.targetspawnhealth=punchee.spawnhealth();
			invoker.targettimer=0;
			if(
				(
					punchee.bismonster
					||!!punchee.player
				)
				&&invoker.zerk
			){
				if(
					punchee.bcorpse
					&&puncheewasalive
				){
					A_StartSound("weapons/zerkding2",CHAN_WEAPON,CHANF_OVERLAP|CHANF_LOCAL);
					givebody(10);
					if(onr){
						onr.fatigue-=onr.fatigue>>2;
						onr.usegametip("\cfK I L L !");
					}
				}else{
					A_StartSound("weapons/zerkding",CHAN_WEAPON,CHANF_OVERLAP|CHANF_LOCAL);
				}
			}
		}
	}
	states{
	preload:
		PUNF ABCD 0;
		PUNG ABCD 0;
		PUNC ABCD 0;
		goto nope;
	ready:
		TNT1 A 1{
			if(
				invoker.washolding
				&&player.cmd.buttons&(
					BT_ATTACK
					|BT_ALTATTACK
					|BT_RELOAD
					|BT_ZOOM
					|BT_USER1
					|BT_USER2
					|BT_USER3
					|BT_USER4
				)
			){
				setweaponstate("nope");
				return;
			}
			A_WeaponReady(WRF_ALL);
			invoker.flicked=false;
			invoker.washolding=false;
		}goto readyend;
	reload:
		TNT1 A 0 A_CheckFistSprite("flick");
	flick:
		#### A 1 offset(0,50);
		#### A 1 offset(0,36);
		#### AAAAAAA 0 A_CustomPunch((int(ceil(invoker.strength))),1,CPF_PULLIN,"HDFistPuncher",36);
		#### AA 1 offset(0,38){invoker.flicked=true;}
		#### A 1 offset(0,42);
		#### A 1 offset(0,50);
		goto fire;
	fire:
	hold:
	althold:
		TNT1 A 0 A_CheckFistSprite("startfire");
	startfire:
	punch:
		#### B 0 offset(0,32) A_DontFreedoomFrameB();
		---- A 1 A_StrengthTics(0,2);
		#### D 0 A_Recoil(min(0,1.-invoker.strength));
		#### D 0 HDPunch(12);
		#### D 6 A_StrengthTics(3,10);
		#### C 3 A_StrengthTics(1,5);
		#### B 0 A_DontFreedoomFrameB();
		---- A 3 A_StrengthTics(0,5);
		TNT1 A 5;
		TNT1 A 0 A_JumpIf(pressingaltfire(),"altfire");
		TNT1 A 1 A_ReFire();
		goto ready;
	altfire:
	bodycheck:
		TNT1 A 3{
			let hdp=hdplayerpawn(self);

			if(
				hdp.fatigue>HDCONST_SPRINTFATIGUE
				||hdp.stunned>0
				||hdp.strength<0.9
				||(
					!player.onground
					&&checkmove(pos.xy-(cos(angle),sin(angle))*4)
				)
			){
				setweaponstate("fire");
				return;
			}

			hdp.fatigue+=4;
			A_ChangeVelocity(
				hdp.strength*(invoker.zerk?8:6)/max(1.,hdp.overloaded),
				0,0,CVF_RELATIVE
			);
		}
		goto nope;
	firemode:
	grab:
		TNT1 A 0 A_ClearGrabbing();
		TNT1 A 0 A_CheckFistSprite("grab2");
		goto grab2;
	spawn:
		TNT1 A 1;
		stop;
	}
}

extend class HDWeapon{
	action void A_FistNope(){
		hdweaponselector.select(self,"HDFist");
		let fff=HDFist(findinventory("HDFist"));
		fff.washolding=true;
		A_ClearRefire();
		A_WeaponReady(WRF_NOFIRE);
	}
}
