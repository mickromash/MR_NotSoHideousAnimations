// ------------------------------------------------------------
// Manually reload magazines! (and clips too!)
// ------------------------------------------------------------
class MagManager:HDWeapon{
	default{
		+weapon.wimpy_weapon
		+weapon.no_auto_switch
		+hdweapon.alwaysshowstatus
		+nointeraction
		weapon.selectionorder 1011;
	}
	int which;
	hdmagammo thismag;
	name thismagtype;
	string uitext;
	array<string>magtypes;

	override void beginplay(){
		super.beginplay();
		uitext="Mag Manager\n\nNo mags selected";
		thismagtype="HDMagAmmo";
		if(owner)thismag=hdmagammo(owner.findinventory(thismagtype));

		magtypes.clear();
		for(int i=0;i<allactorclasses.size();i++){
			let mmmm=(class<hdmagammo>)(allactorclasses[i]);
			if(!mmmm)continue;
			let mmm=getdefaultbytype(mmmm);
			if(
				mmm.mustshowinmagmanager
				||(mmm.roundtype!="")
			){
				magtypes.push(mmm.getclassname());
			}
		}
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(!thismag||thismag.mags.size()<1)return;
		sb.beginhud(forcescaled:true);
		thismag.DrawHUDStuff(sb,self,hpl);
		sb.beginhud(forcescaled:false);
	}
	override string gethelptext(){
		return
		WEPHELP_FIRE.."/"..WEPHELP_ALTFIRE.."  Previous/Next mag/clip\n"
		..WEPHELP_ALTRELOAD.."  Select lowest unselected\n"
		..WEPHELP_RELOAD.."/"..WEPHELP_UNLOAD.."  Insert/Remove round\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_FIRE.."/"..WEPHELP_ALTFIRE.."  Previous/Next item type\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_RELOAD.."/"..WEPHELP_UNLOAD.."  Insert/Remove from backpack\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_DROP.."  Drop lowest mag\n"
		..WEPHELP_USER3.."  Generic item manager\n"
		;
	}
	override inventory createtossable(int amt){
		if(owner){
			if(
				thismag
				&&owner.player
				&&owner.player.cmd.buttons&BT_FIREMODE
			)thismag.LowestToLast();
			owner.A_DropInventory(thismagtype,1);
		}
		return null;
	}
	override void DropOneAmmo(int amt){
		let mmm=HDMagAmmo(thismag);
		if(!mmm)return;
		let what=mmm.roundtype;
		if(!what)return;
		let gdpmmm=getdefaultbytype((class<hdpickup>)(mmm.roundtype));
		int howmany=int(min(max(1,gdpmmm.bulk?HDCONST_MAXPOCKETSPACE/gdpmmm.bulk*0.2:1),owner.countinv(what),100));
		if(!howmany)return;
		owner.A_DropInventory(what,howmany);
	}
	action bool GetMags(){
		invoker.thismag=hdmagammo(findinventory(invoker.thismagtype));
		return !!(invoker.thismag);
	}
	action void NextMagType(bool forwards=true){
		int findindex=0;
		int magrange=invoker.magtypes.size();
		for(int i=0;i<magrange;i++){
			if(invoker.thismagtype==invoker.magtypes[i]){
				findindex=i;
			}
		}
		for(int i=0;i<magrange;i++){
			if(forwards)findindex++;else findindex--;
			if(findindex<0)findindex=magrange-1;
			else if(findindex>=magrange)findindex=0;
			if(findinventory(invoker.magtypes[findindex])){
				invoker.thismag=HDMagAmmo(findinventory(invoker.magtypes[findindex]));
				invoker.thismagtype=invoker.magtypes[findindex];
				break;
			}
		}
		invoker.UpdateText();
	}
	action void Insert(){
		if(!GetMags())return;
		invoker.thismag.Insert();
		invoker.UpdateText();
		A_SetTics(invoker.thismag.inserttime);
	}
	action void Extract(){
		if(!GetMags())return;
		invoker.thismag.Extract();
		invoker.UpdateText();
		A_SetTics(invoker.thismag.extracttime);
	}
	action void LastToFirst(bool forwards=true){
		if(!GetMags())return;
		if(forwards)invoker.thismag.LastToFirst();
		else invoker.thismag.FirstToLast();
		invoker.UpdateText();
	}
	action void LowestToLast(){
		if(!GetMags())return;
//		invoker.thismag.LowestToLast();

		let m=invoker.thismag;
		int magsize=m.mags.size()-1;
		int which=-1;
		int lowest=m.maxperunit;
		for(int i=0;i<magsize;i++){
			if(m.mags[i]<lowest){
				which=i;
				lowest=m.mags[i];
			}
		}
		if(which>=0){
			m.mags.delete(which);
			m.mags.push(lowest);
		}

		invoker.UpdateText();
	}
	void UpdateText(){
		string toui=string.format(
			"\cf///\c%s\cf\\\\\\\n\cqFire\cu/\cqAltfire\cu  select mag\n\cqFiremode\cu+\cqF\cu/\cqAF\cu  select type\n\cqReload\cu/\cqUnload\cu  load/unload selected\n\cqFM\cu+\cqR\cu/\cqU\cu  move to/from backpack\n\cqDrop\cu  drop current  \cqFM\cu+\cqDrop\cu  ...lowest\n\cqAlt.Reload\cu bring up lowest\n\cqDrop one\cu drop loose rounds",thismag?"y"..thismag.gettag():"uNo mags selected."
		);
		if(thismag){
			thismagtype=thismag.getclassname();
		}else toui.replace("\cf","\ce");
		uitext=toui;
	}
	states{
	spawn:
		TNT1 A 0;
		stop;
	nope:
		---- A 1{
			A_WeaponMessage(invoker.uitext);
			A_ClearRefire();
			A_WeaponReady(WRF_NOFIRE);
		}
		---- A 0{
			int inp=getplayerinput(MODINPUT_BUTTONS);
			if(
				inp&BT_ATTACK||
				inp&BT_ALTATTACK||
				inp&BT_RELOAD||
				inp&BT_ZOOM||
				inp&BT_USER1||
				//all this just to get rid of user2 :(
				inp&BT_USER3||
				inp&BT_USER4
			)setweaponstate("nope");
		}
		---- A 0 A_Jump(256,"ready");
	select:
		TNT1 A 1;
		TNT1 A 0{
			if(!invoker.thismag)NextMagType();
			invoker.UpdateText();
		}goto super::select;
	user3:
		TNT1 A 0 A_JumpIf(player.oldbuttons&BT_USER3,"nope");
		TNT1 A 0 A_SelectWeapon("PickupManager");
		TNT1 A 0 A_WeaponReady(WRF_NONE);
		goto nope;
	ready:
		TNT1 A 1{
			int bt=player.cmd.buttons;
			if(bt&BT_ZOOM){
				int inputamt=GetMouseY(true);
				if(abs(inputamt)>5){
					NextMagType(inputamt>0?true:false);
					invoker.UpdateText();
				}
			}else if(bt&BT_FIREMODE){
				if(justpressed(BT_ATTACK))NextMagType(false);
				else if(justpressed(BT_ALTATTACK))NextMagType();
				else if(justpressed(BT_RELOAD))PutIntoBackpack(invoker.thismagtype);
				else if(justpressed(BT_USER4)){
					GetFromBackpack(invoker.thismagtype);
					A_SetTics(8);
				}
			}else A_WeaponReady(WRF_ALL&~WRF_ALLOWUSER2);
			if(!invoker.thismag)NextMagType();
			invoker.UpdateText();
			A_WeaponMessage(invoker.uitext);
		}
		goto readyend;
	fire:
		TNT1 A 1 LastToFirst(false);
		goto nope;
	altfire:
		TNT1 A 1 LastToFirst();
		goto nope;
	reload:
		TNT1 A 1 Insert();
		goto readyend;
	unload:
		TNT1 A 1 Extract();
		goto readyend;
	altreload:
		TNT1 A 0 LowestToLast();
		goto nope;
	}


	//backpack stuff
	action void GetFromBackpack(name type){
		let bp=hdbackpack(FindInventory("HDBackpack",true));
		if(!bp)return;
		StorageItem si=bp.Storage.Find(type);
		if(!si||si.HaveNone())return;
		bp.Storage.RemoveItem(si,self,self);
		bp.weaponbulk();
	}
	action void PutIntoBackpack(name type){
		let bp=hdbackpack(FindInventory("HDBackpack",true));
		if(!bp)return;
		let iv=inventory(findinventory(type));
		if(!iv)return;
		bp.Storage.TryInsertItem(iv,self);
	}
}






// ------------------------------------------------------------
// Generic item manager
// ------------------------------------------------------------
class PickupManager:HDWeapon{
	default{
		+weapon.wimpy_weapon
		+weapon.no_auto_switch
		+hdweapon.alwaysshowstatus
		+nointeraction
		weapon.selectionorder 1012;
		tag "Pickup Manager";
	}
	override string gethelptext(){
		return
		WEPHELP_FIRE.."/"..WEPHELP_ALTFIRE.."  Previous/Next item\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Cycle items\n"
		..WEPHELP_DROP.."  Drop item\n"
		..WEPHELP_ZOOM.."+"..WEPHELP_UPDOWN.."  Adjust amount per drop\n"
		..WEPHELP_USER3.."  Mag manager\n"
		;
	}
	hdpickup thisitem;
	string uitext;
	void getfirstitem(){
		if(!owner)return;
		for(inventory item=owner.inv;item!=null;item=!item?null:item.inv){
			if(ismanageable(item)){
				thisitem=hdpickup(item);
				return;
			}
		}
	}
	bool ismanageable(inventory item){
		return
			hdpickup(item)
			&&!hdpickup(item).bnevershowinpickupmanager
			&&!item.bnointeraction
			&&!item.bundroppable
			&&!item.buntossable
		;
	}
	action void nextitem(){invoker.cycleitem();}
	action void previtem(){invoker.cycleitem(false);}
	void cycleitem(bool forward=true){
		int thisindex=0;
		array<hdpickup> items;items.clear();
		for(inventory item=owner.inv;item!=null;item=!item?null:item.inv){
			if(ismanageable(item))items.push(hdpickup(item));
			if(item==thisitem)thisindex=items.size();  //already returns the next index not the current
		}
		if(!forward)thisindex-=2;  //get previous rather than next
		if(items.size()<1){
			thisitem=null;
			return;
		}
		if(forward){
			if(thisindex<items.size())thisitem=items[thisindex];
			else thisitem=items[0];
		}else{
			if(thisindex<0)thisitem=items[items.size()-1];
			else thisitem=items[thisindex];
		}
		weaponstatus[PMSS_DROPAMT]=1;
	}
	action void UpdateText(){
		let thisitem=invoker.thisitem;
		invoker.uitext=string.format("\cy\\\\\\\cfPickup Manager\cy///\n\n\n\n\n\n\cj%s",thisitem?(
			thisitem.gettag().."\n\cm( "..thisitem.getclassname().." )\n\cx"..thisitem.amount
			.."\n\caOn drop: "..invoker.weaponstatus[PMSS_DROPAMT]
		):"No item selected.");
	}
	override void DropOneAmmo(int amt){
		if(owner&&thisitem){
			string itemtype=thisitem.getclassname();
			amt=weaponstatus[PMSS_DROPAMT];
			bool droppedall=owner.countinv(itemtype)<=amt;
			owner.A_DropInventory(itemtype,amt);
			if(droppedall)cycleitem();
		}
	}
	override inventory CreateTossable(int amt){
		DropOneAmmo(amt);
		return null;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		sb.beginhud(forcescaled:true);
		let item=thisitem;
		if(thisitem){
			let ddi=item.icon;
			if(!ddi){
				let dds=item.spawnstate;
				if(dds!=null)ddi=dds.GetSpriteTexture(0);
			}
			if(ddi){
				vector2 dds=texman.getscaledsize(ddi);
				vector2 ddv=(1.,1.);
				if(min(dds.x,dds.y)<8.){
					ddv*=(8./min(dds.x,dds.y));
				}
				sb.drawtexture(ddi,(0,-smallfont.getheight()*4),
					sb.DI_ITEM_BOTTOM|sb.DI_SCREEN_CENTER,
					scale:ddv
				);
			}
		}
		sb.beginhud(forcescaled:false);
	}
	override void InitializeWepStats(bool idfa){
		if(!idfa)weaponstatus[PMSS_DROPAMT]=1;
	}
	states{
	ready:
		TNT1 A 1{
			if(!invoker.thisitem||invoker.thisitem.owner!=self)invoker.getfirstitem();
			A_WeaponReady(WRF_NOFIRE|WRF_ALLOWUSER3);
			int bt=player.cmd.buttons;
			if(bt&BT_ZOOM){
				int inputamt=GetMouseY(true);
				if(inputamt){
					if(abs(inputamt)<(1<<5))inputamt=clamp(inputamt,-1,1);
					else inputamt>>=5;
				}else if(justpressed(BT_ATTACK))inputamt=-1;
				if(justpressed(BT_ALTATTACK))inputamt=1;
				invoker.weaponstatus[PMSS_DROPAMT]=clamp(invoker.weaponstatus[PMSS_DROPAMT]+inputamt,1,invoker.thisitem?invoker.thisitem.amount:1);
			}
			else if(bt&BT_FIREMODE){
				int inputamt=GetMouseY(true)>>6;
				if(inputamt){
					int aia=abs(inputamt);
					for(int i=0;i<aia;i++){
						if(inputamt<0)previtem();
						else nextitem();
					}
				}
			}
			else if(justpressed(BT_ATTACK))nextitem();
			else if(justpressed(BT_ALTATTACK))previtem();
			UpdateText();
			A_WeaponMessage(invoker.uitext);
		}goto readyend;
	user3:
		TNT1 A 0 A_JumpIf(player.oldbuttons&BT_USER3,"nope");
		TNT1 A 0 A_SelectWeapon("MagManager");
		TNT1 A 0 A_WeaponReady(WRF_NONE);
		goto nope;
	}
}
enum PickupManagerStatus{
	PMSS_DROPAMT=1,
}
