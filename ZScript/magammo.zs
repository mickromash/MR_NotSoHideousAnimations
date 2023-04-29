// ------------------------------------------------------------
// Tracked magazines (and clips and batteries)
// ------------------------------------------------------------
class HDMagAmmo:HDAmmo{
	array<int> mags; //or clips or batteries, whatever
	int maxperunit;property maxperunit:maxperunit;
	int inserttime;property inserttime:inserttime;
	int extracttime;property extracttime:extracttime;
	class<inventory> roundtype;property roundtype:roundtype;
	double roundbulk;property roundbulk:roundbulk;
	double magbulk;property magbulk:magbulk;
	bool mustshowinmagmanager;property mustshowinmagmanager:mustshowinmagmanager;
	default{
		hdmagammo.maxperunit 0;
		hdmagammo.roundtype "";
		hdmagammo.roundbulk 0;
		hdmagammo.magbulk 0;
		hdmagammo.mustshowinmagmanager false;

		hdmagammo.inserttime 8;
		hdmagammo.extracttime 4;

		inventory.maxamount 100;

		hdmagammo.landsound "misc/magdrop";
		hdmagammo.emptylandsound "misc/magdrop2";
	}
	virtual double getbulkonemag(int which){
		return magbulk+roundbulk*mags[which];
	}
	override double getbulk(){
		double result=magbulk+roundbulk;
		if(!result)return bulk*amount;
		result=0;
		SyncAmount();
		for(int i=0;i<amount;i++){
			result+=getbulkonemag(i);
		}
		return result;
	}

	//add mag amount or size as appropriate
	//should be called at the start of each interaction
	//should NEVER reduce the array to none if it was not none before
	virtual void SyncAmount(){
		amount=max(amount,mags.size());
		while(amount>mags.size()){
			//mags.push(random(1,maxperunit));	//testing
			mags.push(maxperunit);
		}
	}
	//remove one mag and return the value
	//use to load or drop
	int TakeMag(bool getmax){
		SyncAmount();
		if(amount<1)return -1;
		//the usual: get the last one
		if(!getmax){
			int lastmag=mags[mags.size()-1];
			mags.pop();
			amount=mags.size();
			return lastmag;
		}

		int maxindex=mags.find(maxperunit);
		//if fail, take the FIRST mag
		//(because last is probably what you just unloaded)
		if(
			maxindex==mags.size()
			&&mags[mags.size()-1]<maxperunit
		){
			int firstmag=mags[0];
			mags.delete(0);
			amount=mags.size();
			return firstmag;
		}
		//take one full mag
		mags.delete(maxindex);
		amount=mags.size();
		return maxperunit;
	}
	//take last mag and put it at index zero
	void LastToFirst(){
		SyncAmount();
		if(amount<2)return;
		mags.insert(0,mags[mags.size()-1]);
		mags.pop();
	}
	void FirstToLast(){
		SyncAmount();
		if(amount<2)return;
		mags.push(mags[0]);
		mags.delete(0);
	}
	//bring up the lowest-value mag
	//useful for refilling and discarding
	int LowestToLast(){
		SyncAmount();
		if(amount<2)return mags[0];
		int lowestindex=-1;
		int lowest=maxperunit;
		for(int i=0;i<amount;i++){
			if(lowest>mags[i]){
				lowest=mags[i];
				lowestindex=i;
			}
		}
		if(lowestindex<0)return maxperunit;
		mags.delete(lowestindex);
		mags.push(lowest);
		return lowest;
	}
	//bring up the highest-value non-full mag
	//useful for refilling and discarding
	void HighestFillableToLast(){
		SyncAmount();
		if(amount<2)return;
		int highestindex=-1;
		int highest=0;
		for(int i=0;i<amount;i++){
			if(highest>mags[i]&&mags[i]<maxperunit){
				highest=mags[i];
				highestindex=i;
			}
		}
		if(highestindex<0||highestindex==mags.size())return;
		mags.delete(highestindex);
		mags.push(highest);
	}
	//add a mag
	//use to unload
	virtual void AddAMag(int addamt=-1){
		SyncAmount();
		if(amount>=maxamount)return;
		if(addamt<0||addamt>maxperunit)addamt=maxperunit;
		mags.push(addamt);
		amount=mags.size();
	}
	//give a mag to someone
	static bool GiveMag(actor receiver,class<inventory> type,int giveamt){
		if(giveamt<0)return false;
		hdmagammo mmm;
		if(receiver.findinventory(type)){
			mmm=HDMagAmmo(receiver.findinventory(type));
			if(mmm.amount>=mmm.maxamount){
				HDMagAmmo.SpawnMag(receiver,type,giveamt);
				return false;
			}
			mmm.AddAMag(giveamt);
		}else{
			mmm=HDMagAmmo(receiver.GiveInventoryType(type));
			mmm.mags.clear();
			mmm.amount=0;
			mmm.AddAMag(giveamt);
		}

		if(
			receiver.player
			&&magmanager(receiver.player.readyweapon)
			&&(
				mmm.mustshowinmagmanager
				||mmm.roundtype!=""
			)
		){
			let mm=magmanager(receiver.player.readyweapon);
			mm.thismag=hdmagammo(receiver.findinventory(type));
			mm.updatetext();
		}
		return true;
	}
	//spawn and drop
	//mostly for unloads
	static actor SpawnMag(actor giver,class<inventory> type,int giveamt){
		if(giveamt<0)return null;
		let mmm=HDMagAmmo(giver.spawn(type,(giver.pos.xy,giver.pos.z+giver.height-12),ALLOW_REPLACE));
		mmm.angle=giver.angle;
		mmm.A_ChangeVelocity(2,0,-1,CVF_RELATIVE);
		mmm.vel+=giver.vel;
		mmm.amount=0;
		mmm.mags.clear();
		mmm.AddAMag(giveamt);
		if(
			!!giver
			&&(
				giver.bshootable
				||playerpawn(giver)
			)
		)mmm.bdontfacetalker=true;
		return mmm;
	}
	//for weapon reloading sequences so you don't look like an idiot
	//if(HDMagAmmo.NothingLoaded(self,"HD9mMag15"))
	static bool NothingLoaded(actor caller,class<inventory> magtype){
		let tocheck=HDMagAmmo(caller.findinventory(magtype));
		if(!tocheck)return true;
		tocheck.SyncAmount();
		for(int i=0;i<tocheck.amount;i++){
			if(tocheck.mags[i]>0)return false;
		}
		return true;
	}

	//add and extract rounds
	//return values can be used to stop loops or affect animations
	virtual bool Extract(){
		SyncAmount();
		if(
			mags.size()<1
			||mags[mags.size()-1]<1
		)return false;
		if(HDPickup.MaxGive(owner,roundtype,roundbulk)>=1)HDF.Give(owner,roundtype,1);
		else HDPickup.DropItem(owner,roundtype,1);
		owner.A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP);
		mags[mags.size()-1]--;
		return true;
	}
	virtual bool Insert(){
		SyncAmount();
		if(
			mags.size()<1
			||mags[mags.size()-1]>=maxperunit
			||!owner.countinv(roundtype)
		)return false;
		owner.A_TakeInventory(roundtype,1,TIF_NOTAKEINFINITE);
		owner.A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP);
		mags[mags.size()-1]++;
		return true;
	}
	//consolidate
	override void Consolidate(){
		SyncAmount();
		if(amount<2)return;
		int totalrounds=0;
		for(int i=0;i<amount;i++){
			totalrounds+=mags[i];
			mags[i]=0; //keep the empties, do NOT call clear()!
		}
		for(int i=0;i<amount;i++){
			int toinsert=min(maxperunit,totalrounds);
			mags[i]=toinsert;
			totalrounds-=toinsert;
			if(totalrounds<1)break;
		}
	}
	//purge empty
	void PurgeEmpties(){
		SyncAmount();
		LowestToLast();
		while(mags[mags.size()-1]<1){
			owner.A_DropInventory(getclassname(),1);
			LowestToLast();
		}
	}
	//max everything
	virtual void MaxCheat(){
		mags.clear();
		for(int i=0;i<amount;i++){
			mags.push(maxperunit);
		}
	}

	//set sprite for mag manager: magsprite, roundsprite, roundtype, scale
	virtual clearscope string,string,name,double getmagsprite(int thismagamt){
		return "","","Clip",2.;
	}

	//debug: log amounts
	void LogAmounts(bool owneronly=false){
		string stt=string.format("%i  %s: ",amount,getclassname());
		for(int i=0;i<amount;i++){
			stt=string.format("%s %i",stt,mags[i]);
		}
		if(owneronly&&owner)owner.A_Log(stt,true);
		else A_Log(stt);
	}

	override void actualpickup(actor other,bool silent){
		if(!other)other=picktarget;
		if(!other)return;
		name gcn=getclassname();
		if(HDPickup.MaxGive(other,gcn,getbulk())<1)return;

		if(!silent){
			//misc. effects
			other.A_StartSound(pickupsound,CHAN_AUTO);
			HDPickup.LogPickupMessage(other,pickupmessage());
		}

		//if no information, give max, otherwise use own array info
		if(mags.size()<1)other.A_GiveInventory(gcn);
		else HDMagAmmo.GiveMag(other,gcn,mags[0]);
		destroy();
	}
	override inventory createtossable(int amt){
		if(amount<1)return null;
		amt=min(max(1,amt),amount);

		HDMagAmmo iii=HDMagAmmo(spawn(getclass(),pos));
		iii.mags.clear();

		for(int i=0;i<amt;i++){
			iii.mags.push(takemag(false));
		}

		iii.amount=amt;
		amount=mags.size();

		return inventory(iii);
	}
	override void SplitPickup(){
		SyncAmount();
		while(amount>1){
			let aaa=HDMagAmmo(spawn(getclassname(),pos+(frandom(-1,1),frandom(-1,1),frandom(-1,1))));
			aaa.vel=vel+(frandom(-0.6,0.6),frandom(-0.6,0.6),frandom(-0.6,0.6));
			aaa.angle=angle;
			aaa.amount=1;
			aaa.mags.clear();
			aaa.mags.push(takemag(false));
			aaa.bdontfacetalker=bdontfacetalker;
		}

		//I'm staring at the above code and cannot see how this EVER happens, but it does
		if(mags.size()<1){
			destroy();
			return;
		}

		if(!mags[0]&&findstate("spawnempty"))setstatelabel("spawnempty");
		else if(findstate("spawn2")){
			if(hd_debug)A_Log(string.format("%s still uses spawn2",getclassname()));
			setstatelabel("spawn2");
		}
	}
	override void beginplay(){
		syncamount();
		super.beginplay();
	}


	//mag manager display
	virtual ui void DrawHUDStuff(HDStatusBar sb,MagManager wp,HDPlayerPawn hpl){
		if(!sb||!wp||!hpl)return;
		DrawMagList(sb,hpl);
	}
	//draw the rows of mags with their counts
	virtual ui void DrawMagList(HDStatusBar sb,HDPlayerPawn hpl,double scl=2.){
		int countermaxx=mags.size();
		int countermax=countermaxx-1;

		int howmanylines=countermax/5;
		int linecounter=countermax%5;
		if(linecounter<0)linecounter=4;

		string magsprite="";
		string roundsprite="";
		name roundtype="";

		int offx=-64-18*howmanylines;
		int offy=80;
		for(int i=0;i<countermaxx;i++){

			bool imax=i==countermax;
			if(imax){
				offx=-6;
				offy=50;
			}else if(
				linecounter<1
			){
				howmanylines--;
				offx=-64-18*howmanylines;
				offy=80;
				linecounter=4;
			}else{
				if(i>0){
					offx+=2;
					offy-=9;
				}
				linecounter--;
			}

			int thismagamt=mags[i];
			string magsprite="";
			[magsprite,roundsprite,roundtype,scl]=getmagsprite(thismagamt);

			sb.drawimage(magsprite,(offx,offy),
				sb.DI_SCREEN_CENTER|sb.DI_ITEM_RIGHT_TOP,
				scale:(scl,scl)*(imax?1.6:1.)
			);
			sb.drawstring(
				imax?sb.pSmallFont:sb.mamountfont,sb.FormatNumber(GetMagHudCount(thismagamt)),
				(offx+2,offy),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_LEFT,
				imax?font.CR_SAPPHIRE:font.CR_BROWN
			);
		}

		if(roundsprite!="")DrawRoundCount(sb,hpl,roundsprite,scl,offx,offy);
	}
	virtual ui void DrawRoundCount(HDStatusBar sb,HDPlayerPawn hpl,name roundsprite,double scl,int offx,int offy){
		offx+=40;
		scl=1.6;
		sb.drawstring(
			sb.pSmallFont,sb.FormatNumber(hpl.countinv(roundtype)),
			(offx+2,offy),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_LEFT,
			font.CR_BROWN
		);
		sb.drawimage(roundsprite,(offx,offy),
			sb.DI_SCREEN_CENTER|sb.DI_ITEM_RIGHT_TOP,
			scale:(scl,scl)
		);
	}
	//this allows a display other than the true internal number
	//useful for, e.g., ZM's 51=50+seal, or bitflags combined with count
	virtual clearscope int GetMagHudCount(int input){return input;}


	//all of this is just to make it clatter when it hits the ground
	sound landsound;property landsound:landsound;
	sound emptylandsound;property emptylandsound:emptylandsound;
	double lastvelz;
	override void Tick(){
		super.Tick();
		if(isfrozen())return;
		//let mag audibly clatter on the floor
		if(
			bdontfacetalker
			&&!vel.z
			&&lastvelz<-HDCONST_GRAVITY
			&&prev.z-max(floorz,pos.z)>=0.1
		){
			double mult=-0.2;
			let snd=landsound;
			if(
				emptylandsound!=""
				&&!mags[0]
				&&roundbulk>0
			){
				mult=-0.35;
				snd=emptylandsound;
			}
			vel.z=lastvelz*mult;
			A_StartSound(snd,CHAN_BODY,CHANF_OVERLAP,volume:min(abs(lastvelz)*0.3,1));
			if(roll==270)roll+=randompick(30,-30);
		}else if(
			roll!=270
			&&roll>180
		){
			if(roll>270){
				roll+=30;
				if(roll>=360)roll-=360;
			}else roll-=30;
		}

		lastvelz=vel.z;
	}
	action void A_SpawnEmpty(){
		invoker.brollsprite=true;invoker.brollcenter=true;
		if(invoker.bdontfacetalker)invoker.roll=270;
		else invoker.roll=randompick(0,0,0,0,2,2,2,2,1,3)*90;
		if(
			tics<0
			&&hdmath.deathmatchclutter()
		)A_SetTics(140);
	}


	states{
	use:
		TNT1 A 0{
			invoker.SyncAmount();
			A_SetInventory("MagManager",1);
			let mmm=MagManager(findinventory("MagManager"));
			mmm.thismag=invoker;mmm.thismagtype=invoker.getclassname();
			UseInventory(mmm);

			if(!invoker.amount||!hd_debug)return;

			invoker.LogAmounts(true);

			//stuff to test
			//give hdmagammo 10;wait 1;use hdmagammo
			//A_Log("PurgeEmpties");invoker.PurgeEmpties();
				//MaxCheat
				//LastToFirst
				//LowestToLast
				//HighestFillableToLast
				//Extract
				//Insert
				//Consolidate
				//TakeMag(true)
				//TakeMag(false)
				//SpawnMag
				//PurgeEmpties
			//invoker.LogAmounts();
		}fail;
	spawn:
		CELL A -1;
		stop;
	}
}
