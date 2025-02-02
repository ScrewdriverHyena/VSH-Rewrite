static Handle g_hHookGetMaxHealth;
static Handle g_hHookShouldTransmit;
static Handle g_hHookBallImpact;
static Handle g_hHookShouldBallTouch;
static Handle g_hSDKGetMaxHealth;
static Handle g_hSDKGetMaxAmmo;
static Handle g_hSDKSendWeaponAnim;
static Handle g_hSDKGetMaxClip;
static Handle g_hSDKRemoveWearable;
static Handle g_hSDKGetEquippedWearable;
static Handle g_hSDKEquipWearable;

void SDK_Init()
{
	GameData hGameData = new GameData("sdkhooks.games");
	if (hGameData == null) SetFailState("Could not find sdkhooks.games gamedata!");

	//This function is used to control player's max health
	int iOffset = hGameData.GetOffset("GetMaxHealth");
	g_hHookGetMaxHealth = DHookCreate(iOffset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, Hook_GetMaxHealth);
	if (g_hHookGetMaxHealth == null) LogMessage("Failed to create hook: CTFPlayer::GetMaxHealth!");

	//This function is used to retreive player's max health
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxHealth = EndPrepSDKCall();
	if (g_hSDKGetMaxHealth == null)
		LogMessage("Failed to create call: CTFPlayer::GetMaxHealth!");

	delete hGameData;

	hGameData = new GameData("sm-tf2.games");
	if (hGameData == null) SetFailState("Could not find sm-tf2.games gamedata!");

	int iRemoveWearableOffset = hGameData.GetOffset("RemoveWearable");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(iRemoveWearableOffset);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKRemoveWearable = EndPrepSDKCall();
	if (g_hSDKRemoveWearable == null)
		LogMessage("Failed to create call: CBasePlayer::RemoveWearable!");

	// This call allows us to equip a wearable
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(iRemoveWearableOffset-1);//In theory the virtual function for EquipWearable is rigth before RemoveWearable,
													//if it's always true (valve don't put a new function between these two), then we can use SM auto update offset for RemoveWearable and find EquipWearable from it
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKEquipWearable = EndPrepSDKCall();
	if(g_hSDKEquipWearable == null)
		LogMessage("Failed to create call: CBasePlayer::EquipWearable!");

	delete hGameData;

	hGameData = new GameData("vsh");
	if (hGameData == null) SetFailState("Could not find vsh gamedata!");

	// This call gets the weapon max ammo
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::GetMaxAmmo");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxAmmo = EndPrepSDKCall();
	if (g_hSDKGetMaxAmmo == null)
		LogMessage("Failed to create call: CTFPlayer::GetMaxAmmo!");

	// This call gets wearable equipped in loadout slots
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::GetEquippedWearableForLoadoutSlot");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKGetEquippedWearable = EndPrepSDKCall();
	if (g_hSDKGetEquippedWearable == null)
		LogMessage("Failed to create call: CTFPlayer::GetEquippedWearableForLoadoutSlot!");
	
	//This function is used to play the blocked knife animation
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBase::SendWeaponAnim");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKSendWeaponAnim = EndPrepSDKCall();
	if (g_hSDKSendWeaponAnim == null)
		LogMessage("Failed to create call: CTFWeaponBase::SendWeaponAnim!");

	// This call gets the maximum clip 1 for a given weapon
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxClip = EndPrepSDKCall();
	if (g_hSDKGetMaxClip == null)
		LogMessage("Failed to create call: CTFWeaponBase::GetMaxClip1!");

	// This hook allows entity to always transmit
	iOffset = hGameData.GetOffset("CBaseEntity::ShouldTransmit");
	g_hHookShouldTransmit = DHookCreate(iOffset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, Hook_EntityShouldTransmit);
	if (g_hHookShouldTransmit == null)
		LogMessage("Failed to create hook: CBaseEntity::ShouldTransmit!");
	else
		DHookAddParam(g_hHookShouldTransmit, HookParamType_ObjectPtr);
	
	// This hook calls when Sandman Ball stuns a player
	iOffset = hGameData.GetOffset("CTFStunBall::ApplyBallImpactEffectOnVictim");
	g_hHookBallImpact = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (g_hHookBallImpact == null)
		LogMessage("Failed to create hook: CTFStunBall::ApplyBallImpactEffectOnVictim!");
	else
		DHookAddParam(g_hHookBallImpact, HookParamType_CBaseEntity);
	
	// This hook calls when Sandman Ball want to touch
	iOffset = hGameData.GetOffset("CTFStunBall::ShouldBallTouch");
	g_hHookShouldBallTouch = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
	if (g_hHookShouldBallTouch == null)
		LogMessage("Failed to create hook: CTFStunBall::ApplyBallImpactEffectOnVictim!");
	else
		DHookAddParam(g_hHookShouldBallTouch, HookParamType_CBaseEntity);
	
	// This hook allows to allow/block medigun heals
	Handle hHook = DHookCreateFromConf(hGameData, "CWeaponMedigun::AllowedToHealTarget");
	if (hHook == null)
		LogMessage("Failed to create hook: CWeaponMedigun::AllowedToHealTarget!");
	else
		DHookEnableDetour(hHook, false, Hook_AllowedToHealTarget);
	
	delete hHook;
	
	// This hook allows to allow/block dispenser heals
	hHook = DHookCreateFromConf(hGameData, "CObjectDispenser::CouldHealTarget");
	if (hHook == null)
		LogMessage("Failed to create hook: CObjectDispenser::CouldHealTarget!");
	else
		DHookEnableDetour(hHook, false, Hook_CouldHealTarget);
	
	delete hHook;
	delete hGameData;
}

void SDK_HookGetMaxHealth(int iClient)
{
	if (g_hHookGetMaxHealth)
		DHookEntity(g_hHookGetMaxHealth, false, iClient);
}

void SDK_AlwaysTransmitEntity(int iEntity)
{
	if (g_hHookShouldTransmit)
		DHookEntity(g_hHookShouldTransmit, true, iEntity);
}

void SDK_HookBallImpact(int iEntity, DHookCallback callback)
{
	if (g_hHookBallImpact)
		DHookEntity(g_hHookBallImpact, false, iEntity, _, callback);
}

void SDK_HookBallTouch(int iEntity, DHookCallback callback)
{
	if (g_hHookShouldBallTouch)
		DHookEntity(g_hHookShouldBallTouch, false, iEntity, _, callback);
}

public MRESReturn Hook_GetMaxHealth(int iClient, Handle hReturn)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid && boss.iMaxHealth > 0)
	{
		DHookSetReturn(hReturn, boss.iMaxHealth);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn Hook_EntityShouldTransmit(int iEntity, Handle hReturn, Handle hParams)
{
	DHookSetReturn(hReturn, FL_EDICT_ALWAYS);
	return MRES_Supercede;
}

public MRESReturn Hook_AllowedToHealTarget(int iMedigun, Handle hReturn, Handle hParams)
{
	if (!g_bEnabled) return MRES_Ignored;
	if (g_iTotalRoundPlayed <= 0) return MRES_Ignored;
	
	int iHealTarget = DHookGetParam(hParams, 1);
	int iClient = GetEntPropEnt(iMedigun, Prop_Send, "m_hOwnerEntity");
	
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iHealTarget);
		if (0 < iHealTarget <= MaxClients && boss.bValid && !boss.bCanBeHealed)
		{
			//Dont allow medics heal boss
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
		
		TagsParams tParams = new TagsParams();
		TagsCore_CallSlot(iClient, TagsCall_Heal, WeaponSlot_Secondary, tParams);
		
		if (iHealTarget > MaxClients)
		{
			char sClassname[256];
			GetEntityClassname(iHealTarget, sClassname, sizeof(sClassname));
			
			//Override heal result
			int iResult;
			if (StrContains(sClassname, "obj_") == 0 && GetEntProp(iHealTarget, Prop_Send, "m_iTeamNum") == GetClientTeam(iClient) && tParams.GetIntEx("healbuilding", iResult))
			{
				bool bResult = !!iResult;
				DHookSetReturn(hReturn, bResult);
				delete tParams;
				return MRES_Supercede;
			}
		}
		
		delete tParams;
	}
	
	return MRES_Ignored;
}

public MRESReturn Hook_CouldHealTarget(int iDispenser, Handle hReturn, Handle hParams)
{
	int iHealTarget = DHookGetParam(hParams, 1);
	
	if (0 < iHealTarget <= MaxClients)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iHealTarget);
		if (boss.bValid && !boss.bCanBeHealed)
		{
			//Dont allow dispensers heal boss
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

int SDK_GetMaxAmmo(int iClient, int iSlot)
{
	if(g_hSDKGetMaxAmmo != null)
		return SDKCall(g_hSDKGetMaxAmmo, iClient, iSlot, -1);
	return -1;
}

void SDK_SendWeaponAnim(int weapon, int anim)
{
	if (g_hSDKSendWeaponAnim != null)
		SDKCall(g_hSDKSendWeaponAnim, weapon, anim);
}

int SDK_GetMaxClip(int iWeapon)
{
	if(g_hSDKGetMaxClip != null)
		return SDKCall(g_hSDKGetMaxClip, iWeapon);
	return -1;
}

int SDK_GetMaxHealth(int iClient)
{
	if (g_hSDKGetMaxHealth != null)
		return SDKCall(g_hSDKGetMaxHealth, iClient);
	return 0;
}

void SDK_RemoveWearable(int client, int iWearable)
{
	if(g_hSDKRemoveWearable != null)
		SDKCall(g_hSDKRemoveWearable, client, iWearable);
}

int SDK_GetEquippedWearable(int client, int iSlot)
{
	if(g_hSDKGetEquippedWearable != null)
		return SDKCall(g_hSDKGetEquippedWearable, client, iSlot);
	return -1;
}

void SDK_EquipWearable(int client, int iWearable)
{
	if(g_hSDKEquipWearable != null)
		SDKCall(g_hSDKEquipWearable, client, iWearable);
}