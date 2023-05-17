//-------------------------------------------------
// Stims and berserk
//-------------------------------------------------
class HDInjectorMaker:HDMagAmmo{
	class<weapon>injectortype;
	property injectortype:injectortype;
	override bool IsUsed(){return true;}
	default{
		+inventory.invbar
	}
	states{
	use:
		TNT1 A 0{
			A_GiveInventory(invoker.injectortype);
			hdweaponselector.select(self,"HDFist",0);
			hdweaponselector.select(self,invoker.injectortype,2);
		}
		fail;
	}
}

class HDDrug:HDDamageHandler{
	default{
		+inventory.undroppable
		inventory.maxamount 1000000;
		HDDamageHandler.priority -1000;
		HDPickup.overlaypriority -1;
	}
	override void PreTravelled(){amount=0;}
	override void OwnerDied(){amount=0;}
	states{
	spawn:
		TNT1 A 0;
		stop;
	}
	/*
		There's no prioritization system in place for these
		the way there is for worn items. This is an intentional
		design choice - everything *should* be fighting each other.

		To avoid unintentionally aberrant behaviour,
		make sure no modifications involve setting absolutely or
		clamping the modified value - all things should be done as
		"if more/less than X, do Y".

		Anything that wins out over something else is doing so by
		virtue of faster rate and bigger numbers.
	*/
	virtual void OnHeartbeat(hdplayerpawn hdp){}
	override void Tick(){
		super.Tick();
		if(amount<1)destroy();
	}
}
class PortableStimpack:HDInjectorMaker{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Stimpack"
		//$Sprite "STIMA0"

		scale 0.37;
		-hdpickup.droptranslation
		inventory.pickupmessage "Picked up a stimpack.";
		inventory.icon "STIMA0";
		hdpickup.bulk ENC_STIMPACK;
		tag "stimpack";
		hdpickup.refid HDLD_STIMPAK;
		+inventory.ishealth
		hdinjectormaker.injectortype "HDStimpacker";
	}
	states{
	spawn:
		STIM A -1;
	}
}
enum InjectorWeapon{
	INJECTF_SPENT=1,
	INJECTS_AMOUNT=1,
}
class HDStimpacker:HDWoundFixer{
	class<actor> injecttype;property injecttype:injecttype;
	class<actor> spentinjecttype;property spentinjecttype:spentinjecttype;
	class<inventory> inventorytype;property inventorytype:inventorytype;
	string injectoricon;property injectoricon:injectoricon;
	class<inventory> injectortype;property injectortype:injectortype;
	string mainhelptext;property mainhelptext:mainhelptext;

	override string,double getpickupsprite(){return "STIMA0",1.;}
	override string gethelptext(){return WEPHELP_INJECTOR;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		sb.drawimage(
			injectoricon,(-23,-7),
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT
		);
	}
	default{
		hdstimpacker.injecttype "InjectStimDummy";
		hdstimpacker.spentinjecttype "SpentStim";
		hdstimpacker.inventorytype "PortableStimpack";
		weapon.selectionorder 1003;
		hdstimpacker.injectoricon "STIMA0";
		hdstimpacker.injectortype "PortableStimpack";
		tag "stimpack";
		hdstimpacker.mainhelptext "\cd<<< \cjSTIMPACK \cd>>>\c-\n\n\nStimpacks help reduce\nbleeding temporarily\n\nand boost performance when injured.\n\n\Press altfire to use on someone else.\n\n\cgDO NOT OVERDOSE.";
	}
	action void A_SpawnSpent(){invoker.SpawnSpent(self);}
	actor SpawnSpent(actor onr){
		if(!onr)return null;
		actor a=onr.spawn(spentinjecttype,(onr.pos+HDMath.GetGunPos(onr)),ALLOW_REPLACE);
		if(!a)return null;
		a.target=onr;
		a.angle=onr.angle;a.vel=onr.vel;a.A_ChangeVelocity(-2,1,4,CVF_RELATIVE);
		a.A_StartSound("weapons/grenopen",CHAN_VOICE);
		return a;
	}
	states{
	//don't use a CreateTossable override - we need the throwing stuff
	spawn:
		TNT1 A 1; //DO NOT REMOVE DELAY
		TNT1 A 0{
			if(invoker.weaponstatus[0]&INJECTF_SPENT){
				let aa=invoker.SpawnSpent(target);
				aa.vel=vel;
				return;
			}

			let a=HDInjectorMaker(spawn(invoker.inventorytype,invoker.pos,ALLOW_REPLACE));
			if(!a)return;
			a.mags[0]=invoker.weaponstatus[INJECTS_AMOUNT];
			a.angle=self.angle;a.vel=self.vel;
			a.target=self;
			a.vel=vel;

			//if dropped while sprinting, treat as dropped one from inventory
			let hdp=HDPlayerPawn(target);
			if(
				!!hdp
				&&!!hdp.player
				&&!!NullWeapon(hdp.player.readyweapon)
			){
				let iii=HDInjectorMaker(hdp.findinventory(invoker.inventorytype));
				if(
					!!iii
					&&iii.amount>0
				){
					iii.SyncAmount();
					a.mags[0]=iii.mags[0];

					invoker.weaponstatus[0]^=~INJECTF_SPENT;
					invoker.weaponstatus[INJECTS_AMOUNT]=iii.mags[0];
					iii.mags.delete(0);
					iii.amount--;
				}
			}
		}
		stop;
	select0:
		STIS A 1{
			bool helptext=DoHelpText();
			if(helptext)A_WeaponMessage(invoker.mainhelptext);
			A_StartSound("weapons/pocket",8,CHANF_OVERLAP,volume:0.5);

			//take away one item in inventory.
			//the way deselect works, the only way you can have a fresh hdstimpacker
			//while having no stimpacks to draw from is if you cheated to obtain it,
			//which should be respected as = cheating to obtain one stimpack.
			let iii=HDInjectorMaker(findinventory(invoker.inventorytype));
			if(
				!!iii
				&&iii.amount>0
			){
				iii.SyncAmount();
				invoker.weaponstatus[0]^=~INJECTF_SPENT;
				invoker.weaponstatus[INJECTS_AMOUNT]=iii.mags[0];
				iii.mags.delete(0);
				iii.amount--;
			}
		}
		STIS A 1 A_Raise(0);
		STIS A 1 A_Raise(26);
		STIS A 1 A_Raise(18);
		Goto Open;
	Open:
		TNT1 A 0 A_StartSound("weapons/pocket",8,CHANF_OVERLAP,volume:0.7);
		STIS BBBCCDD 1 A_WeaponReady(WRF_NOFIRE);
		TNT1 A 0 A_StartSound("weapons/pocket",8,CHANF_OVERLAP,volume:0.7);
		STIS EEFGGHHII 1;
		Goto ReadyEnd;
	deselect:
		TNT1 A 5 A_StartSound("weapons/pocket",8,CHANF_OVERLAP,volume:0.5);
		TNT1 A 0{
			if(invoker.weaponstatus[0]&INJECTF_SPENT){
				DropInventory(invoker);
				return;
			}
			HDMagAmmo.GiveMag(self,invoker.inventorytype,invoker.weaponstatus[INJECTS_AMOUNT]);
		}
		TNT1 A 0 A_Lower(999);
		wait;
	ready:
		STIG A 1{
			if(invoker.weaponstatus[0]&INJECTF_SPENT)DropInventory(invoker);
			A_WeaponReady();
		}
		Goto ReadyEnd;
	None:
		TNT1 A 1;
		Stop;
	Leg:
		STLG A 1 {A_OverlayFlags(-26,PSPF_PLAYERTRANSLATED,1);A_OverlayOffset(-26, 0, (-pitch*2)+200);}
		Loop;
	fire:
	hold:
		TNT1 A 0 A_OverLay(-26,"Leg");
		STIG A 1;
		STIG A 0{
			if(hdplayerpawn(self))hdplayerpawn(self).gunbraced=false;
			if(invoker.weaponstatus[0]&INJECTF_SPENT){
				A_OverLay(-26,"None");
				return resolvestate("nope");
			}
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				A_TakeOffFirst(blockinv.gettag(),2);
				A_OverLay(-26,"None");
				return resolvestate("nope");
			}
			if(pitch<90){
				A_MuzzleClimb(0,8);
				A_Refire();
				return resolvestate(null);
			}
			return resolvestate("inject");
		}
		STIG A 0 A_OverLay(-26,"None");
		goto nope;
	inject:
		STIF CD 2;
		STIF E 2{
			A_SetBlend("7a 3a 18",0.1,4);
			A_MuzzleClimb(0,2);
			if(hdplayerpawn(self))A_StartSound(hdplayerpawn(self).medsound,CHAN_VOICE);
			else A_StartSound("*usemeds",CHAN_VOICE);
			A_StartSound("misc/injection",CHAN_WEAPON,CHANF_OVERLAP);
			actor a=spawn(invoker.injecttype,pos,ALLOW_REPLACE);
			a.accuracy=40;a.target=self;
			invoker.weaponstatus[0]|=INJECTF_SPENT;}
		STIF F 4;
		STIF GGG 1 A_MuzzleClimb(0,-10);
		TNT1 AAA 1 A_MuzzleClimb(0,-10);
		TNT1 A 0 A_OverLay(-26,"None");
		goto nope;
	altfire:
		STIF C 2;
		TNT1 A 0 A_Refire();
		goto nope;
	althold:
		STIF H 2;
		TNT1 A 0{
			bool helptext=DoHelpText();
			flinetracedata injectorline;
			linetrace(
				angle,42,pitch,
				offsetz:gunheight()-2,
				data:injectorline
			);
			let c=HDPlayerPawn(injectorline.hitactor);
			if(!c){
				let ccc=HDHumanoid(injectorline.hitactor);
				if(
					ccc
					&&invoker.getclassname()=="HDStimpacker"
				){
					if(
						ccc.stunned<100
						||ccc.health<10
					){
						if(helptext)A_WeaponMessage("They don't need it.",2);
						return resolvestate("UnInject");
					}
					return resolvestate("Injecting");
				}}
				if(helptext)A_WeaponMessage("Nothing to be done here.\n\nStimulate thyself? (press fire)");
				return resolvestate("UnInject");
			}
		Goto Injection;	
		Injecting:
		STIF HIJ 2;
		TNT1 A 0{bool helptext=DoHelpText();
			flinetracedata injectorline;
			linetrace(
				angle,42,pitch,
				offsetz:gunheight()-2,
				data:injectorline
			);
			let ccc=HDHumanoid(injectorline.hitactor);
					ccc.A_StartSound(ccc.painsound,CHAN_VOICE);
					ccc.stunned=max(0,ccc.stunned>>1);}
		STIF JJKKLM	2;
		TNT1 A 0{invoker.weaponstatus[0]|=INJECTF_SPENT;}
		Goto Nope;
		UnInject:
		STIF C 6 A_Refire();
		Goto Nope;
		Injection:
		STIF HIJ 2;
		TNT1 A 0{
			bool helptext=DoHelpText();
			flinetracedata injectorline;
			linetrace(
				angle,42,pitch,
				offsetz:gunheight()-2,
				data:injectorline
			);
			let c=HDPlayerPawn(injectorline.hitactor);
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				if(helptext)A_WeaponMessage("You'll need them to take off their "..blockinv.gettag().."...");
				return resolvestate("InjectFail");
			}
			if(IsMoving.Count(c)>4){
				bool chelptext=DoHelpText(c);
				if(c.countinv("HDStim")){
					if(chelptext)HDWeapon.ForceWeaponMessage(c,string.format("Run away!!!\n\n%s is trying to overdose you!",player.getusername()));
					if(helptext)A_WeaponMessage("They seem a bit fidgety...");
				}else{
					if(chelptext)HDWeapon.ForceWeaponMessage(c,string.format("Stop squirming!\n\n%s only wants to\n\ngive you some drugs...",player.getusername()));
					if(helptext)A_WeaponMessage("You'll need them to stay still...");
				}
				return resolvestate("InjectFail");
			}
			if(
				//because poisoning people should count as friendly fire!
				(teamplay || !deathmatch)&&
				(
					(
						invoker.injecttype=="InjectStimDummy"
						&& c.countinv("HDStim")
					)||
					(
						invoker.injecttype=="InjectZerkDummy"
						&& c.countinv("HDZerk")>HDZerk.HDZERK_COOLOFF
					)
				)
			){
				if(DoHelpText(c))HDWeapon.ForceWeaponMessage(c,string.format("Run away!!!\n\n%s is trying to overdose you!",player.getusername()));
				if(DoHelpText())A_WeaponMessage("They seem a bit fidgety already...");
				return resolvestate("InjectFail");
			}
			//and now...
			return resolvestate("injectDone");
		}
		Goto Nope;
	InjectFail:
		STIF JKC 2;
		Goto ReadyEnd;
	injectDone:
		STIF J 1{flinetracedata injectorline;
			linetrace(
				angle,42,pitch,
				offsetz:gunheight()-2,
				data:injectorline
			);
			let c=HDPlayerPawn(injectorline.hitactor);
			c.A_StartSound(hdplayerpawn(c).medsound,CHAN_VOICE);
			c.A_SetBlend("7a 3a 18",0.1,4);
			actor a=spawn(invoker.injecttype,c.pos,ALLOW_REPLACE);
			a.accuracy=40;a.target=c;}
		STIF JJKKLM 2;
		TNT1 A 0 {invoker.weaponstatus[0]|=INJECTF_SPENT;}
		Goto Nope;
	injected:
		TNT1 A 8;
		goto nope;
	}
}
class InjectStimDummy:IdleDummy{
	hdplayerpawn tg;
	states{
	spawn:
		TNT1 A 6 nodelay{
			tg=HDPlayerPawn(target);
			if(!tg||tg.bkilled){destroy();return;}
			if(tg.countinv("HDZerk")>HDZerk.HDZERK_COOLOFF)tg.aggravateddamage+=int(ceil(accuracy*0.01*random(1,3)));
		}
		TNT1 A 1{
			if(!target||target.bkilled){destroy();return;}
			HDF.Give(target,"HDStim",HDStim.HDSTIM_DOSE);
		}stop;
	}
}
class HDStim:HDDrug{
	enum StimAmounts{
		HDSTIM_DOSE=400,
		HDSTIM_MAX=480,
	}
	override void doeffect(){
		let hdp=hdplayerpawn(owner);

		double ret=min(0.1,amount*0.003);
		if(hdp.strength<1.+ret)hdp.strength+=0.003;
	}
	override void OnHeartbeat(hdplayerpawn hdp){
		if(amount<1)return;
		int amt=amount;amount--;

		if(amt>HDSTIM_MAX){

			if(hdp.beatcap>max(6,20-(amount>>5)))hdp.beatcap--;

			if(hdp.stunned<10)hdp.stunned+=2;

			if(
				hdp.bloodpressure<50-(hdp.bloodloss>>4)
			)hdp.bloodpressure+=4;

		}else{

			if(hdp.beatcap>30)hdp.beatcap--;

			if(
				hdp.runwalksprint<1
			){
				if(hdp.fatigue>0)hdp.fatigue--;
				if(hdp.stunned>0)hdp.stunned--;
			}

			if(
				hdp.bloodpressure<14-(hdp.bloodloss>>4)
			)hdp.bloodpressure+=3;
		}

		if(
			hdp.beatmax>=HDCONST_MINHEARTTICS+3
			&&hdp.fatigue<=HDCONST_SPRINTFATIGUE
			&&hdp.health<hdp.healthcap+(amt>>4)
			&&random(1,300)<amt
		){
			hdp.givebody(1);
			if(hdp.fatigue>0)hdp.fatigue--;
		}

		if(hd_debug>=4)console.printf("STIM "..amt.."/"..HDSTIM_MAX.."  = "..hdp.strength);
	}
}


class PortableBerserkPack:hdinjectormaker{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Berserk"
		//$Sprite "PSTRA0"

		inventory.pickupmessage "Picked up a berserk pack.";
		inventory.icon "PSTRA0";
		scale 0.3;
		hdpickup.bulk ENC_STIMPACK;
		tag "berserk pack";
		hdpickup.refid HDLD_BERSERK;
		+inventory.ishealth
		hdinjectormaker.injectortype "HDBerserker";
	}
	states{
	spawn:
		PSTR A -1 nodelay{if(invoker.amount>2)invoker.scale=(0.4,0.35);else invoker.scale=(0.3,0.3);}
	}
}
class HDBerserker:HDStimpacker{
	default{
		hdstimpacker.injecttype "InjectZerkDummy";
		hdstimpacker.spentinjecttype "SpentZerk";
		hdstimpacker.inventorytype "PortableBerserkPack";
		weapon.selectionorder 1002;
		hdstimpacker.injectoricon "PSTRA0";
		hdstimpacker.injectortype "PortableBerserkPack";
		tag "berserk pack";
		hdstimpacker.mainhelptext "\cr*** \caBERSERK \cr***\c-\n\n\nBerserk packs help increase\ncombat capabilities temporarily.\n\n\Press altfire to use on someone else.";
	}
	override string,double getpickupsprite(){return "PSTRA0",1.;}
}
class InjectZerkDummy:InjectStimDummy{
	states{
	spawn:
		TNT1 A 60 nodelay{
			tg=HDPlayerPawn(target);
		}
		TNT1 A 1{
			if(!tg||tg.bkilled){destroy();return;}

			if(tg.countinv("HDStim"))tg.aggravateddamage+=int(ceil(tg.countinv("HDStim")*0.05*random(1,3)));
			else tg.aggravateddamage++;

			let zzz=tg.findinventory("HDZerk");
			if(!zzz||zzz.amount<1){
				tg.A_GiveInventory("HDZerk",HDZerk.HDZERK_MAX);

				if(hdplayerpawn(tg))tg.A_StartSound(hdplayerpawn(tg).xdeathsound,CHAN_VOICE);
				else tg.A_StartSound("*xdeath",CHAN_VOICE);
				HDPlayerPawn.Disarm(self);
				tg.A_SelectWeapon("HDFist");
			}else{
				if(zzz.amount>HDZerk.HDZERK_COOLOFF){
					zzz.amount+=HDZerk.HDZERK_DURATION;
				}else{
					zzz.amount=HDZerk.HDZERK_MAX+(zzz.amount>>5);
				}
				if(hdplayerpawn(tg))tg.A_StartSound(hdplayerpawn(tg).painsound,CHAN_VOICE);
				else tg.A_StartSound("*pain",CHAN_VOICE);
			}
		}stop;
	}
}
class HDZerk:HDDrug{
	enum ZerkAmounts{
		HDZERK_DURATION=TICRATE*60*4,
		HDZERK_COOLOFF=TICRATE*60*5,
		HDZERK_MAX=HDZERK_COOLOFF+HDZERK_DURATION,
		HDZERK_OVER=HDZERK_MAX+HDZERK_COOLOFF,
	}
	override void DisplayOverlay(hdstatusbar sb,hdplayerpawn hpl){
		sb.SetSize(0,320,200);
		sb.BeginHUD(forcescaled:true);
		sb.fill(
			amount<HDZERK_COOLOFF?
				color(min(100,amount>>5)+(hpl.beatcount?random[zerkshit](-1,1):random[zerkshit](-5,5)),0,0,0)
				:color(min(100,(amount-HDZERK_COOLOFF)>>5)+(hpl.beatcount>>2),90,14,12),
			0,0,screen.getwidth(),screen.getheight()
		);
	}
	clearscope static bool IsZerk(actor zerker){
		return zerker.countinv("HDZerk")>HDZerk.HDZERK_COOLOFF;
	}
	override void DoEffect(){
		if(amount<1)return;
		int amt=amount;amount--;

		let hdp=hdplayerpawn(owner);
		if(amt==(HDZERK_COOLOFF+128))hdp.AddBlackout(256,2,4,24);

		bool iszerk=amt>HDZERK_COOLOFF;
		if(
			iszerk
			&&hdp.bloodloss<HDCONST_MAXBLOODLOSS
		){
			if(
				iszerk
				&&hdp.strength<3.
			)hdp.strength+=0.03;

			if(hdp.bloodpressure<40-(hdp.bloodloss>>4))hdp.bloodpressure++;
			if(amt>HDZERK_MAX){
				if(!random(0,7))hdp.damagemobj(hdp,hdp,random(1,5),"bashing",DMG_NO_ARMOR|DMG_NO_PAIN);
				if(!random(0,31))hdp.aggravateddamage++;
				if(hdp.beatcap>random(1,12))hdp.beatcap--;
			}else if(amt>(HDZERK_MAX-(TICRATE<<1))){
				if(hdp.strength<2.)hdp.strength+=0.05;
				hdp.stunned=max(hdp.stunned,10);
				hdp.muzzleclimb1+=(frandom(-2,2),frandom(-2,2));
				hdp.vel+=(frandom(-0.5,0.5),frandom(-0.5,0.5),frandom(-0.5,0.5));
				if(!random(0,3)){
					hdp.givebody(1);
					A_SetBlend("20 0a 0f",0.4,3);

					if(!random(0,int(8-amt*0.0005))){
						if(!random(0,7)){
							hdp.oldwoundcount++;
							if(amount<(HDZERK_MAX-(TICRATE<<2)))hdp.A_StartSound(hdp.painsound,CHAN_VOICE);
						}
						else if(!random(0,7))hdp.aggravateddamage++;
					}

					if(!HDFist(hdp.player.readyweapon)){
						hdp.Disarm(hdp);
						hdp.A_SelectWeapon("HDFist");
					}
				}
			}else if(amt>(HDZERK_MAX-(TICRATE<<3))){
				hdp.muzzleclimb1+=(frandom(-1,1),frandom(-1,1));
				hdp.vel+=(frandom(-0.1,0.1),frandom(-0.1,0.1),frandom(-0.1,0.1));
				if(hdp.fatigue>0)hdp.fatigue-=1;
				if(!random(0,3)){
					hdp.givebody(1);
					if(!HDFist(hdp.player.readyweapon)){
						hdp.Disarm(hdp);
						hdp.A_SelectWeapon("HDFist");
					}
				}
			}else if(iszerk){
				if(hdp.health<(hdp.healthcap<<2))hdp.givebody(1);
				if(hdp.stunned)hdp.stunned=hdp.stunned*4/5;
				if(hdp.fatigue>0&&!(level.time&(1|2)))hdp.fatigue-=1;
				if(hdp.incaptimer)hdp.incaptimer=hdp.incaptimer*14/15;
			}
		}else if(amt==HDZERK_COOLOFF){
			hdp.A_StartSound(hdp.painsound,CHAN_VOICE);
			if(!random(0,4))hdp.aggravateddamage+=random(1,3);
		}else if(amt>0){
			if(
				!countinv("HDStim")
				||!(level.time&(1|2|4))
			){
				if(hdp.stunned<40)hdp.stunned+=3;
				if(hdp.fatigue<HDCONST_SPRINTFATIGUE)hdp.fatigue++;
			}
		}

	}
	override void OnHeartbeat(hdplayerpawn hdp){
		if(amount<1)return;

		bool iszerk=(amount-HDZERK_COOLOFF)>0;

		//fatigue eventually overrides zerk
		if(hdp.fatigue>HDCONST_DAMAGEFATIGUE*1.4)
			hdp.damagemobj(self,hdp,hdp.beatmax+4,"internal");

		if(iszerk){
			hdp.beatmax=clamp(hdp.beatmax,4,14);

			if(!(hdp.beatcount%12)){
				//twitchy
				if(!IsMoving.Count(hdp)){
					if(hdp.floorz>=hdp.pos.z)
						hdp.A_ChangeVelocity(frandom(-2,3),frandom(-2,2),1,CVF_RELATIVE);

					if(!(hdp.player.cmd.buttons&BT_ATTACK))
						hdp.muzzledrift+=(random(-14,14),random(-24,14));
					else hdp.muzzledrift+=(frandom(-2,2),frandom(-3,2));
				}
			}
			if(
				amount<(HDZERK_MAX-(TICRATE<<2))
				&&!random(0,10)
			){
				sound yell=hdp.tauntsound;
				int yellwhich=random(1,100);
				if(yellwhich<20)yell=hdp.gruntsound;
				else if(yellwhich<40)yell=hdp.painsound;
				else if(yellwhich<60)yell=hdp.deathsound;
				else yell=hdp.xdeathsound;
				A_AlertMonsters();
				hdp.bspawnsoundsource=true;
				hdp.A_StartSound(yell,CHAN_VOICE);
			}

		}else if(amount>0){
			if(hdp.beatcap>HDCONST_MINHEARTTICS+random(1,70+countinv("HDStim")))hdp.beatcap--;
		}
	}
}




class SpentZerk:HDDebris{
	default{
		xscale 0.32;yscale 0.28;radius 3;height 3;
		bouncesound "misc/fragknock";
	}
	states{
	spawn:
		SYRB A 0;
	spawn2:
		---- A 1{
			A_SetRoll(roll+60,SPF_INTERPOLATE);
		}wait;
	death:
		---- A -1{
			roll=0;
			if(!random(0,1))scale.x*=-1;
		}stop;
	}
}
class SpentStim:SpentZerk{
	default{
		translation "176:191=80:95";
	}
	states{
	spawn:
		SYRG A 0 nodelay A_JumpIf(Wads.CheckNumForName("id",0)==-1,1);
		goto spawn2;
		STIM A 0 A_SetScale(0.37,0.37);
		STIM A 0 A_SetTranslation("FreeStimSpent");
		goto spawn2;
		death:
		---- A -1{
			if(Wads.CheckNumForName("id",0)!=-1)roll=0;
			else if(abs(roll)<20)roll+=40;
			if(!random(0,1))scale.x*=-1;
		}stop;
	}
}

class SpentBottle:SpentStim{
	default{
		alpha 0.6;renderstyle "translucent";
		bouncesound "misc/casing";bouncefactor 0.4;scale 0.3;radius 4;height 4;
		translation "10:15=241:243","150:151=206:207";
	}
	override void ondestroy(){
		plantbit.spawnplants(self,7,33);
		actor.ondestroy();
	}
	states{
	spawn:
		BON1 A 0;
		goto spawn2;
	death:
		---- A 100{
			if(random(0,7))roll=randompick(90,270);else roll=0;
			if(roll==270)scale.x*=-1;
		}
		---- A random(2,4){
			if(frandom(0.1,0.9)<alpha){
				angle+=random(-12,12);pitch=random(45,90);
				actor a=spawn("HDGunSmoke",pos,ALLOW_REPLACE);
				a.scale=(0.4,0.4);a.angle=angle;
			}
			A_FadeOut(frandom(-0.03,0.032));
		}wait;
	}
}
class SpentCork:SpentBottle{
	default{
		bouncesound "misc/casing3";scale 0.6;
		translation "224:231=64:71";
	}
	override void ondestroy(){
		plantbit.spawnplants(self,1,0);
		actor.ondestroy();
	}
	states{
	spawn:
		PBRS A 2 A_SetRoll(roll+90,SPF_INTERPOLATE);
		wait;
	}
}




