// ------------------------------------------------------------
// Rocket Launcher
// ------------------------------------------------------------
class HDRL:HDWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Rocket Launcher"
		//$Sprite "LAUNA0"

		+weapon.explosive
		weapon.selectionorder 92;
		weapon.slotnumber 5;
		weapon.slotpriority 1;
		weapon.bobrangex 0.3;
		weapon.bobrangey 0.9;
		scale 0.6;
		inventory.pickupmessage "$PICKUP_RL";
		obituary "$OB_ROCKET";
		hdweapon.barrelsize 32,3.1,5;
		hdweapon.refid HDLD_LAUNCHR;
		tag "$TAG_RL";

		hdweapon.ammo1 "HDRocketAmmo",1;
		hdweapon.ammo2 "HEATAmmo",1;

		hdweapon.loadoutcodes"
			\cuheat - 0/1, whether you start with a H.E.A.T. loaded
			\cugrenade - 0/1, whether you start in grenade mode
			\cunomag - 0-2, whether it is a single-shot (2 loads a H.E.A.T.)";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override void tick(){
		super.tick();
		drainheat(RLS_SMOKE,12);
	}
	override double gunmass(){
		return (weaponstatus[0]&RLF_NOMAG)?
			7+weaponstatus[RLS_CHAMBER]
			:(8+weaponstatus[RLS_MAG]+weaponstatus[RLS_CHAMBER]);
	}
	override double weaponbulk(){
		double blx=(weaponstatus[0]&RLF_NOMAG)?100:(125+weaponstatus[RLS_MAG]*ENC_ROCKETLOADED);

		int chmb=weaponstatus[RLS_CHAMBER];
		if(chmb>1)blx+=ENC_HEATROCKETLOADED;
		else if(chmb==1)blx+=ENC_ROCKETLOADED;
		return blx;
	}
	override void beginplay(){
		super.beginplay();
		weaponstatus[RLS_DOT]=3;
	}
	override string,double getpickupsprite(){return weaponstatus[0]&RLF_NOMAG?"LAUNB0":"LAUNA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("ROQPA0",(-47,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
			sb.drawimage("ROCKA0",(-58,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
			sb.drawnum(hpl.countinv("HDRocketAmmo"),-41,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			sb.drawnum(hpl.countinv("HEATAmmo"),-54,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		int ab=hdw.airburst;
		if(
			hdw.weaponstatus[RLS_CHAMBER]>1||
			!(hdw.weaponstatus[0]&RLF_GRENADEMODE)
		){
			if(hdw.weaponstatus[RLS_CHAMBER]>1){
				ab=0;
				sb.drawrect(-22,-15,3,2);
				sb.drawrect(-18,-15,2,2);
				sb.drawrect(-26,-17,4,6);
				sb.drawrect(-30,-16,4,4);
			}else{
				sb.drawrect(-22,-13,3,1);
				sb.drawrect(-18,-13,2,1);
				sb.drawrect(-26,-14,4,3);
			}
		}else{
			sb.drawrect(-26,-27+min(16,ab>>9),4,1);
			sb.drawrect(-23,-26,1,16);
			sb.drawrect(-25,-26,1,16);
		}
		if(ab)sb.drawstring(
			sb.mAmountFont,string.format("%.2f",ab*0.01),
			(-32,-15),sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,
			ab?Font.CR_WHITE:Font.CR_DARKGRAY
		);
		if(hdw.weaponstatus[RLF_SAFETY]==1)sb.drawimage("SAFETY",(-17,-16),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1,1));	
		if(!(hdw.weaponstatus[0]&RLF_NOMAG))sb.drawwepnum(hdw.weaponstatus[RLS_MAG],6);
		if(hdw.weaponstatus[RLS_CHAMBER]>0)sb.drawrect(-19,-11,3,1);
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRESHOOT
		..LWPHELP_ALTFIRE.."  "..(weaponstatus[0]&RLF_GRENADEMODE?StringTable.Localize("$RLWH_ROCK"):StringTable.Localize("$RLWH_GREN"))..StringTable.Localize("$RLWH_MODE")
		..(weaponstatus[RLS_CHAMBER]>1?(
			LWPHELP_ALTRELOAD..StringTable.Localize("$RLWH_OR")..LWPHELP_RELOAD..StringTable.Localize("$RLWH_REMOVHEAT")
		):(
			LWPHELP_ALTRELOAD..StringTable.Localize("$RLWH_LOAD")
			..LWPHELP_RELOADRELOAD
		))
		..LWPHELP_FIREMODE.."+"..LWPHELP_UPDOWN..StringTable.Localize("$RLWH_AIRBURST")
		..LWPHELP_UNLOADUNLOAD
		..LWPHELP_USE.."+"..LWPHELP_FIREMODE..StringTable.Localize("$LWPHELP_SAFETY")
		;
	}
	int rangefinder;
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int Light = Owner.CurSector.LightLEvel * 1.75;
		if(owner.player.fixedlightlevel==1)Light = 255;
		if(hdw.weaponstatus[0]&RLF_GRENADEMODE)sb.drawgrenadeladder(hdw.airburst,bob);
		else{
			double dotoff=max(abs(bob.x),abs(bob.y));

			if(dotoff<35){
				string whichdot=sb.ChooseReflexReticle(hdw.weaponstatus[RLS_DOT]);
				sb.drawimage(
					whichdot,(0,0)+bob*1.1,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					alpha:0.8-dotoff*0.01,scale:(0.8,0.8),
					col:0xFF000000|sb.crosshaircolor.GetInt()
				);
			}
			sb.drawimage(
				"rlrearsight",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);
			sb.drawimage(
				"rlrearsight",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER, col:color(254-Light, 0,0,0)
			);
			if(hdw.weaponstatus[RLS_CHAMBER]<=1){
				int airburst=hdw.airburst;
				if(airburst)sb.drawnum(airburst/100,
					10+bob.x,9+bob.y,sb.DI_SCREEN_CENTER,Font.CR_BLACK
				);
			}


			if(scopeview){
				double degree=4.;
				double deg=1/degree;
				int scaledyoffset=40;
				int scaledwidth=56;
				int cx,cy,cw,ch;
				[cx,cy,cw,ch]=screen.GetClipRect();
				sb.SetClipRect(
					bob.x-(scaledwidth>>1),bob.y+scaledyoffset-(scaledwidth>>1),
					scaledwidth,scaledwidth,
					sb.DI_SCREEN_CENTER
				);

				sb.fill(color(255,0,0,0),
					bob.x-27,scaledyoffset+bob.y-27,
					54,54,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
				);

				texman.setcameratotexture(hpc,"HDXCAM_RLAUN",degree);
				let cam  = texman.CheckForTexture("HDXCAM_RLAUN",TexMan.Type_Any);
				double camSize = texman.GetSize(cam);
				sb.DrawCircle(cam,(0,scaledyoffset)+bob*5,.085,usePixelRatio:true);

				screen.SetClipRect(cx,cy,cw,ch);

				sb.drawimage(
					"rlret",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.82,0.82)
				);
				if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
				sb.drawimage(
					"rlretblk",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.82,0.82), col:Color(254-Light, 0,0,0)
				);
				sb.drawimage(
					"rlscop",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.82,0.82)
				);
				if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
				sb.drawimage(
					"rlscop",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.82,0.82), col:Color(254-Light, 0,0,0)
				);


				//readings
				if(
					(level.time&(1|2))
					||rangefinder>14
				)sb.drawnum(rangefinder,
					4+bob.x,17+bob.y,sb.DI_SCREEN_CENTER,Font.CR_RED,0.5
				);
				if(hdw.weaponstatus[RLS_CHAMBER]<=1){
					int airburst=hdw.airburst;
					if(airburst)sb.drawnum(max(10,airburst/100),
						4+bob.x,52+bob.y,sb.DI_SCREEN_CENTER,Font.CR_WHITE,0.5
					);
				}

			}
		}
	}
	override void SetReflexReticle(int which){weaponstatus[RLS_DOT]=which;}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			double angchange=owner.findinventory("HEATAmmo")?10:0;
			if(angchange)owner.angle-=angchange;
			owner.A_DropInventory("HDRocketAmmo",1);
			if(angchange){
				owner.angle+=angchange*2;
				owner.A_DropInventory("HEATAmmo",1);
				owner.angle-=angchange;
			}
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("DudRocketAmmo");
		owner.A_SetInventory("HEATAmmo",1);
		owner.A_SetInventory("HDRocketAmmo",1);
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(weaponstatus[0]&RLF_NOMAG){
			bobrangex=default.bobrangey*0.8;
			bobrangey=default.bobrangey*0.8;
		}
	}
	states{
	select0:
		LAUG A 0 A_CheckDefaultReflexReticle(RLS_DOT);
		MISG A 0 A_CheckIdSprite("LAUGA0","MISGA0");
		goto select0big;
		LAUG AB 0;
		MISG AB 0;
	deselect0:
		MISG # 0 A_CheckIdSprite("LAUGA0","MISGA0");
		---- A 0;
		goto deselect0small;
		
	Safety:
		---- A 0 {A_StartSound("weapons/fmswitch",CHAN_WEAPON,CHANF_OVERLAP,0.4);
		if(invoker.weaponstatus[RLF_SAFETY]==1)invoker.weaponstatus[RLF_SAFETY]=0;
		else invoker.weaponstatus[RLF_SAFETY]=1;}
		Goto Nope;
	ready:
		MISG A 0 A_CheckIdSprite("LAUGA0","MISGA0");
		---- A 0 A_JumpIf(pressinguse()&&pressingfiremode(),"Safety");
		#### A 1{
			A_WeaponReady(WRF_ALL);

			//update rangefinder
			if(
				!(level.time&(1|2|4|8))
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
				invoker.rangefinder=int(frt.distance*(1./HDCONST_ONEMETRE));
			}
		}
		goto readyend;

	firemode:
		goto abadjust;


	fire:
		#### A 1;
		goto shoot;
	althold:
	hold:
		---- A 0;
		goto nope;
	shoot:
		#### A 2{
			bool nomag=invoker.weaponstatus[0]&RLF_NOMAG;
			if(nomag)invoker.weaponstatus[RLS_MAG]=0;

			int chm=invoker.weaponstatus[RLS_CHAMBER];
			if(chm<1){
				if(nomag)setweaponstate("nope");
				else setweaponstate("chamber_manual");
				return;
			}

			RocketGrenade rkt;
			if(
				invoker.weaponstatus[0]&RLF_GRENADEMODE
				&&chm==1
			){
				//shoot a grenade
				A_FireHDGL();
				invoker.weaponstatus[RLS_SMOKE]+=5;
				invoker.weaponstatus[RLS_CHAMBER]=0;
				invoker.weaponstatus[RLS_RECOIL]=0;
			}else{
				A_FireHDGL(chm>1?2:1);
				invoker.weaponstatus[RLS_SMOKE]+=5;
				invoker.weaponstatus[RLS_CHAMBER]=0;

				if(chm>1)invoker.weaponstatus[RLS_RECOIL]=2;
				else invoker.weaponstatus[RLS_RECOIL]=1;
			}
		}
		#### B 2{
			switch(invoker.weaponstatus[RLS_RECOIL]){
			case 2:
				A_ZoomRecoil(0.99);
				A_MuzzleClimb(
					0,0,
					-0.8,-1.6,
					-0.2,-0.6,
					-0.3,-0.9
				);
				break;
			case 1:
				A_ZoomRecoil(0.995);
				A_MuzzleClimb(
					0,0,
					-0.4,-0.8,
					-0.1,-0.3,
					-0.2,-0.6
				);
				break;
			case 0:
			default:
				A_ZoomRecoil(0.995);
				A_MuzzleClimb(
					0,0,
					-0.4,-0.8,
					-0.1,-0.3
				);
				break;
			}
		}
		---- A 0 A_JumpIf(!(invoker.weaponstatus[0]&RLF_NOMAG),"chamber");
		goto nope;

	hardlaunchrecoil:  //unused
		#### A 2{
			A_ZoomRecoil(0.7);
			if(gunbraced()){
				hdplayerpawn(self).gunbraced=false;
				A_MuzzleClimb(
					0,0,
					frandom(1,1.2),-frandom(1,1.5),
					frandom(0.7,0.9),-frandom(1.5,2),
					-frandom(0.8,1.),frandom(2,3)
				);
				A_ChangeVelocity(cos(pitch)*-1,0,sin(pitch)*1,CVF_RELATIVE);
			}else{
				A_MuzzleClimb(
					0,0,
					frandom(1.2,1.7),-frandom(2,2.5),
					frandom(1.,1.2),-frandom(2.5,3),
					frandom(0.6,0.8),-frandom(2,3)
				);
				A_ChangeVelocity(cos(pitch)*-3,0,sin(pitch)*3,CVF_RELATIVE);
				if(self is "hdplayerpawn")hdplayerpawn(self).stunned+=10;
			}
			A_Gunflash();
		}
		#### B 1 offset(0,49);
		#### B 2 offset(0,54);
		#### B 2 offset(0,43);
		#### B 1 offset(0,39);
		#### B 1 offset(0,36);
		#### A 0 A_JumpIf(invoker.weaponstatus[0]&RLF_NOMAG,"nope");
		goto chamber;
	flash:
		MISF A 2 bright{
			A_CheckIdSprite("LAUFA0","MISFA0",PSP_FLASH);
			A_StartSound("weapons/rocklaunch",CHAN_WEAPON,CHANF_OVERLAP,volume:0.6);
			HDFlashAlpha(128);
			A_Light1();
		}
		#### B 2 bright A_Light2();
		#### C 2 bright A_Light1();
		#### D 1 bright A_Light0();
		TNT1 A 0 A_AlertMonsters();
		stop;
		LAUF ABCD 0;
		MISF ABCD 0;
		stop;

	chamber:
		#### A 1 offset(0,35){
			if(invoker.weaponstatus[RLS_CHAMBER]>0){
				setweaponstate("nope");
				return;
			}
			A_StartSound("weapons/rockchamber",8);
		}
		#### A 1 offset(1,38){
			if(invoker.weaponstatus[RLS_MAG]>0){
				invoker.weaponstatus[RLS_CHAMBER]=1;
				invoker.weaponstatus[RLS_MAG]--;
			}
		}
		#### A 1 offset(0,36);
		goto nope;
	chamber_manual:
		#### A 1 offset(0,35){
			if(invoker.weaponstatus[RLS_CHAMBER]>0){
				setweaponstate("nope");
				return;
			}
			A_StartSound("weapons/rockchamber",8);
		}
		#### A 1 offset(0,39);
		#### A 2 offset(1,38){
			if(invoker.weaponstatus[RLS_MAG]>0){
				invoker.weaponstatus[RLS_CHAMBER]=1;
				invoker.weaponstatus[RLS_MAG]--;
			}
		}
		#### A 1 offset(0,35);
		goto nope;

	altfire:
	grenadeorrocket:
		#### A 1 offset(0,34){
			if(invoker.weaponstatus[RLS_CHAMBER]>1){
				invoker.weaponstatus[0]&=~RLF_GRENADEMODE;
				setweaponstate("nope");
				return;
			}
			A_WeaponBusy();
		}
		#### A 2 offset(0,36) A_StartSound("weapons/rockchamber",8);
		#### A 1 offset(0,37);
		#### A 2 offset(1,38);
		#### A 3 offset(2,37){
			invoker.weaponstatus[0]^=RLF_GRENADEMODE;
			A_SetHelpText();
		}
		#### A 2 offset(1,36);
		#### A 1 offset(0,34);
		goto nope;
	reload:
		#### A 0 A_JumpIf(invoker.weaponstatus[RLS_CHAMBER]>1,"altreload");
		#### A 0 A_JumpIf(invoker.weaponstatus[0]&RLF_NOMAG,"nomagreload");
		#### A 0 A_JumpIf(
			(invoker.weaponstatus[RLS_CHAMBER]>0&&invoker.weaponstatus[RLS_MAG]>=5)
			||!countinv("HDRocketAmmo"),
			"nope"
		);
		MISR A 2 offset(0,0);
		#### B 2 offset(0,0) A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		#### C 2 offset(0,0);
		#### D 2 offset(0,0);
		#### E 2{
			A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
			A_StartSound("weapons/rockopen",8);
		}
		#### F 2;
		#### G 4 A_StartSound("weapons/rockopen2",8,CHANF_OVERLAP);
	reload2:
		#### B 0 A_JumpIf(
			(invoker.weaponstatus[RLS_CHAMBER]>0&&invoker.weaponstatus[RLS_MAG]>=5)
			||!countinv("HDRocketAmmo"),
			"reloadend"
		);
		#### A 0 A_OverLay(-26, "HandRocketLoad");
		#### G 9 offset(10,38) A_StartSound("weapons/pocket",9);
		#### G 4 offset(12,40)A_StartSound("weapons/rockreload",8);
		#### G 3 offset(10,38){
			if(!countinv("HDRocketAmmo"))return;
			A_TakeInventory("HDRocketAmmo",1,TIF_NOTAKEINFINITE);
			if(invoker.weaponstatus[RLS_CHAMBER]<1)invoker.weaponstatus[RLS_CHAMBER]=1;
			else invoker.weaponstatus[RLS_MAG]++;
		}
		#### G 1 offset(10,34) A_JumpIf(!pressingreload(),"reloadend");
		#### G 4 offset(11,38) A_StartSound("weapons/pocket",9);
		#### G 5 offset(10,37);
		loop;
	HandRocketLoad:	
		SHHA D 2 A_OverLayOffset(-26, -56, 1);
		SHHA D 2 A_OverLayOffset(-26, -61, -1);
		SHHA D 2 A_OverLayOffset(-26, -70, 0);
		SHHA D 2 A_OverLayOffset(-26, -82, -2);
		SHHA D 1 {if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, -89, -1); Else A_OverLayOffset(-26, -90, -2);}
		SHHA D 1 A_OverLayOffset(-26, -90, -3);
		SHHA D 1 {if((HDPlayerPawn(self).bloodpressure>40)||(Health<41))A_OverLayOffset(-26, -91, -3); Else A_OverLayOffset(-26, -90, -2);}
		SHHA D 1 A_OverLayOffset(-26, -90, -2);
		BFHA D 1 {if((HDPlayerPawn(self).bloodpressure>30)||(Health<41))A_OverLayOffset(-26, -131, -1); Else A_OverLayOffset(-26, -130, 0);}
		BFHA D 1 A_OverLayOffset(-26, -130, 0);
		BFHA D 1 {if((HDPlayerPawn(self).bloodpressure>40)||(Health<41))A_OverLayOffset(-26, -129, 1); Else A_OverLayOffset(-26, -120, 4);}
		BFHA D 1 A_OverLayOffset(-26, -120, 4);
		BFHA D 1 {if((HDPlayerPawn(self).bloodpressure>40)||(Health<41))A_OverLayOffset(-26, -115, 5); Else A_OverLayOffset(-26, -110, 7);}
		BFHA D 1 A_OverLayOffset(-26, -100, 9);
		BFHA D 1 {if((HDPlayerPawn(self).bloodpressure>40)||(Health<41))A_OverLayOffset(-26, -85, 16); Else A_OverLayOffset(-26, -90, 14);}
		BFHA D 1 A_OverLayOffset(-26, -80, 25);
		BFHA D 1 A_OverLayOffset(-26, -70, 34);
		BFHA D 1 A_OverLayOffset(-26, -60, 40);
		Stop;		
	reloadend:
		#### G 3 A_StartSound("weapons/rockopen2",8);
		#### F 3 A_StartSound("weapons/rockopen",8,CHANF_OVERLAP);
		#### E 2;
		#### D 2;
		#### C 2;
		#### B 2;
		#### A 2;
		MISG A 0;
		goto nope;

	HandHeat:
		---- A 0 A_JumpIf(invoker.weaponstatus[RLS_CHAMBER]>1,"Handremoveheat");
		---- A 0 A_Jumpif((invoker.weaponstatus[RLF_NOMAG]||invoker.weaponstatus[RLS_MAG]==5)&&(invoker.weaponstatus[RLS_CHAMBER]==1),"HandremoveRock");
		MISG L 1 A_OverlayOffset(-26, 40, 30);
		MISG L 2 A_OverlayOffset(-26, 30, 20);
		MISG L 2 A_OverlayOffset(-26, 20, 0);
		MISG L 2 A_OverlayOffset(-26, 10, -10);
		MISG L 2 A_OverlayOffset(-26, 0, -5);
		MISG L 2 A_OverlayOffset(-26, -13,0);
		MISG L 2 A_OverlayOffset(-26, -17,5);
		MISG L 2 A_OverlayOffset(-26, -18,6);
		MISG L 4 A_OverlayOffset(-26, -20,8);
		BFHA D 2 A_OverlayOffset(-26, -80, -5);
		BFHA D 2 A_OverlayOffset(-26, -70, 0);
		BFHA D 2 A_OverlayOffset(-26, -60, 12);
		BFHA D 2 A_OverlayOffset(-26, -50, 20);
		BFHA D 2 A_OverlayOffset(-26, -40, 32);
		BFHA D 2 A_OverlayOffset(-26, -30, 44);
		BFHA D 2 A_OverlayOffset(-26, -20, 56);
		BFHA D 2 A_OverlayOffset(-26, -10, 68);
		Stop;
	Handremoveheat:
		BFHA D 2 A_OverlayOffset(-26, -30, 44);
		BFHA D 2 A_OverlayOffset(-26, -40, 32);
		BFHA D 1 A_OverlayOffset(-26, -50, 20);
		BFHA D 2 A_OverlayOffset(-26, -60, 12);
		BFHA D 1 A_OverlayOffset(-26, -70, 0);
		BFHA D 2 A_OverlayOffset(-26, -80, -5);
		BFHA D 2 A_OverlayOffset(-26, -87, -12);
		MISG L 2 A_OverlayOffset(-26, -20,8);
		MISG L 2 A_OverlayOffset(-26, -13,0);
		MISG L 2 A_OverlayOffset(-26, 0, -5);
		MISG L 2 A_OverlayOffset(-26, 10, -10);
		MISG L 2 A_OverlayOffset(-26, 20, 0);
		MISG L 2 A_OverlayOffset(-26, 30, 20);
		MISG L 1 A_OverlayOffset(-26, 40, 30);
		Stop;
	HandremoveRock:
		BFHA D 2 A_OverlayOffset(-26, -30, 44);
		BFHA D 2 A_OverlayOffset(-26, -40, 32);
		BFHA D 1 A_OverlayOffset(-26, -50, 20);
		BFHA D 2 A_OverlayOffset(-26, -60, 12);
		BFHA D 1 A_OverlayOffset(-26, -70, 0);
		BFHA D 2 A_OverlayOffset(-26, -80, -5);
		BFHA D 2 A_OverlayOffset(-26, -87, -12);
		SHHA D 2 A_OverlayOffset(-26, -40,-2);
		SHHA D 2 A_OverlayOffset(-26, -33,-10);
		SHHA D 2 A_OverlayOffset(-26, -20, -15);
		SHHA D 2 A_OverlayOffset(-26, -10, -20);
		SHHA D 2 A_OverlayOffset(-26, 0, -10);
		SHHA D 2 A_OverlayOffset(-26, 10, 10);
		SHHA D 1 A_OverlayOffset(-26, 20, 20);
		Stop;
	user1:
	altreload:
		#### A 2{
			int ch=invoker.weaponstatus[RLS_CHAMBER];
			if(
				(
					ch>0
					&&pressingreload()
				)||(
					ch<2
					&&!countinv("HEATAmmo")
				)
			)setweaponstate("nope");
		}
		MISR A 2 offset(0,20);
		#### C 2 offset(0,40);
		#### E 2 offset(20,60);
		#### H 2 offset(40,60);
		#### I 2 offset(30,40) A_StartSound("weapons/rockopen",8);
		#### J 2 offset(20,30);
		#### K 4 offset(10,3);
		#### K 10 offset(10,3){
			A_StartSound("weapons/rockopen2",8);
			if(invoker.weaponstatus[0]&RLF_NOMAG)A_SetTics(8);
		}
		#### K 4 offset(10,3){
			A_StartSound("weapons/pocket",8);
			if(invoker.weaponstatus[0]&RLF_NOMAG)A_SetTics(8);
		}
		#### B 0{
			if(health<40)A_SetTics(7);
			else if(health<60)A_SetTics(3);
		}
		#### A 0 A_OverLay(-26, "HandHeat");
		#### K 6 offset(10,3);
		#### K 6 offset(10,3);
		#### K 2 offset(10,4) A_StartSound("weapons/rockreload",8);

		#### K 10 offset(10,3){
			int chh=invoker.weaponstatus[RLS_CHAMBER];
			if(chh>1){
				setweaponstate("removeheatfromchamber");
				return;
			}

			if(invoker.weaponstatus[0]&RLF_NOMAG)A_SetTics(5);
			if(invoker.weaponstatus[RLS_CHAMBER]<1){
				setweaponstate("loadheatintoemptychamber");
				return;
			}else{
				invoker.weaponstatus[RLS_CHAMBER]=0;
				if(
					!(invoker.weaponstatus[0]&RLF_NOMAG)
					&&invoker.weaponstatus[RLS_MAG]<5
				){
					invoker.weaponstatus[RLS_MAG]++;
					setweaponstate("loadheatintoemptychamber");
					return;
				}
				if(A_JumpIfInventory("HDRocketAmmo",0,"null"))A_SpawnItemEx(
					"HDRocketAmmo",10,0,10,vel.x,vel.y,vel.z,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
				);else{
					A_StartSound("weapons/pocket",9);
					A_GiveInventory("HDRocketAmmo",1);
				}
			}
		}goto altreloadend;
	loadheatintoemptychamber:
		#### K 3 offset(10,3);
		#### K 2 offset(10,3){
			if(!countinv("HEATAmmo"))return;
			invoker.weaponstatus[RLS_CHAMBER]=2;
			A_SetHelpText();
			invoker.weaponstatus[0]&=~RLF_GRENADEMODE;
			A_TakeInventory("HEATAmmo",1,TIF_NOTAKEINFINITE);
		}goto altreloadend;
	removeheatfromchamber:
		#### K 4 offset(10,3){
			invoker.weaponstatus[RLS_CHAMBER]=0;
			A_SetHelpText();
			if(A_JumpIfInventory("HEATAmmo",0,"null"))A_SpawnItemEx(
				"HEATAmmo",10,0,height-16,vel.x,vel.y,vel.z+2,
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
			);else{
				A_StartSound("weapons/pocket",9);
				A_GiveInventory("HEATAmmo",1);
			}
		}goto altreloadend;
	altreloadend:
		#### K 6 offset(10,3) A_StartSound("weapons/rockopen2",8,CHANF_OVERLAP);
		#### B 0 A_StartSound("weapons/rockopen",8,CHANF_OVERLAP);
		#### J 2 offset(20,30);
		#### I 2 offset(30,40);
		#### H 2 offset(40,60);
		#### E 2 offset(20,60);
		#### C 2 offset(0,40);
		MISR A 2 offset(0,20);
		goto nope;

	user4:
	unload:
		#### A 0 A_JumpIf(invoker.weaponstatus[0]&RLF_NOMAG,"nomagreload");
		MISR A 1{
			if(
				invoker.weaponstatus[RLS_CHAMBER]>1
			)setweaponstate("altreload");
			else if(
				invoker.weaponstatus[RLS_CHAMBER]<1
				&&invoker.weaponstatus[RLS_MAG]<1
			)setweaponstate("nope");
		}
		#### A 1;
		#### C 2;
		#### D 2 A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		#### E 2{
			A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
			A_StartSound("weapons/rockopen",8);
		}
		#### F 2;
		#### G 2 A_StartSound("weapons/rockopen2",8);
	unload2:
		#### B 0 A_JumpIf(invoker.weaponstatus[RLS_MAG]<1&&invoker.weaponstatus[RLS_CHAMBER]<1,"unloadend");
		#### G 0 A_OverLay(-26,"HandRocketUnload");
		#### G 5;
		#### G 10 offset(-2,2) A_StartSound("weapons/rockreload",8,CHANF_OVERLAP);
		#### G 9 offset(-3,3){
			if(!invoker.weaponstatus[RLS_CHAMBER]){
				invoker.weaponstatus[RLS_MAG]--;
			}else{
				invoker.weaponstatus[RLS_CHAMBER]=0;
			}
			if(
				A_JumpIfInventory("HDRocketAmmo",0,"null")
				||(!PressingUnload()&&!PressingReload())
			){
				A_SpawnItemEx(
					"HDRocketAmmo",10,0,height-16,vel.x,vel.y,vel.z+2,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
				);
			}else{
				A_StartSound("weapons/pocket",9);
				A_GiveInventory("HDRocketAmmo",1);
			}
		}
		#### G 5 offset(-1,1) A_StartSound("weapons/rockopen2",8);
		#### G 4 {
			if(health<40)A_SetTics(4);
			A_StartSound("weapons/rockopen",8,CHANF_OVERLAP);
		}
		#### B 0 A_JumpIf(!pressingunload(),"unloadend");
		goto unload2;
	HandRocketUnLoad:	
		BFHA D 1 A_OverLayOffset(-26, -70, 40);
		BFHA D 1 A_OverLayOffset(-26, -80, 30);
		BFHA D 1 A_OverLayOffset(-26, -90, 20);
		BFHA D 2 A_OverLayOffset(-26, -100, 9);
		BFHA D 2 A_OverLayOffset(-26, -130, 0);
		SHHA D 2 A_OverLayOffset(-26, -90, -2);
		SHHA D 2 A_OverLayOffset(-26, -90, -3);
		SHHA D 2 A_OverLayOffset(-26, -82, -2);
		SHHA D 2 A_OverLayOffset(-26, -70, 0);
		SHHA D 2 A_OverLayOffset(-26, -61, -1);
		SHHA D 2 A_OverLayOffset(-26, -56, 1);
		Stop;			
	unloadend:
		#### F 2;
		#### E 2;
		#### D 2;
		#### C 2;
		#### B 2;
		#### A 2;
		MISG A 0;
		goto nope;



	nomagreload:
		MISR A 2 offset(0,20){
			int ch=invoker.weaponstatus[RLS_CHAMBER];
			if(
				ch>0
				&&pressingreload()
			)setweaponstate("nope");
			else if(
				ch<=0
				&&pressingunload()
			)setweaponstate("nope");
			else if(
				ch>=2
			)setweaponstate("altreload");
			else if(
				ch<1
				&&!countinv("HDRocketAmmo")
			)setweaponstate("nope");
		}
		#### C 2 offset(0,40);
		#### E 2 offset(20,60);
		#### H 2 offset(40,60);
		#### I 2 offset(30,40) A_StartSound("weapons/rockopen",8);
		#### J 2 offset(20,30);
		#### K 4 offset(10,3);
		#### K 10 offset(10,3) A_StartSound("weapons/rockopen2",8);
		#### K 4 offset(10,3) A_StartSound("weapons/pocket",8);
		#### B 0{
			if(health<40)A_SetTics(7);
			else if(health<60)A_SetTics(3);
		}
		#### A 0 A_OverLay(-26, "HandRocket");
		#### K 6 offset(10,3);
		#### K 6 offset(10,3);
		#### K 5 offset(10,3){
			int chh=invoker.weaponstatus[RLS_CHAMBER];
			if(chh<1){
				setweaponstate("loadrocketintoemptychamber");
				return;
			}else{
				invoker.weaponstatus[RLS_CHAMBER]=0;
				if(A_JumpIfInventory("HDRocketAmmo",0,"null"))A_SpawnItemEx(
					"HDRocketAmmo",10,0,10,vel.x,vel.y,vel.z,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
				);else A_GiveInventory("HDRocketAmmo",1);
			}
		}goto altreloadend;
	HandRocket:
		---- A 0 A_Jumpif(invoker.weaponstatus[RLS_CHAMBER]==1,"HandremoveRock");
		SHHA D 1 A_OverlayOffset(-26, 20, 20);
		SHHA D 2 A_OverlayOffset(-26, 10, 10);
		#### D 2 A_OverlayOffset(-26, 0, -10);
		#### D 2 A_OverlayOffset(-26, -10, -20);
		#### D 2 A_OverlayOffset(-26, -20, -15);
		#### D 2 A_OverlayOffset(-26, -33,-10);
		#### D 4 A_OverlayOffset(-26, -40,-0);
		BFHA D 2 A_OverlayOffset(-26, -80, -5);
		BFHA D 2 A_OverlayOffset(-26, -70, 0);
		BFHA D 2 A_OverlayOffset(-26, -60, 12);
		BFHA D 2 A_OverlayOffset(-26, -50, 20);
		BFHA D 2 A_OverlayOffset(-26, -40, 32);
		BFHA D 2 A_OverlayOffset(-26, -30, 44);
		BFHA D 2 A_OverlayOffset(-26, -20, 56);
		BFHA D 2 A_OverlayOffset(-26, -10, 68);
		Stop;	
	loadrocketintoemptychamber:
		#### K 3 offset(10,3);
		#### K 2 offset(10,3){
			if(!countinv("HDRocketAmmo"))return;
			invoker.weaponstatus[RLS_CHAMBER]=1;
			A_SetHelpText();
			A_TakeInventory("HDRocketAmmo",1,TIF_NOTAKEINFINITE);
		}goto altreloadend;

	spawn:
		TNT1 A 0 nodelay A_JumpIf(invoker.weaponstatus[0]&RLF_NOMAG,2);
		LAUN A -1;
		LAUN B -1;
		stop;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[RLS_MAG]=5;
		if(idfa){
			weaponstatus[RLS_CHAMBER]=max(1,weaponstatus[RLS_CHAMBER]);
		}else{
			weaponstatus[0]=0;
			weaponstatus[RLS_CHAMBER]=1;
			airburst=0;
			if(!owner){
				weaponstatus[0]+=random(0,1)*RLF_GRENADEMODE;
				if(random(0,3))weaponstatus[0]|=RLF_NOMAG;
			}
		}
	}
	override void loadoutconfigure(string input){
		int heatloaded=getloadoutvar(input,"heat",1);
		if(!heatloaded)weaponstatus[RLS_CHAMBER]=1;
		else if(heatloaded>0)weaponstatus[RLS_CHAMBER]=2;

		int xhdot=getloadoutvar(input,"dot",3);
		if(xhdot>=0)weaponstatus[RLS_DOT]=xhdot;

		//if no heat, evaluate grenade mode
		if(weaponstatus[RLS_CHAMBER]!=2){
			weaponstatus[RLS_CHAMBER]=1;
			int grenademode=getloadoutvar(input,"grenade",1);
			if(!grenademode)weaponstatus[0]&=~RLF_GRENADEMODE;
			else if(grenademode>0)weaponstatus[0]|=RLF_GRENADEMODE;
		}

		//singleshot
		int nomag=getloadoutvar(input,"nomag",1);
		if(nomag>0){
			weaponstatus[0]|=RLF_NOMAG;
			if(nomag>1){
				weaponstatus[RLS_CHAMBER]=2;
				weaponstatus[0]&=~RLF_GRENADEMODE;
			}
		}else weaponstatus[0]&=~RLF_NOMAG;
	}
}
enum rocketstatus{
	RLF_GRENADEMODE=2,
	RLF_NOMAG=4,
	RLF_SAFETY=7,
	RLS_STATUS=0,
	RLS_MAG=1,
	RLS_CHAMBER=2,
	RLS_AIRBURST=3,
	RLS_SMOKE=4,
	RLS_DOT=5,
	RLS_RECOIL=6,
};








// ------------------------------------------------------------
// Bloop Launcher
// ------------------------------------------------------------
class Blooper:HDWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Grenade Launcher"
		//$Sprite "BLOPA0"

		+weapon.explosive
		+hdweapon.fitsinbackpack
		weapon.selectionorder 93;
		weapon.slotnumber 5;
		weapon.slotpriority 3;
		scale 0.6;
		inventory.pickupmessage "$PICKUP_BLOOPER";
		obituary "$OB_BLOOPER";
		hdweapon.barrelsize 24,1.6,3;
		tag "$TAG_GL";
		hdweapon.refid HDLD_BLOOPER;

		hdweapon.ammo1 "HDRocketAmmo",2;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override double gunmass(){
		return weaponstatus[0]&BLOPF_LOADED?5:4;
	}
	override double weaponbulk(){
		return 60+(weaponstatus[0]&BLOPF_LOADED?ENC_ROCKETLOADED:0);
	}
	override string,double getpickupsprite(){return "BLOPA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("ROQPA0",(-52,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
			sb.drawnum(hpl.countinv("HDRocketAmmo"),-45,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(hdw.weaponstatus[0]&BLOPF_LOADED)sb.drawrect(-21,-13,5,3);
		int ab=hdw.airburst;
		sb.drawstring(
			sb.mAmountFont,ab?string.format("%.2f",hdw.airburst*0.01):"--.--",
			(-28,-15),sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,
			ab?Font.CR_WHITE:Font.CR_BLACK
		);
		sb.drawwepnum(
			hpl.countinv("HDRocketAmmo"),
			(HDCONST_MAXPOCKETSPACE/ENC_ROCKET)
		);
		sb.drawrect(-28,-43+min(32,ab>>8),6,1);
		sb.drawrect(-23,-42,1,32);
		sb.drawrect(-25,-42,1,32);
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRESHOOT
		..LWPHELP_ALTFIRE..StringTable.Localize("$BLOPWH_ALTFIRE")
		..LWPHELP_RELOADRELOAD
		..LWPHELP_FIREMODE.."+"..LWPHELP_UPDOWN..StringTable.Localize("$BLOPWH_AIRBURST")
		..LWPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		sb.drawgrenadeladder(hdw.airburst,bob);
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			owner.A_DropInventory("HDRocketAmmo",1);
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("DudRocketAmmo");
		owner.A_SetInventory("HDRocketAmmo",1);
	}
	states{
	select0:
		BLOG A 0;
		goto select0small;
	deselect0:
		BLOG A 0;
		goto deselect0small;

	ready:
		BLOG A 1 A_WeaponReady(WRF_ALL);
		goto readyend;
	hold:
	altfire:
		BLOG A 0{invoker.airburst=0;}
		goto nope;
	firemode:
		goto abadjust;

	fire:
		BLOG B 0 A_JumpIf(invoker.weaponstatus[0]&BLOPF_LOADED,"reallyshoot");
		goto nope;
	reallyshoot:
		BLOG A 1{
			A_FireHDGL();
			invoker.weaponstatus[0]&=~BLOPF_LOADED;
		}
		BLOG A 1 offset(0,34);
		BLOG B 0{
			A_ZoomRecoil(0.9);
			A_MuzzleClimb(-frandom(2.,2.7),-frandom(3.4,5.2));
		}
		goto nope;
	loadcommon:
		BLOG B 1 offset(2,34)A_StartSound("weapons/rockopen",8);
		BLOG C 1 offset(4,38)A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		BLOG C 1 offset(10,44);
		BLOG C 2 offset(12,50)A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		BLOG C 3 offset(13,55) A_StartSound("weapons/rockopen2",8,CHANF_OVERLAP);
		BLOG D 3 offset(14,60);
		BLOG D 3 offset(11,64)A_StartSound("weapons/pocket",9);
		BLOG D 7 offset(10,66);
		BLOG D 0{
			if(health<40)A_SetTics(7);
			else if(health<60)A_SetTics(3);
		}
		BLOG D 4 offset(12,68) A_StartSound("weapons/rockreload",8);
		BLOG D 2 offset(10,66){
			if(invoker.weaponstatus[0]&BLOPF_JUSTUNLOAD){
				if(
					!(invoker.weaponstatus[0]&BLOPF_LOADED)
				)setweaponstate("reloadend");else{
					invoker.weaponstatus[0]&=~BLOPF_LOADED;
					if(
						(!PressingUnload()&&!PressingReload())
						||A_JumpIfInventory("HDRocketAmmo",0,"null")
					)
					A_SpawnItemEx(
						"HDRocketAmmo",10,0,height-16,vel.x,vel.y,vel.z+2,
						0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
					);
					else{
						A_GiveInventory("HDRocketAmmo",1);
						A_StartSound("weapons/pocket",9);
						A_SetTics(4);
					}
				}
			}else{
				if(
					invoker.weaponstatus[0]&BLOPF_LOADED
					||!countinv("HDRocketAmmo")
				)setweaponstate("reloadend");else{
					A_TakeInventory("HDRocketAmmo",1,TIF_NOTAKEINFINITE);
					invoker.weaponstatus[0]|=BLOPF_LOADED;
					A_SetTics(5);
				}
			}
		}
	reloadend:
		BLOG D 1 offset(12,68) A_StartSound("weapons/rockopen2",8);
		BLOG D 1 offset(11,70);
		BLOG D 4 offset(10,69);
		BLOG D 0 A_StartSound("weapons/rockopen",8,CHANF_OVERLAP);
		BLOG D 1 offset(9,66);
		BLOG D 1 offset(9,60);
		BLOG C 1 offset(8,53);
		BLOG C 1 offset(8,48);
		BLOG C 1 offset(6,43);
		BLOG B 1 offset(4,38);
		BLOG B 1 offset(2,34);
		goto ready;
	altreload:
	reload:
		BLOG B 0 A_JumpIf(
			invoker.weaponstatus[0]&BLOPF_LOADED
			||!countinv("HDRocketAmmo"),
			"nope"
		);
		BLOG B 0{
			if(
				invoker.weaponstatus[0]&BLOPF_LOADED
				||!countinv("HDRocketAmmo")
			)setweaponstate("nope");else{
				invoker.weaponstatus[0]&=~BLOPF_JUSTUNLOAD;
			}
		}goto loadcommon;
	unload:
		BLOG B 0{
			if(
				!(invoker.weaponstatus[0]&BLOPF_LOADED)
			)setweaponstate("nope");else{
				invoker.weaponstatus[0]|=BLOPF_JUSTUNLOAD;
			}
		}goto loadcommon;

	spawn:
		BLOP A -1;
	}
	override void loadoutconfigure(string input){
		//there isn't actually anything to configure,
		//but we need this to keep it loaded
		weaponstatus[0]|=BLOPF_LOADED;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[0]|=BLOPF_LOADED;
		if(!idfa && !owner){
			airburst=0;
		}
	}
}
enum bloopstatus{
	BLOPF_LOADED=1,
	BLOPF_JUSTUNLOAD=2,

	BLOPS_STATUS=0,
	BLOPS_AIRBURST=1,
};





// ------------------------------------------------------------
// Pickups
// ------------------------------------------------------------
class RocketBigPickup:HDUPK{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Box of Rocket Grenades"
		//$Sprite "BROKA0"

		scale 0.5;
		hdupk.pickupmessage "$PICKUP_ROCKETBOX";
		hdupk.pickuptype "HDRocketAmmo";
		hdupk.amount 5;
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_SpawnItemEx("HEATAmmo",10,0,0,0,0,0,0,0,220);
		A_SpawnItemEx("HEATAmmo",13,0,0,0,0,0,0,0,220);
		A_SpawnItemEx("HEATAmmo",16,0,0,0,0,0,0,0,220);
	}
	states{
	spawn:
		BROK A -1;
		stop;
	}
}

class BloopMapPickup:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let wep=Blooper(spawn("Blooper",pos,ALLOW_REPLACE));
			if(!wep)return;
			HDF.TransferSpecials(self,wep);

			A_SpawnItemEx("RocketBigPickup",3);
			A_SpawnItemEx("HDRocketAmmo",5);
		}stop;
	}
}
