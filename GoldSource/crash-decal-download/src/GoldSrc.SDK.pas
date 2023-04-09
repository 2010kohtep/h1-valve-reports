(*============ (C) Copyright 2020, Alexander B. All rights reserved. ============*)
(*                                                                               *)
(*  Module:                                                                      *)
(*    GoldSrc.SDK                                                                *)
(*                                                                               *)
(*  License:                                                                     *)
(*    You may freely use this code provided you retain this copyright message.   *)
(*                                                                               *)
(*  Description:                                                                 *)
(*    Provides relatively full SDK for GoldSource renderer library.              *)
(*                                                                               *)
(*  There are several important nuances to consider when working with            *)
(*  this file:                                                                   *)
(*                                                                               *)
(*  - Pay special attention when working with the $SizeOf compiler directive.    *)
(*    The SizeOf preprocessor directive does not work correctly in some cases.   *)
(*    This manifests itself in incorrect calculation of the size of types of     *)
(*    this kind:                                                                 *)
(*                                                                               *)
(*    type                                                                       *)
(*      model_t = model_s;                                                       *)
(*                                                                               *)
(*    Therefore, the "IF SizeOf" checks must be performed very carefully. Using  *)
(*    such overridden types in other records can also give an incorrect SizeOf   *)
(*    value for the record where the type is declared.                           *)
(*                                                                               *)
(*  - Never use the $ALIGN compiler directive and its derivatives. The Delphi    *)
(*    compiler is smart enough to choose the necessary alignment on its own, and *)
(*    the presence of such a directive will break the SizeOf values for many     *)
(*    structures (mainly for those with types larger than 4 bytes). Use 'packed' *)
(*    parameter to set alignment to 1 if you want to turn off alignment for      *)
(*    certain records (for example - demo_command_t).                            *)
(*                                                                               *)
(*  Special tags:                                                                *)
(*    @xref: Defines the name of the function where you can find out the exact   *)
(*           size of the type                                                    *)
(*    @todo: Type needs to be completed                                          *)
(*    @note: Interesting notes                                                   *)
(*===============================================================================*)

unit GoldSrc.SDK;

{$LEGACYIFEND ON}
{$MINENUMSIZE 4}

{$UNDEF MSME}

interface

const
  GSSDK_VERSION = 20200918;

const
  MAX_PATH = 260;

  FBEAM_STARTENTITY = $00000001;
  FBEAM_ENDENTITY = $00000002;
  FBEAM_FADEIN = $00000004;
  FBEAM_FADEOUT = $00000008;
  FBEAM_SINENOISE = $00000010;
  FBEAM_SOLID = $00000020;
  FBEAM_SHADEIN = $00000040;
  FBEAM_SHADEOUT = $00000080;
  FBEAM_STARTVISIBLE = $10000000;		// Has this client actually seen this beam's start entity yet?
  FBEAM_ENDVISIBLE = $20000000;		// Has this client actually seen this beam's end entity yet?
  FBEAM_ISACTIVE = $40000000;
  FBEAM_FOREVER = $80000000;

  HISTORY_MAX = 64;  // Must be power of 2
  HISTORY_MASK = HISTORY_MAX - 1;

  STUDIO_RENDER = 1;
  STUDIO_EVENTS = 2;

  PLANE_ANYZ = 5;

  ALIAS_Z_CLIP_PLANE = 5;

  // flags in finalvert_t.flags
  ALIAS_LEFT_CLIP = $0001;
  ALIAS_TOP_CLIP = $0002;
  ALIAS_RIGHT_CLIP = $0004;
  ALIAS_BOTTOM_CLIP = $0008;
  ALIAS_Z_CLIP = $0010;
  ALIAS_ONSEAM = $0020;
  ALIAS_XY_CLIP_MASK = $000F;

  ZISCALE	= Single($8000);

  CACHE_SIZE = 32; // used to align key data structures

  // Max # of clients allowed in a server.
  MAX_CLIENTS = 32;

  // How many bits to use to encode an edict.
  MAX_EDICT_BITS = 11;			// # of bits needed to represent max edicts
  // Max # of edicts in a level (2048)
  MAX_EDICTS = 1 shl MAX_EDICT_BITS;

  // How many data slots to use when in multiplayer (must be power of 2)
  MULTIPLAYER_BACKUP = 64;
  // Same for single player
  SINGLEPLAYER_BACKUP = 8;

  //
  // Constants shared by the engine and dlls
  // This header file included by engine files and DLL files.
  // Most came from server.h
  // edict->flags
  FL_FLY = 1 shl 0;	// Changes the SV_Movestep() behavior to not need to be on ground
  FL_SWIM = 1 shl 1;	// Changes the SV_Movestep() behavior to not need to be on ground (but stay in water)
  FL_CONVEYOR = 1 shl 2;
  FL_CLIENT	= 1 shl 3;
  FL_INWATER = 1 shl 4;
  FL_MONSTER = 1 shl 5;
  FL_GODMODE = 1 shl 6;
  FL_NOTARGET = 1 shl 7;
  FL_SKIPLOCALHOST = 1 shl 8;	// Don't send entity to local host, it's predicting this entity itself
  FL_ONGROUND = 1 shl 9;	// At rest / on the ground
  FL_PARTIALGROUND = 1 shl 10;	// not all corners are valid
  FL_WATERJUMP = 1 shl 11;	// player jumping out of water
  FL_FROZEN = 1 shl 12; // Player is frozen for 3rd person camera
  FL_FAKECLIENT = 1 shl 13;	// JAC: fake client, simulated server side; don't send network messages to them
  FL_DUCKING = 1 shl 14;	// Player flag -- Player is fully crouched
  FL_FLOAT = 1 shl 15;	// Apply floating force to this entity when in water
  FL_GRAPHED = 1 shl 16; // worldgraph has this ent listed as something that blocks a connection

  // UNDONE: Do we need these?
  FL_IMMUNE_WATER = 1 shl 17;
  FL_IMMUNE_SLIME = 1 shl 18;
  FL_IMMUNE_LAVA = 1 shl 19;

  FL_PROXY = 1 shl 20;	// This is a spectator proxy
  FL_ALWAYSTHINK = 1 shl 21;	// Brush model flag -- call think every frame regardless of nextthink - ltime (for constantly changing velocity/path)
  FL_BASEVELOCITY = 1 shl 22;	// Base velocity has been applied this frame (used to convert base velocity into momentum)
  FL_MONSTERCLIP = 1 shl 23;	// Only collide in with monsters who have FL_MONSTERCLIP set
  FL_ONTRAIN = 1 shl 24; // Player is _controlling_ a train, so movement commands should be ignored on client during prediction.
  FL_WORLDBRUSH = 1 shl 25;	// Not moveable/removeable brush entity (really part of the world, but represented as an entity for transparency or something)
  FL_SPECTATOR = 1 shl 26; // This client is a spectator, don't run touch functions, etc.
  FL_CUSTOMENTITY = 1 shl 29;	// This is a custom entity
  FL_KILLME = 1 shl 30;	// This entity is marked for death -- This allows the engine to kill ents at the appropriate time
  FL_DORMANT = 1 shl 31;	// Entity is dormant, no updates to client

  // SV_EmitSound2 flags
  SND_EMIT2_NOPAS	= 1 shl 0;	// never to do check PAS
  SND_EMIT2_INVOKER	= 1 shl 1;	// do not send to the client invoker

  // Engine edict->spawnflags
  SF_NOTINDEATHMATCH = $0800;	// Do not spawn when deathmatch and loading entities from a file


  // Goes into globalvars_t.trace_flags
  FTRACE_SIMPLEBOX = 1 shl 0;	// Traceline with a simple box

  // walkmove modes
  WALKMOVE_NORMAL = 0; // normal walkmove
  WALKMOVE_WORLDONLY = 1; // doesn't hit ANY entities, no matter what the solid type
  WALKMOVE_CHECKONLY = 2; // move, but don't touch triggers

  // edict->movetype values
  MOVETYPE_NONE = 0;		// never moves
  //MOVETYPE_ANGLENOCLIP	1;
  //MOVETYPE_ANGLECLIP		2;
  MOVETYPE_WALK = 3;		// Player only - moving on the ground
  MOVETYPE_STEP = 4;		// gravity, special edge handling -- monsters use this
  MOVETYPE_FLY = 5;		// No gravity, but still collides with stuff
  MOVETYPE_TOSS = 6;		// gravity/collisions
  MOVETYPE_PUSH = 7;		// no clip to world, push and crush
  MOVETYPE_NOCLIP = 8;		// No gravity, no collisions, still do velocity/avelocity
  MOVETYPE_FLYMISSILE = 9;		// extra size to monsters
  MOVETYPE_BOUNCE = 10;		// Just like Toss, but reflect velocity when contacting surfaces
  MOVETYPE_BOUNCEMISSILE = 11;		// bounce w/o gravity
  MOVETYPE_FOLLOW = 12;		// track movement of aiment
  MOVETYPE_PUSHSTEP = 13;		// BSP model that needs physics/world collisions (uses nearest hull for world collision)

  // edict->solid values
  // NOTE: Some movetypes will cause collisions independent of SOLID_NOT/SOLID_TRIGGER when the entity moves
  // SOLID only effects OTHER entities colliding with this one when they move - UGH!
  SOLID_NOT	= 0;		// no interaction with other objects
  SOLID_TRIGGER	= 1;		// touch on edge, but not blocking
  SOLID_BBOX	= 2;		// touch on edge, block
  SOLID_SLIDEBOX	= 3;		// touch on edge, but not an onground
  SOLID_BSP	= 4;		// bsp clip, touch on edge, block

  // edict->deadflag values
  DEAD_NO	= 0; // alive
  DEAD_DYING = 1; // playing death animation or still falling off of a ledge waiting to hit ground
  DEAD_DEAD	= 2; // dead. lying still.
  DEAD_RESPAWNABLE = 3;
  DEAD_DISCARDBODY = 4;

  DAMAGE_NO	= 0;
  DAMAGE_YES = 1;
  DAMAGE_AIM = 2;

  // entity effects
  EF_BRIGHTFIELD = 1;	// swirling cloud of particles
  EF_MUZZLEFLASH = 2;	// single frame ELIGHT on entity attachment 0
  EF_BRIGHTLIGHT = 4;	// DLIGHT centered at entity origin
  EF_DIMLIGHT = 8;	// player flashlight
  EF_INVLIGHT = 16;	// get lighting from ceiling
  EF_NOINTERP = 32;	// don't interpolate the next frame
  EF_LIGHT = 64;	// rocket flare glow sprite
  EF_NODRAW = 128;	// don't draw entity
  EF_NIGHTVISION = 256; // player nightvision
  EF_SNIPERLASER = 512; // sniper laser effect
  EF_FIBERCAMERA = 1024;// fiber camera

  // entity flags
  EFLAG_SLERP = 1;	// do studio interpolation of this entity

  //
  // temp entity events
  //
  TE_BEAMPOINTS = 0;		// beam effect between two points
  // coord coord coord (start position)
  // coord coord coord (end position)
  // short (sprite index)
  // byte (starting frame)
  // byte (frame rate in 0.1's)
  // byte (life in 0.1's)
  // byte (line width in 0.1's)
  // byte (noise amplitude in 0.01's)
  // byte,byte,byte (color)
  // byte (brightness)
  // byte (scroll speed in 0.1's)

  TE_BEAMENTPOINT = 1;		// beam effect between point and entity
  // short (start entity)
  // coord coord coord (end position)
  // short (sprite index)
  // byte (starting frame)
  // byte (frame rate in 0.1's)
  // byte (life in 0.1's)
  // byte (line width in 0.1's)
  // byte (noise amplitude in 0.01's)
  // byte,byte,byte (color)
  // byte (brightness)
  // byte (scroll speed in 0.1's)

  TE_GUNSHOT = 2;		// particle effect plus ricochet sound
  // coord coord coord (position)

  TE_EXPLOSION = 3;		// additive sprite, 2 dynamic lights, flickering particles, explosion sound, move vertically 8 pps
  // coord coord coord (position)
  // short (sprite index)
  // byte (scale in 0.1's)
  // byte (framerate)
  // byte (flags)
  //
  // The Explosion effect has some flags to control performance/aesthetic features:
  TE_EXPLFLAG_NONE = 0;	// all flags clear makes default Half-Life explosion
  TE_EXPLFLAG_NOADDITIVE = 1;	// sprite will be drawn opaque (ensure that the sprite you send is a non-additive sprite)
  TE_EXPLFLAG_NODLIGHTS = 2;	// do not render dynamic lights
  TE_EXPLFLAG_NOSOUND = 4;	// do not play client explosion sound
  TE_EXPLFLAG_NOPARTICLES = 8;	// do not draw particles


  TE_TAREXPLOSION = 4;		// Quake1 "tarbaby" explosion with sound
  // coord coord coord (position)

  TE_SMOKE = 5;		// alphablend sprite, move vertically 30 pps
  // coord coord coord (position)
  // short (sprite index)
  // byte (scale in 0.1's)
  // byte (framerate)

  TE_TRACER = 6;		// tracer effect from point to point
  // coord, coord, coord (start)
  // coord, coord, coord (end)

  TE_LIGHTNING = 7;		// TE_BEAMPOINTS with simplified parameters
  // coord, coord, coord (start)
  // coord, coord, coord (end)
  // byte (life in 0.1's)
  // byte (width in 0.1's)
  // byte (amplitude in 0.01's)
  // short (sprite model index)

  TE_BEAMENTS = 8;
  // short (start entity)
  // short (end entity)
  // short (sprite index)
  // byte (starting frame)
  // byte (frame rate in 0.1's)
  // byte (life in 0.1's)
  // byte (line width in 0.1's)
  // byte (noise amplitude in 0.01's)
  // byte,byte,byte (color)
  // byte (brightness)
  // byte (scroll speed in 0.1's)

  TE_SPARKS = 9;		// 8 random tracers with gravity, ricochet sprite
  // coord coord coord (position)

  TE_LAVASPLASH = 10;		// Quake1 lava splash
  // coord coord coord (position)

  TE_TELEPORT = 11;		// Quake1 teleport splash
  // coord coord coord (position)

  TE_EXPLOSION2 = 12;		// Quake1 colormaped (base palette) particle explosion with sound
  // coord coord coord (position)
  // byte (starting color)
  // byte (num colors)

  TE_BSPDECAL = 13;		// Decal from the .BSP file
  // coord, coord, coord (x,y,z), decal position (center of texture in world)
  // short (texture index of precached decal texture name)
  // short (entity index)
  // [optional - only included if previous short is non-zero (not the world)] short (index of model of above entity)

  TE_IMPLOSION = 14;		// tracers moving toward a point
  // coord, coord, coord (position)
  // byte (radius)
  // byte (count)
  // byte (life in 0.1's)

  TE_SPRITETRAIL = 15;		// line of moving glow sprites with gravity, fadeout, and collisions
  // coord, coord, coord (start)
  // coord, coord, coord (end)
  // short (sprite index)
  // byte (count)
  // byte (life in 0.1's)
  // byte (scale in 0.1's)
  // byte (velocity along vector in 10's)
  // byte (randomness of velocity in 10's)

  TE_BEAM = 16;		// obsolete

  TE_SPRITE = 17;		// additive sprite, plays 1 cycle
  // coord, coord, coord (position)
  // short (sprite index)
  // byte (scale in 0.1's)
  // byte (brightness)

  TE_BEAMSPRITE = 18;		// A beam with a sprite at the end
  // coord, coord, coord (start position)
  // coord, coord, coord (end position)
  // short (beam sprite index)
  // short (end sprite index)

  TE_BEAMTORUS = 19;		// screen aligned beam ring, expands to max radius over lifetime
  // coord coord coord (center position)
  // coord coord coord (axis and radius)
  // short (sprite index)
  // byte (starting frame)
  // byte (frame rate in 0.1's)
  // byte (life in 0.1's)
  // byte (line width in 0.1's)
  // byte (noise amplitude in 0.01's)
  // byte,byte,byte (color)
  // byte (brightness)
  // byte (scroll speed in 0.1's)

  TE_BEAMDISK = 20;		// disk that expands to max radius over lifetime
  // coord coord coord (center position)
  // coord coord coord (axis and radius)
  // short (sprite index)
  // byte (starting frame)
  // byte (frame rate in 0.1's)
  // byte (life in 0.1's)
  // byte (line width in 0.1's)
  // byte (noise amplitude in 0.01's)
  // byte,byte,byte (color)
  // byte (brightness)
  // byte (scroll speed in 0.1's)

  TE_BEAMCYLINDER = 21;		// cylinder that expands to max radius over lifetime
  // coord coord coord (center position)
  // coord coord coord (axis and radius)
  // short (sprite index)
  // byte (starting frame)
  // byte (frame rate in 0.1's)
  // byte (life in 0.1's)
  // byte (line width in 0.1's)
  // byte (noise amplitude in 0.01's)
  // byte,byte,byte (color)
  // byte (brightness)
  // byte (scroll speed in 0.1's)

  TE_BEAMFOLLOW = 22;		// create a line of decaying beam segments until entity stops moving
  // short (entity:attachment to follow)
  // short (sprite index)
  // byte (life in 0.1's)
  // byte (line width in 0.1's)
  // byte,byte,byte (color)
  // byte (brightness)

  TE_GLOWSPRITE = 23;
  // coord, coord, coord (pos) short (model index) byte (scale / 10)

  TE_BEAMRING = 24;		// connect a beam ring to two entities
  // short (start entity)
  // short (end entity)
  // short (sprite index)
  // byte (starting frame)
  // byte (frame rate in 0.1's)
  // byte (life in 0.1's)
  // byte (line width in 0.1's)
  // byte (noise amplitude in 0.01's)
  // byte,byte,byte (color)
  // byte (brightness)
  // byte (scroll speed in 0.1's)

  TE_STREAK_SPLASH = 25;		// oriented shower of tracers
  // coord coord coord (start position)
  // coord coord coord (direction vector)
  // byte (color)
  // short (count)
  // short (base speed)
  // short (ramdon velocity)

  TE_BEAMHOSE = 26;		// obsolete

  TE_DLIGHT = 27;		// dynamic light, effect world, minor entity effect
  // coord, coord, coord (pos)
  // byte (radius in 10's)
  // byte byte byte (color)
  // byte (brightness)
  // byte (life in 10's)
  // byte (decay rate in 10's)

  TE_ELIGHT = 28;		// point entity light, no world effect
  // short (entity:attachment to follow)
  // coord coord coord (initial position)
  // coord (radius)
  // byte byte byte (color)
  // byte (life in 0.1's)
  // coord (decay rate)

  TE_TEXTMESSAGE = 29;
  // short 1.2.13 x (-1 = center)
  // short 1.2.13 y (-1 = center)
  // byte Effect 0 = fade in/fade out
        // 1 is flickery credits
        // 2 is write out (training room)

  // 4 bytes r,g,b,a color1	(text color)
  // 4 bytes r,g,b,a color2	(effect color)
  // ushort 8.8 fadein time
  // ushort 8.8  fadeout time
  // ushort 8.8 hold time
  // optional ushort 8.8 fxtime	(time the highlight lags behing the leading text in effect 2)
  // string text message		(512 chars max sz string)
  TE_LINE = 30;
  // coord, coord, coord		startpos
  // coord, coord, coord		endpos
  // short life in 0.1 s
  // 3 bytes r, g, b

  TE_BOX = 31;
  // coord, coord, coord		boxmins
  // coord, coord, coord		boxmaxs
  // short life in 0.1 s
  // 3 bytes r, g, b

  TE_KILLBEAM = 99;		// kill all beams attached to entity
  // short (entity)

  TE_LARGEFUNNEL = 100;
  // coord coord coord (funnel position)
  // short (sprite index)
  // short (flags)

  TE_BLOODSTREAM = 101;		// particle spray
  // coord coord coord (start position)
  // coord coord coord (spray vector)
  // byte (color)
  // byte (speed)

  TE_SHOWLINE = 102;		// line of particles every 5 units, dies in 30 seconds
  // coord coord coord (start position)
  // coord coord coord (end position)

  TE_BLOOD = 103;		// particle spray
  // coord coord coord (start position)
  // coord coord coord (spray vector)
  // byte (color)
  // byte (speed)

  TE_DECAL = 104;		// Decal applied to a brush entity (not the world)
  // coord, coord, coord (x,y,z), decal position (center of texture in world)
  // byte (texture index of precached decal texture name)
  // short (entity index)

  TE_FIZZ = 105;		// create alpha sprites inside of entity, float upwards
  // short (entity)
  // short (sprite index)
  // byte (density)

  TE_MODEL = 106;		// create a moving model that bounces and makes a sound when it hits
  // coord, coord, coord (position)
  // coord, coord, coord (velocity)
  // angle (initial yaw)
  // short (model index)
  // byte (bounce sound type)
  // byte (life in 0.1's)

  TE_EXPLODEMODEL = 107;		// spherical shower of models, picks from set
  // coord, coord, coord (origin)
  // coord (velocity)
  // short (model index)
  // short (count)
  // byte (life in 0.1's)

  TE_BREAKMODEL = 108;		// box of models or sprites
  // coord, coord, coord (position)
  // coord, coord, coord (size)
  // coord, coord, coord (velocity)
  // byte (random velocity in 10's)
  // short (sprite or model index)
  // byte (count)
  // byte (life in 0.1 secs)
  // byte (flags)

  TE_GUNSHOTDECAL = 109;		// decal and ricochet sound
  // coord, coord, coord (position)
  // short (entity index???)
  // byte (decal???)

  TE_SPRITE_SPRAY = 110;		// spay of alpha sprites
  // coord, coord, coord (position)
  // coord, coord, coord (velocity)
  // short (sprite index)
  // byte (count)
  // byte (speed)
  // byte (noise)

  TE_ARMOR_RICOCHET = 111;		// quick spark sprite, client ricochet sound.
  // coord, coord, coord (position)
  // byte (scale in 0.1's)

  TE_PLAYERDECAL = 112;		// ???
  // byte (playerindex)
  // coord, coord, coord (position)
  // short (entity???)
  // byte (decal number???)
  // [optional] short (model index???)

  TE_BUBBLES = 113;		// create alpha sprites inside of box, float upwards
  // coord, coord, coord (min start position)
  // coord, coord, coord (max start position)
  // coord (float height)
  // short (model index)
  // byte (count)
  // coord (speed)

  TE_BUBBLETRAIL = 114;		// create alpha sprites along a line, float upwards
  // coord, coord, coord (min start position)
  // coord, coord, coord (max start position)
  // coord (float height)
  // short (model index)
  // byte (count)
  // coord (speed)

  TE_BLOODSPRITE = 115;		// spray of opaque sprite1's that fall, single sprite2 for 1..2 secs (this is a high-priority tent)
  // coord, coord, coord (position)
  // short (sprite1 index)
  // short (sprite2 index)
  // byte (color)
  // byte (scale)

  TE_WORLDDECAL = 116;		// Decal applied to the world brush
  // coord, coord, coord (x,y,z), decal position (center of texture in world)
  // byte (texture index of precached decal texture name)

  TE_WORLDDECALHIGH = 117;		// Decal (with texture index > 256) applied to world brush
  // coord, coord, coord (x,y,z), decal position (center of texture in world)
  // byte (texture index of precached decal texture name - 256)

  TE_DECALHIGH = 118;		// Same as TE_DECAL, but the texture index was greater than 256
  // coord, coord, coord (x,y,z), decal position (center of texture in world)
  // byte (texture index of precached decal texture name - 256)
  // short (entity index)

  TE_PROJECTILE = 119;		// Makes a projectile (like a nail) (this is a high-priority tent)
  // coord, coord, coord (position)
  // coord, coord, coord (velocity)
  // short (modelindex)
  // byte (life)
  // byte (owner)  projectile won't collide with owner (if owner == 0, projectile will hit any client).

  TE_SPRAY = 120;		// Throws a shower of sprites or models
  // coord, coord, coord (position)
  // coord, coord, coord (direction)
  // short (modelindex)
  // byte (count)
  // byte (speed)
  // byte (noise)
  // byte (rendermode)

  TE_PLAYERSPRITES = 121;		// sprites emit from a player's bounding box (ONLY use for players!)
  // byte (playernum)
  // short (sprite modelindex)
  // byte (count)
  // byte (variance) (0 = no variance in size) (10 = 10% variance in size)

  TE_PARTICLEBURST = 122;		// very similar to lavasplash.
  // coord (origin)
  // short (radius)
  // byte (particle color)
  // byte (duration * 10) (will be randomized a bit)

  TE_FIREFIELD = 123;		// makes a field of fire.
  // coord (origin)
  // short (radius) (fire is made in a square around origin. -radius, -radius to radius, radius)
  // short (modelindex)
  // byte (count)
  // byte (flags)
  // byte (duration (in seconds) * 10) (will be randomized a bit)
  //
  // to keep network traffic low, this message has associated flags that fit into a byte:
  TEFIRE_FLAG_ALLFLOAT = 1; // all sprites will drift upwards as they animate
  TEFIRE_FLAG_SOMEFLOAT = 2; // some of the sprites will drift upwards. (50% chance)
  TEFIRE_FLAG_LOOP = 4; // if set, sprite plays at 15 fps, otherwise plays at whatever rate stretches the animation over the sprite's duration.
  TEFIRE_FLAG_ALPHA = 8; // if set, sprite is rendered alpha blended at 50% else, opaque
  TEFIRE_FLAG_PLANAR = 16; // if set, all fire sprites have same initial Z instead of randomly filling a cube.
  TEFIRE_FLAG_ADDITIVE = 32; // if set, sprite is rendered non-opaque with additive

  TE_PLAYERATTACHMENT = 124; // attaches a TENT to a player (this is a high-priority tent)
  // byte (entity index of player)
  // coord (vertical offset) ( attachment origin.z = player origin.z + vertical offset )
  // short (model index)
  // short (life * 10 );

  TE_KILLPLAYERATTACHMENTS = 125; // will expire all TENTS attached to a player.
  // byte (entity index of player)

  TE_MULTIGUNSHOT = 126; // much more compact shotgun message
  // This message is used to make a client approximate a 'spray' of gunfire.
  // Any weapon that fires more than one bullet per frame and fires in a bit of a spread is
  // a good candidate for MULTIGUNSHOT use. (shotguns)
  //
  // NOTE: This effect makes the client do traces for each bullet, these client traces ignore
  //		 entities that have studio models.Traces are 4096 long.
  //
  // coord (origin)
  // coord (origin)
  // coord (origin)
  // coord (direction)
  // coord (direction)
  // coord (direction)
  // coord (x noise * 100)
  // coord (y noise * 100)
  // byte (count)
  // byte (bullethole decal texture index)

  TE_USERTRACER = 127; // larger message than the standard tracer, but allows some customization.
  // coord (origin)
  // coord (origin)
  // coord (origin)
  // coord (velocity)
  // coord (velocity)
  // coord (velocity)
  // byte ( life * 10 )
  // byte ( color ) this is an index into an array of color vectors in the engine. (0 - )
  // byte ( length * 10 )

  // contents of a spot in the world
  CONTENTS_EMPTY = -1;
  CONTENTS_SOLID = -2;
  CONTENTS_WATER = -3;
  CONTENTS_SLIME = -4;
  CONTENTS_LAVA = -5;
  CONTENTS_SKY = -6;

  CONTENTS_LADDER = -16;

  CONTENT_FLYFIELD = -17;
  CONTENT_GRAVITY_FLYFIELD = -18;
  CONTENT_FOG = -19;

  CONTENT_EMPTY = -1;
  CONTENT_SOLID = -2;
  CONTENT_WATER = -3;
  CONTENT_SLIME = -4;
  CONTENT_LAVA = -5;
  CONTENT_SKY= -6;

  // channels
  CHAN_AUTO = 0;
  CHAN_WEAPON = 1;
  CHAN_VOICE = 2;
  CHAN_ITEM = 3;
  CHAN_BODY = 4;
  CHAN_STREAM = 5;			// allocate stream channel from the static or dynamic area
  CHAN_STATIC = 6;			// allocate channel from the static area
  CHAN_NETWORKVOICE_BASE  = 7;		// voice data coming across the network
  CHAN_NETWORKVOICE_END = 500;		// network voice data reserves slots (CHAN_NETWORKVOICE_BASE through CHAN_NETWORKVOICE_END).
  CHAN_BOT = 501;			// channel used for bot chatter.

  // attenuation values
  ATTN_NONE = 0;
  ATTN_NORM: Single = 0.8;
  ATTN_IDLE: Single = 2.0;
  ATTN_STATIC: Single = 1.25;

  // pitch values
  PITCH_NORM = 100;			// non-pitch shifted
  PITCH_LOW = 95;			// other values are possible - 0-255, where 255 is very high
  PITCH_HIGH = 120;

  // volume values
  VOL_NORM = 1.0;

  BREAK_TYPEMASK = $4F;
  BREAK_GLASS = $01;
  BREAK_METAL = $02;
  BREAK_FLESH = $04;
  BREAK_WOOD = $08;

  BREAK_SMOKE = $10;
  BREAK_TRANS = $20;
  BREAK_CONCRETE = $40;
  BREAK_2 = $80;

  // Colliding temp entity sounds

  BOUNCE_GLASS = BREAK_GLASS;
  BOUNCE_METAL = BREAK_METAL;
  BOUNCE_FLESH = BREAK_FLESH;
  BOUNCE_WOOD = BREAK_WOOD;
  BOUNCE_SHRAP = $10;
  BOUNCE_SHELL = $20;
  BOUNCE_CONCRETE = BREAK_CONCRETE;
  BOUNCE_SHOTSHELL = $80;

  // Temp entity bounce sound types
  TE_BOUNCE_NULL = 0;
  TE_BOUNCE_SHELL = 1;
  TE_BOUNCE_SHOTSHELL = 2;

  // Rendering constants
  kRenderNormal = 0;			// src
  kRenderTransColor = 1;		// c*a+dest*(1-a)
  kRenderTransTexture = 2;	// src*a+dest*(1-a)
  kRenderGlow = 3;			// src*a+dest -- No Z buffer checks
  kRenderTransAlpha = 4;		// src*srca+dest*(1-srca)
  kRenderTransAdd = 5;		// src*a+dest

  kRenderFxNone = 0;
  kRenderFxPulseSlow = 1;
  kRenderFxPulseFast = 2;
  kRenderFxPulseSlowWide = 3;
  kRenderFxPulseFastWide = 4;
  kRenderFxFadeSlow = 5;
  kRenderFxFadeFast = 6;
  kRenderFxSolidSlow = 7;
  kRenderFxSolidFast = 8;
  kRenderFxStrobeSlow = 9;
  kRenderFxStrobeFast = 10;
  kRenderFxStrobeFaster = 11;
  kRenderFxFlickerSlow = 12;
  kRenderFxFlickerFast = 13;
  kRenderFxNoDissipation = 14;
  kRenderFxDistort = 15;			// Distort/scale/translate flicker
  kRenderFxHologram = 16;			// kRenderFxDistort + distance fade
  kRenderFxDeadPlayer = 17;		// kRenderAmt is the player index
  kRenderFxExplode = 18;			// Scale up really big!
  kRenderFxGlowShell = 19;			// Glowing Shell
  kRenderFxClampMinScale = 20;		// Keep this sprite from getting very small (SPRITES only!)
  kRenderFxLightMultiplier = 21;	//CTM !!!CZERO added to tell the studiorender that the value in iuser2 is a lightmultiplier

  FCVAR_ARCHIVE = 1 shl 0;	// set to cause it to be saved to vars.rc
  FCVAR_USERINFO = 1 shl 1;	// changes the client's info string
  FCVAR_SERVER = 1 shl 2;	// notifies players when changed
  FCVAR_EXTDLL = 1 shl 3;	// defined by external DLL
  FCVAR_CLIENTDLL = 1 shl 4;  // defined by the client dll
  FCVAR_PROTECTED = 1 shl 5;  // It's a server cvar, but we don't send the data since it's a password, etc.  Sends 1 if it's not bland/zero, 0 otherwise as value
  FCVAR_SPONLY = 1 shl 6;  // This cvar cannot be changed by clients connected to a multiplayer server.
  FCVAR_PRINTABLEONLY = 1 shl 7;  // This cvar's string cannot contain unprintable characters ( e.g., used for player name etc ).
  FCVAR_UNLOGGED = 1 shl 8;  // If this is a FCVAR_SERVER, don't log changes to the log file / console if we are creating a log
  FCVAR_NOEXTRAWHITEPACE = 1 shl 9;  // strip trailing/leading white space from this cvar

  // director_cmds.h
  // sub commands for svc_director

  DRC_ACTIVE = 0;	// tells client that he's an spectator and will get director command
  DRC_STATUS = 1;	// send status infos about proxy
  DRC_CAMERA = 2;	// set the actual director camera position
  DRC_EVENT = 3;	// informs the dircetor about ann important game event

  // commands of the director API function CallDirectorProc(...)

  DRCAPI_NOP = 0;	// no operation
  DRCAPI_ACTIVE = 1;	// de/acivates director mode in engine
  DRCAPI_STATUS = 2;   // request proxy information
  DRCAPI_SETCAM = 3;	// set camera n to given position and angle
  DRCAPI_GETCAM = 4;	// request camera n position and angle
  DRCAPI_DIRPLAY = 5;	// set director time and play with normal speed
  DRCAPI_DIRFREEZE = 6;	// freeze directo at this time
  DRCAPI_SETVIEWMODE = 7;	// overview or 4 cameras
  DRCAPI_SETOVERVIEWPARAMS = 8;	// sets parameter for overview mode
  DRCAPI_SETFOCUS = 9;	// set the camera which has the input focus
  DRCAPI_GETTARGETS = 10;	// queries engine for player list
  DRCAPI_SETVIEWPOINTS = 11;	// gives engine all waypoints

  //DLL State Flags

  DLL_INACTIVE = 0;		// no dll
  DLL_ACTIVE = 1;		// dll is running
  DLL_PAUSED = 2;		// dll is paused
  DLL_CLOSE = 3;		// closing down dll
  DLL_TRANS = 4; 		// Level Transition

  // DLL Pause reasons

  DLL_NORMAL = 0;   // User hit Esc or something.
  DLL_QUIT = 4;   // Quit now
  DLL_RESTART = 5;   // Switch to launcher for linux, does a quit but returns 1

  // DLL Substate info ( not relevant )
  NG_NORMAL = 1 shl 0;

  // For entityType below
  ENTITY_NORMAL = 1 shl 0;
  ENTITY_BEAM = 1 shl 1;

  ET_NORMAL = 0;
  ET_PLAYER = 1;
  ET_TEMPENTITY = 2;
  ET_BEAM = 3;
  // BMODEL or SPRITE that was split across BSP nodes
  ET_FRAGMENTED	= 4;

type
  netsrc_s =
  (
    NS_CLIENT,
    NS_SERVER,
    NS_MULTICAST	// xxxMO
  );
  netsrc_t = netsrc_s;

  TNetSrc = netsrc_t;
  PNetSrc = ^TNetSrc;

const
  // Event was invoked with stated origin
  FEVENT_ORIGIN	= 1 shl 0;

  // Event was invoked with stated angles
  FEVENT_ANGLES = 1 shl 1;

  // Skip local host for event send.
  FEV_NOTHOST = 1 shl 0;

  // Send the event reliably.  You must specify the origin and angles and use
  // PLAYBACK_EVENT_FULL for this to work correctly on the server for anything
  // that depends on the event origin/angles.  I.e., the origin/angles are not
  // taken from the invoking edict for reliable events.
  FEV_RELIABLE = 1 shl 1;

  // Don't restrict to PAS/PVS, send this event to _everybody_ on the server ( useful for stopping CHAN_STATIC
  //  sounds started by client event when client is not in PVS anymore ( hwguy in TFC e.g. ).
  FEV_GLOBAL = 1 shl 2;

  // If this client already has one of these events in its queue, just update the event instead of sending it as a duplicate
  //
  FEV_UPDATE = 1 shl 3;

  // Only send to entity specified as the invoker
  FEV_HOSTONLY = 1 shl 4;

  // Only send if the event was created on the server.
  FEV_SERVER = 1 shl 5;

  // Only issue event client side ( from shared code )
  FEV_CLIENT = 1 shl 6;

  // all shared consts between server, clients and proxy
  TYPE_CLIENT = 0;	// client is a normal HL client (default)
  TYPE_PROXY = 1;	// client is another proxy
  TYPE_COMMENTATOR = 3;	// client is a commentator
  TYPE_DEMO = 4;	// client is a demo file

  // sub commands of svc_hltv:
  HLTV_ACTIVE	= 0;	// tells client that he's an spectator and will get director commands
  HLTV_STATUS	= 1;	// send status infos about proxy
  HLTV_LISTEN	= 2;	// tell client to listen to a multicast stream

  // director command types:
  DRC_CMD_NONE = 0;	// NULL director command
  DRC_CMD_START = 1;	// start director mode
  DRC_CMD_EVENT = 2;	// informs about director command
  DRC_CMD_MODE = 3;	// switches camera modes
  DRC_CMD_CAMERA = 4;	// set fixed camera
  DRC_CMD_TIMESCALE = 5;	// sets time scale
  DRC_CMD_MESSAGE = 6;	// send HUD centerprint
  DRC_CMD_SOUND = 7;	// plays a particular sound
  DRC_CMD_STATUS = 8;	// HLTV broadcast status
  DRC_CMD_BANNER = 9;	// set GUI banner
  DRC_CMD_STUFFTEXT = 10;	// like the normal svc_stufftext but as director command
  DRC_CMD_CHASE = 11;	// chase a certain player
  DRC_CMD_INEYE = 12;	// view player through own eyes
  DRC_CMD_MAP = 13;	// show overview map
  DRC_CMD_CAMPATH = 14;	// define camera waypoint
  DRC_CMD_WAYPOINTS = 15;	// start moving camera, inetranl message

  DRC_CMD_LAST = 15;


  // DRC_CMD_EVENT event flags
  DRC_FLAG_PRIO_MASK = $0F;	// priorities between 0 and 15 (15 most important)
  DRC_FLAG_SIDE = 1 shl 4;	//
  DRC_FLAG_DRAMATIC = 1 shl 5;	// is a dramatic scene
  DRC_FLAG_SLOWMOTION = 1 shl 6;  // would look good in SloMo
  DRC_FLAG_FACEPLAYER = 1 shl 7;  // player is doning something (reload/defuse bomb etc)
  DRC_FLAG_INTRO = 1 shl 8;	// is a introduction scene
  DRC_FLAG_FINAL = 1 shl 9;	// is a final scene
  DRC_FLAG_NO_RANDOM = 1 shl 10;	// don't randomize event data


  // DRC_CMD_WAYPOINT flags
  DRC_FLAG_STARTPATH = 1;	// end with speed 0.0
  DRC_FLAG_SLOWSTART = 2;	// start with speed 0.0
  DRC_FLAG_SLOWEND = 4;	// end with speed 0.0

  IN_ATTACK = 1 shl 0;
  IN_JUMP = 1 shl 1;
  IN_DUCK = 1 shl 2;
  IN_FORWARD = 1 shl 3;
  IN_BACK = 1 shl 4;
  IN_USE = 1 shl 5;
  IN_CANCEL	 = 1 shl 6;
  IN_LEFT = 1 shl 7;
  IN_RIGHT = 1 shl 8;
  IN_MOVELEFT = 1 shl 9;
  IN_MOVERIGHT = 1 shl 10;
  IN_ATTACK2 = 1 shl 11;
  IN_RUN = 1 shl 12;
  IN_RELOAD = 1 shl 13;
  IN_ALT1 = 1 shl 14;
  IN_SCORE = 1 shl 15;   // Used by client.dll for when scoreboard is held down

type
  VoiceTweakControl =
  (
    MicrophoneVolume = 0, // values 0-1.
    OtherSpeakerScale,    // values 0-1. Scales how loud other players are.
    MicBoost              // 20 db gain to voice input
  );
  TVoiceTweakControl = VoiceTweakControl;

const
  NETAPI_REQUEST_SERVERLIST = 0;  // Doesn't need a remote address
  NETAPI_REQUEST_PING = 1;
  NETAPI_REQUEST_RULES = 2;
  NETAPI_REQUEST_PLAYERS = 3;
  NETAPI_REQUEST_DETAILS = 4;

  // Set this flag for things like broadcast requests, etc. where the engine should not
  //  kill the request hook after receiving the first response
  FNETAPI_MULTIPLE_RESPONSE = 1 shl 0;

  NET_SUCCESS = 0;
  NET_ERROR_TIMEOUT = 1 shl 0;
  NET_ERROR_PROTO_UNSUPPORTED = 1 shl 1;
  NET_ERROR_UNDEFINED = 1 shl 2;

type
  netadrtype_t =
  (
    NA_UNUSED,
    NA_LOOPBACK,
    NA_BROADCAST,
    NA_IP,
    NA_IPX,
    NA_BROADCAST_IPX
  );
  TNetAdrType = netadrtype_t;

  ptype_t =
  (
    pt_static,
    pt_grav,
    pt_slowgrav,
    pt_fire,
    pt_explode,
    pt_explode2,
    pt_blob,
    pt_blob2,
    pt_vox_slowgrav,
    pt_vox_grav,
    pt_clientcustom   // Must have callback function specified
  );
  TPType = ptype_t;

const
  NUM_GLYPHS = 256;

  // DATA STRUCTURE INFO

  MAX_NUM_ARGVS = 50;

  // SYSTEM INFO
  MAX_QPATH = 64;		// max length of a game pathname
  MAX_OSPATH = 260;		// max length of a filesystem pathname

  ON_EPSILON = 0.1;		// point on plane side epsilon

  MAX_LIGHTSTYLE_INDEX_BITS = 6;
  MAX_LIGHTSTYLES = 1 shl MAX_LIGHTSTYLE_INDEX_BITS;

  // Resource counts;
  MAX_MODEL_INDEX_BITS = 9;	// sent as a short
  MAX_MODELS = 1 shl MAX_MODEL_INDEX_BITS;
  MAX_SOUND_INDEX_BITS = 9;
  MAX_SOUNDS = 1 shl MAX_SOUND_INDEX_BITS;
  MAX_SOUNDS_HASHLOOKUP_SIZE = MAX_SOUNDS * 2 - 1;

  MAX_GENERIC_INDEX_BITS = 9;
  MAX_GENERIC = 1 shl MAX_GENERIC_INDEX_BITS;
  MAX_DECAL_INDEX_BITS = 9;
  MAX_BASE_DECALS = 1 shl MAX_DECAL_INDEX_BITS;

  MAX_USER_MSG_DATA = 192;

  // Temporary entity array
  TENTPRIORITY_LOW = 0;
  TENTPRIORITY_HIGH = 1;

  // TEMPENTITY flags
  FTENT_NONE = $00000000;
  FTENT_SINEWAVE = $00000001;
  FTENT_GRAVITY = $00000002;
  FTENT_ROTATE = $00000004;
  FTENT_SLOWGRAVITY = $00000008;
  FTENT_SMOKETRAIL = $00000010;
  FTENT_COLLIDEWORLD = $00000020;
  FTENT_FLICKER = $00000040;
  FTENT_FADEOUT = $00000080;
  FTENT_SPRANIMATE = $00000100;
  FTENT_HITSOUND = $00000200;
  FTENT_SPIRAL = $00000400;
  FTENT_SPRCYCLE = $00000800;
  FTENT_COLLIDEALL = $00001000; // will collide with world and slideboxes
  FTENT_PERSIST = $00002000; // tent is not removed when unable to draw
  FTENT_COLLIDEKILL = $00004000; // tent is removed upon collision with anything
  FTENT_PLYRATTACHMENT = $00008000; // tent is attached to a player (owner)
  FTENT_SPRANIMATELOOP = $00010000; // animating sprite doesn't die when last frame is displayed
  FTENT_SPARKSHOWER = $00020000;
  FTENT_NOMODEL = $00040000; // Doesn't have a model, never try to draw ( it just triggers other things )
  FTENT_CLIENTCUSTOM = $00080000; // Must specify callback.  Callback function is responsible for killing tempent and updating fields ( unless other flags specify how to do things )

type
  //--------------------------------------------------------------------------
  // sequenceDefaultBits_e
  //
  // Enumerated list of possible modifiers for a command.  This enumeration
  // is used in a bitarray controlling what modifiers are specified for a command.
  //---------------------------------------------------------------------------
  sequenceModifierBits =
  (
    SEQUENCE_MODIFIER_EFFECT_BIT = 1 shl 1,
    SEQUENCE_MODIFIER_POSITION_BIT = 1 shl 2,
    SEQUENCE_MODIFIER_COLOR_BIT = 1 shl 3,
    SEQUENCE_MODIFIER_COLOR2_BIT = 1 shl 4,
    SEQUENCE_MODIFIER_FADEIN_BIT = 1 shl 5,
    SEQUENCE_MODIFIER_FADEOUT_BIT = 1 shl 6,
    SEQUENCE_MODIFIER_HOLDTIME_BIT = 1 shl 7,
    SEQUENCE_MODIFIER_FXTIME_BIT = 1 shl 8,
    SEQUENCE_MODIFIER_SPEAKER_BIT = 1 shl 9,
    SEQUENCE_MODIFIER_LISTENER_BIT = 1 shl 10,
    SEQUENCE_MODIFIER_TEXTCHANNEL_BIT	= 1 shl 11
  );
  sequenceModifierBits_e = sequenceModifierBits;
  TSequenceModifierBits = sequenceModifierBits;

  //---------------------------------------------------------------------------
  // sequenceCommandEnum_e
  //
  // Enumerated sequence command types.
  //---------------------------------------------------------------------------
  sequenceCommandEnum_ =
  (
    SEQUENCE_COMMAND_ERROR = -1,
    SEQUENCE_COMMAND_PAUSE = 0,
    SEQUENCE_COMMAND_FIRETARGETS,
    SEQUENCE_COMMAND_KILLTARGETS,
    SEQUENCE_COMMAND_TEXT,
    SEQUENCE_COMMAND_SOUND,
    SEQUENCE_COMMAND_GOSUB,
    SEQUENCE_COMMAND_SENTENCE,
    SEQUENCE_COMMAND_REPEAT,
    SEQUENCE_COMMAND_SETDEFAULTS,
    SEQUENCE_COMMAND_MODIFIER,
    SEQUENCE_COMMAND_POSTMODIFIER,
    SEQUENCE_COMMAND_NOOP,

    SEQUENCE_MODIFIER_EFFECT,
    SEQUENCE_MODIFIER_POSITION,
    SEQUENCE_MODIFIER_COLOR,
    SEQUENCE_MODIFIER_COLOR2,
    SEQUENCE_MODIFIER_FADEIN,
    SEQUENCE_MODIFIER_FADEOUT,
    SEQUENCE_MODIFIER_HOLDTIME,
    SEQUENCE_MODIFIER_FXTIME,
    SEQUENCE_MODIFIER_SPEAKER,
    SEQUENCE_MODIFIER_LISTENER,
    SEQUENCE_MODIFIER_TEXTCHANNEL
  );
  sequenceCommandEnum_e = sequenceCommandEnum_;
  TSequenceCommandEnum = sequenceCommandEnum_e;

  //---------------------------------------------------------------------------
  // sequenceCommandType_e
  //
  // Typeerated sequence command types.
  //---------------------------------------------------------------------------
  sequenceCommandType_ =
  (
    SEQUENCE_TYPE_COMMAND,
    SEQUENCE_TYPE_MODIFIER
  );
  sequenceCommandType_e = sequenceCommandType_;
  TSequenceCommandType = sequenceCommandType_e;

  TRICULLSTYLE =
  (
    TRI_FRONT = 0,
    TRI_NONE = 1
  );
  TTriCullStyle = TRICULLSTYLE;

const
  TRI_TRIANGLES = 0;
  TRI_TRIANGLE_FAN = 1;
  TRI_QUADS = 2;
  TRI_POLYGON = 3;
  TRI_LINES = 4;
  TRI_TRIANGLE_STRIP = 5;
  TRI_QUAD_STRIP = 6;

  // header
  Q1BSP_VERSION = 29;		// quake1 regular version (beta is 28)
  HLBSP_VERSION = 30;		// half-life regular version

  MAX_MAP_HULLS = 4;

  CONTENTS_ORIGIN = -7;		// removed at csg time
  CONTENTS_CLIP = -8;		// changed to contents_solid
  CONTENTS_CURRENT_0 = -9;
  CONTENTS_CURRENT_90 = -10;
  CONTENTS_CURRENT_180 = -11;
  CONTENTS_CURRENT_270 = -12;
  CONTENTS_CURRENT_UP = -13;
  CONTENTS_CURRENT_DOWN = -14;

  CONTENTS_TRANSLUCENT = -15;

  LUMP_ENTITIES = 0;
  LUMP_PLANES = 1;
  LUMP_TEXTURES = 2;
  LUMP_VERTEXES = 3;
  LUMP_VISIBILITY = 4;
  LUMP_NODES = 5;
  LUMP_TEXINFO = 6;
  LUMP_FACES = 7;
  LUMP_LIGHTING = 8;
  LUMP_CLIPNODES = 9;
  LUMP_LEAFS = 10;
  LUMP_MARKSURFACES = 11;
  LUMP_EDGES = 12;
  LUMP_SURFEDGES = 13;
  LUMP_MODELS = 14;

  HEADER_LUMPS = 15;

  FCMD_HUD_COMMAND = 1 shl 0;
  FCMD_GAME_COMMAND	= 1 shl 1;
  FCMD_WRAPPER_COMMAND = 1 shl 2;

  COM_TOKEN_LEN = 1024;

  // Don't allow overflow
  SIZEBUF_CHECK_OVERFLOW = 0;
  SIZEBUF_ALLOW_OVERFLOW  = 1 shl 0;
  SIZEBUF_OVERFLOWED = 1 shl 1;

  NUM_SAFE_ARGVS = 7;

  COM_COPY_CHUNK_SIZE = 1024;
  COM_MAX_CMD_LINE = 256;

  MAX_RESOURCE_LIST	= 1280;

type
  /////////////////
  // Customization
  // passed to pfnPlayerCustomization
  // For automatic downloading.
  resourcetype_t =
  (
    t_sound = 0,
    t_skin,
    t_model,
    t_decal,
    t_generic,
    t_eventscript,
    t_world,		// Fake type for world, is really t_model
    rt_unk,

    rt_max
  );
  TResourceType = resourcetype_t;

const
  RES_FATALIFMISSING = 1 shl 0; // Disconnect if we can't get this file.
  RES_WASMISSING = 1 shl 1; // Do we have the file locally, did we get it ok?
  RES_CUSTOM = 1 shl 2; // Is this resource one that corresponds to another player's customization
                        // or is it a server startup resource.
  RES_REQUESTED = 1 shl 3; // Already requested a download of this one
  RES_PRECACHED = 1 shl 4; // Already precached
  RES_ALWAYS = 1 shl 5;	// download always even if available on client
  RES_UNK_6 = 1 shl 6; // TODO: what is it?
  RES_CHECKFILE = 1 shl 7;// check file on client


  FCUST_FROMHPAK = 1 shl 0;
  FCUST_WIPEDATA = 1 shl 1;
  FCUST_IGNOREINIT = 1 shl 2;

  // Beam types, encoded as a byte
  BEAM_POINTS = 0;
  BEAM_ENTPOINT = 1;
  BEAM_ENTS = 2;
  BEAM_HOSE = 3;

  BEAM_FSINE = $10;
  BEAM_FSOLID = $20;
  BEAM_FSHADEIN = $40;
  BEAM_FSHADEOUT = $80;

  MAX_ENT_LEAFS = 48;

type
  ALERT_TYPE =
  (
    at_notice,
    at_console,		// same as at_notice, but forces a ConPrintf, not a message box
    at_aiconsole,	// same as at_console, but only shown if developer level is 2!
    at_warning,
    at_error,
    at_logged		// Server print to console ( only in multiplayer games ).
  );
  TAlertType = ALERT_TYPE;

  // 4-22-98  JOHN: added for use in pfnClientPrintf
  PRINT_TYPE =
  (
    print_console,
    print_center,
    print_chat
  );
  TPrintType = PRINT_TYPE;

  // For integrity checking of content on clients
  FORCE_TYPE =
  (
    force_exactfile,					// File on client must exactly match server's file
    force_model_samebounds,				// For model files only, the geometry must fit in the same bbox
    force_model_specifybounds,			// For model files only, the geometry must fit in the specified bbox
    force_model_specifybounds_if_avail	// For Steam model files only, the geometry must fit in the specified bbox (if the file is available)
  );
  TForceType = FORCE_TYPE;

const
  //
  // these are the key numbers that should be passed to Key_Event
  //
  K_TAB = 9;
  K_ENTER = 13;
  K_ESCAPE = 27;
  K_SPACE = 32;

  // normal keys should be passed as lowercased ascii

  K_BACKSPACE = 127;
  K_UPARROW = 128;
  K_DOWNARROW = 129;
  K_LEFTARROW = 130;
  K_RIGHTARROW = 131;

  K_ALT = 132;
  K_CTRL = 133;
  K_SHIFT = 134;
  K_F1 = 135;
  K_F2 = 136;
  K_F3 = 137;
  K_F4 = 138;
  K_F5 = 139;
  K_F6 = 140;
  K_F7 = 141;
  K_F8 = 142;
  K_F9 = 143;
  K_F10 = 144;
  K_F11 = 145;
  K_F12 = 146;
  K_INS = 147;
  K_DEL = 148;
  K_PGDN = 149;
  K_PGUP = 150;
  K_HOME = 151;
  K_END = 152;

  K_KP_HOME = 160;
  K_KP_UPARROW = 161;
  K_KP_PGUP = 162;
  K_KP_LEFTARROW = 163;
  K_KP_5 = 164;
  K_KP_RIGHTARROW = 165;
  K_KP_END = 166;
  K_KP_DOWNARROW = 167;
  K_KP_PGDN = 168;
  K_KP_ENTER = 169;
  K_KP_INS = 170;
  K_KP_DEL = 171;
  K_KP_SLASH = 172;
  K_KP_MINUS = 173;
  K_KP_PLUS = 174;
  K_CAPSLOCK = 175;


  //
  // joystick buttons
  //
  K_JOY1 = 203;
  K_JOY2 = 204;
  K_JOY3 = 205;
  K_JOY4 = 206;

  //
  // aux keys are for multi-buttoned joysticks to generate so they can use
  // the normal binding process
  //
  K_AUX1 = 207;
  K_AUX2 = 208;
  K_AUX3 = 209;
  K_AUX4 = 210;
  K_AUX5 = 211;
  K_AUX6 = 212;
  K_AUX7 = 213;
  K_AUX8 = 214;
  K_AUX9 = 215;
  K_AUX10 = 216;
  K_AUX11 = 217;
  K_AUX12 = 218;
  K_AUX13 = 219;
  K_AUX14 = 220;
  K_AUX15 = 221;
  K_AUX16 = 222;
  K_AUX17 = 223;
  K_AUX18 = 224;
  K_AUX19 = 225;
  K_AUX20 = 226;
  K_AUX21 = 227;
  K_AUX22 = 228;
  K_AUX23 = 229;
  K_AUX24 = 230;
  K_AUX25 = 231;
  K_AUX26 = 232;
  K_AUX27 = 233;
  K_AUX28 = 234;
  K_AUX29 = 235;
  K_AUX30 = 236;
  K_AUX31 = 237;
  K_AUX32 = 238;
  K_MWHEELDOWN = 239;
  K_MWHEELUP = 240;

  K_PAUSE = 255;

  //
  // mouse buttons generate virtual keys
  //
 	K_MOUSE1 = 241;
 	K_MOUSE2 = 242;
 	K_MOUSE3 = 243;
  K_MOUSE4 = 244;
  K_MOUSE5 = 245;

  // header
  ALIAS_MODEL_VERSION	= $006;
  IDPOLYHEADER = Ord('I') shl 24 or Ord('D') shl 16 or Ord('P') shl 8 or Ord('O'); // little-endian "IDPO"

  MAX_LBM_HEIGHT = 480;
  MAX_ALIAS_MODEL_VERTS = 2000;

  SURF_PLANEBACK = 2;
  SURF_DRAWSKY = 4;
  SURF_DRAWSPRITE = 8;
  SURF_DRAWTURB = $10;
  SURF_DRAWTILED = $20;
  SURF_DRAWBACKGROUND = $40;

  MAX_MODEL_NAME = 64;
  MIPLEVELS = 4;
  NUM_AMBIENTS = 4;		// automatic ambient sounds
  MAXLIGHTMAPS = 4;
  MAX_KNOWN_MODELS = 1024;

  TEX_SPECIAL = 1; // sky or slime, no lightmap or 256 subdivision

type
  modtype_e =
  (
    mod_brush = 0,
    mod_sprite,
    mod_alias,
    mod_studio
  );
  modtype_t = modtype_e;
  TModType = modtype_t;

  synctype_e =
  (
    ST_SYNC = 0,
    ST_RAND = 1
  );
  synctype_t = synctype_e;
  TSyncType = synctype_t;

  aliasframetype_s =
  (
    ALIAS_SINGLE = 0,
    ALIAS_GROUP = 1
  );
  aliasframetype_t = aliasframetype_s;
  TAliasFrameType = aliasframetype_t;

const
  // 16 simultaneous events, max
  MAX_EVENT_QUEUE = 64;

  DEFAULT_EVENT_RESENDS = 1;

  FFADE_IN = $0000;		// Just here so we don't pass 0 into the function
  FFADE_OUT = $0001;		// Fade out (not in)
  FFADE_MODULATE = $0002;		// Modulate (don't blend)
  FFADE_STAYOUT = $0004;		// ignores the duration, stays faded out until new ScreenFade message received
  FFADE_LONGFADE = $0008;		// used to indicate the fade can be longer than 16 seconds (added for czero)

  SPRITE_VERSION = 2; // Half-Life sprites
  IDSPRITEHEADER = Ord('I') shl 24 or Ord('D') shl 16 or Ord('S') shl 8 or Ord('P');	// little-endian "IDSP"

type
  spriteframetype_e =
  (
    SPR_SINGLE = 0,
    SPR_GROUP,
    SPR_ANGLED
  );
  spriteframetype_t = spriteframetype_e;
  TSpriteFrameType = spriteframetype_t;

const
  MAXSTUDIOTRIANGLES = 20000;	// TODO: tune this
  MAXSTUDIOVERTS = 2048;	// TODO: tune this
  MAXSTUDIOSEQUENCES = 2048;	// total animation sequences
  MAXSTUDIOSKINS = 100;		// total textures
  MAXSTUDIOSRCBONES = 512;		// bones allowed at source movement
  MAXSTUDIOBONES = 128;		// total bones actually used
  MAXSTUDIOMODELS = 32;		// sub-models per model
  MAXSTUDIOBODYPARTS = 32;
  MAXSTUDIOGROUPS = 16;
  MAXSTUDIOANIMATIONS = 2048;	// per sequence
  MAXSTUDIOMESHES = 256;
  MAXSTUDIOEVENTS = 1024;
  MAXSTUDIOPIVOTS = 256;
  MAXSTUDIOCONTROLLERS = 8;

  STUDIO_DYNAMIC_LIGHT = $0100;	// dynamically get lighting from floor or ceil (flying monsters)
  STUDIO_TRACE_HITBOX = $0200;	// always use hitbox trace instead of bbox

  // lighting options
  STUDIO_NF_FLATSHADE = $0001;
  STUDIO_NF_CHROME = $0002;
  STUDIO_NF_FULLBRIGHT = $0004;
  STUDIO_NF_NOMIPS = $0008;
  STUDIO_NF_ALPHA = $0010;
  STUDIO_NF_ADDITIVE = $0020;
  STUDIO_NF_MASKED = $0040;

  // motion flags
  STUDIO_X = $0001;
  STUDIO_Y = $0002;
  STUDIO_Z = $0004;
  STUDIO_XR = $0008;
  STUDIO_YR = $0010;
  STUDIO_ZR = $0020;
  STUDIO_LX = $0040;
  STUDIO_LY = $0080;
  STUDIO_LZ = $0100;
  STUDIO_AX = $0200;
  STUDIO_AY = $0400;
  STUDIO_AZ = $0800;
  STUDIO_AXR = $1000;
  STUDIO_AYR = $2000;
  STUDIO_AZR = $4000;
  STUDIO_TYPES = $7FFF;
  STUDIO_RLOOP = $8000;	// controller that wraps shortest distance

  // sequence flags
  STUDIO_LOOPING = $0001;

  // bone flags
  STUDIO_HAS_NORMALS = $0001;
  STUDIO_HAS_VERTICES = $0002;
  STUDIO_HAS_BBOX = $0004;
  STUDIO_HAS_CHROME = $0008;	// if any of the textures have chrome on them

  RAD_TO_STUDIO = 32768.0 / Pi;
  STUDIO_TO_RAD = Pi / 32768.0;

  STUDIO_NUM_HULLS = 128;
  STUDIO_NUM_PLANES = STUDIO_NUM_HULLS * 6;
  STUDIO_CACHE_SIZE = 16;

type
  // Authentication types
  AUTH_IDTYPE =
  (
    AUTH_IDTYPE_UNKNOWN	= 0,
    AUTH_IDTYPE_STEAM	= 1,
    AUTH_IDTYPE_VALVE	= 2,
    AUTH_IDTYPE_LOCAL	= 3
  );
  TAuthIDType = AUTH_IDTYPE;

const
  VOICE_MAX_PLAYERS = MAX_CLIENTS;
  VOICE_MAX_PLAYERS_DW = (VOICE_MAX_PLAYERS div MAX_CLIENTS) + not not (VOICE_MAX_PLAYERS and $1F);

  MAX_PHYSENTS = 600; 		  		// Must have room for all entities in the world.
  MAX_MOVEENTS = 64;
  MAX_CLIP_PLANES = 5;

  PM_NORMAL = $00000000;
  PM_STUDIO_IGNORE = $00000001;	// Skip studio models
  PM_STUDIO_BOX	= $00000002;	// Use boxes for non-complex studio models (even in traceline)
  PM_GLASS_IGNORE = $00000004;	// Ignore entities with non-normal rendermode
  PM_WORLD_ONLY = $00000008;	// Only trace against the world

  PM_TRACELINE_PHYSENTSONLY = 0;
  PM_TRACELINE_ANYVISIBLE = 1;

  MAX_PHYSINFO_STRING = 256;

  CTEXTURESMAX = 1024;	// max number of textures loaded
  CBTEXTURENAMEMAX = 17;	// only load first n chars of name

  CHAR_TEX_CONCRETE = 'C';	// texture types
  CHAR_TEX_METAL = 'M';
  CHAR_TEX_DIRT = 'D';
  CHAR_TEX_VENT = 'V';
  CHAR_TEX_GRATE = 'G';
  CHAR_TEX_TILE = 'T';
  CHAR_TEX_SLOSH = 'S';
  CHAR_TEX_WOOD = 'W';
  CHAR_TEX_COMPUTER = 'P';
  CHAR_TEX_GRASS = 'X';
  CHAR_TEX_GLASS = 'Y';
  CHAR_TEX_FLESH = 'F';
  CHAR_TEX_SNOW = 'N';

  PM_DEAD_VIEWHEIGHT = -8;

  OBS_NONE = 0;
  OBS_CHASE_LOCKED = 1;
  OBS_CHASE_FREE = 2;
  OBS_ROAMING = 3;
  OBS_IN_EYE = 4;
  OBS_MAP_FREE = 5;
  OBS_MAP_CHASE = 6;

  STEP_CONCRETE = 0;
  STEP_METAL = 1;
  STEP_DIRT = 2;
  STEP_VENT = 3;
  STEP_GRATE = 4;
  STEP_TILE = 5;
  STEP_SLOSH = 6;
  STEP_WADE = 7;
  STEP_LADDER = 8;
  STEP_SNOW = 9;

  WJ_HEIGHT = 8;
  STOP_EPSILON = 0.1;
  MAX_CLIMB_SPEED = 200;
  PLAYER_DUCKING_MULTIPLIER = 0.333;
  PM_CHECKSTUCK_MINTIME = 0.05;	// Don't check again too quickly.

  PLAYER_LONGJUMP_SPEED: Single = 350.0;	// how fast we longjump

  // Ducking time
  TIME_TO_DUCK  = 0.4;
  STUCK_MOVEUP = 1;

  PM_VEC_DUCK_HULL_MIN = -18;
  PM_VEC_HULL_MIN = -36;
  PM_VEC_DUCK_VIEW = 12;
  PM_VEC_VIEW = 17;

  PM_PLAYER_MAX_SAFE_FALL_SPEED = 580;	// approx 20 feet
  PM_PLAYER_MIN_BOUNCE_SPEED = 350;
  PM_PLAYER_FALL_PUNCH_THRESHHOLD = 250;	// won't punch player's screen/make scrape noise unless player falling at least this fast.

  // Only allow bunny jumping up to 1.2x server / player maxspeed setting
  BUNNYJUMP_MAX_SPEED_FACTOR: Single = 1.2;

  MAX_CONSISTENCY_LIST = 512;

  MAX_EVENTS = 256;
  MAX_PACKET_ENTITIES = 256;

  NUM_BASELINES = 64;

  PROTOCOL_VERSION = 48;

  MAX_CHALLENGES = 1024;

  // Client connection is initiated by requesting a challenge value
  //  the server sends this value back
  S2C_CHALLENGE: AnsiChar = 'A'; // + challenge value

  // Send a userid, client remote address, is this server secure and engine build number
  S2C_CONNECTION: AnsiChar = 'B';

  // HLMaster rejected a server's connection because the server needs to be updated
  M2S_REQUESTRESTART: AnsiChar = 'O';

  // Response details about each player on the server
  S2A_PLAYERS: AnsiChar = 'D';

  // Number of rules + string key and string value pairs
  S2A_RULES: AnsiChar = 'E';

  // info request
  S2A_INFO: AnsiChar = 'C'; // deprecated goldsrc response

  S2A_INFO_DETAILED: AnsiChar = 'm'; // New Query protocol, returns dedicated or not, + other performance info.

  // send a log event as key value
  S2A_LOGSTRING: AnsiChar = 'R';

  // Send a log string
  S2A_LOGKEY: AnsiChar = 'S';

  // Basic information about the server
  A2S_INFO: AnsiChar = 'T';

  // Details about each player on the server
  A2S_PLAYER = 'U';

  // The rules the server is using
  A2S_RULES = 'V';

  // Another user is requesting a challenge value from this machine
  A2A_GETCHALLENGE = 'W'; // Request challenge # from another machine

  // Generic Ping Request
  A2A_PING = 'i';	// respond with an A2A_ACK

  // Generic Ack
  A2A_ACK = 'j';	// general acknowledgement without info

  // Print to client console
  A2A_PRINT = 'l'; // print a message on client

  // Challenge response from master
  M2A_CHALLENGE = 's';	// + challenge value

  // 0 == regular, 1 == file stream
  FRAG_NORMAL_STREAM = 0;
  FRAG_FILE_STREAM = 1;
  MAX_STREAMS = 2;

  // Flow control bytes per second limits
  MAX_RATE = 100000.0;
  MIN_RATE = 1000.0;

  // Default data rate
  DEFAULT_RATE = 30000.0;

  // Max size of udp packet payload
  MAX_UDP_PACKET = 4010;

  // Max length of a reliable message
  MAX_MSGLEN = 3990;

  // Max length of unreliable message
  MAX_DATAGRAM = 4000;

  // This is the packet payload without any header bytes (which are attached for actual sending)
  NET_MAX_PAYLOAD	= 65536;

  // Packet header is:
  //  4 bytes of outgoing seq
  //  4 bytes of incoming seq
  //  and for each stream
  // {
  //  byte (on/off)
  //  int (fragment id)
  //  short (startpos)
  //  short (length)
  // }
  HEADER_BYTES = 8 + MAX_STREAMS * 9;

  NET_MAX_MESSAGE = 4037;

  FILESYSTEM_INVALID_FIND_HANDLE = -1;

  MAX_LEVEL_CONNECTIONS = 16; // These are encoded in the lower 16bits of ENTITYTABLE->flags

  FRAGMENT_MAX_SIZE = 1400;

  (***************************************************************************************************)
  (***************************************************************************************************)
  (***************************************************************************************************)
  (***************************************************************************************************)

type
  FileHandle_t = Pointer;
  TFileHandle = FileHandle_t;

  vec_t = Single;
  TVec = vec_t;
  PVec = ^TVec;

  vec3_t = array[0..2] of TVec;
  TVec3 = vec3_t;
  PVec3 = ^vec3_t;

  Vector = vec3_t;
  {$IF SizeOf(TVec3) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TVec3.'} {$DEFINE MSME} {$IFEND}

  vec4_t = array[0..3] of TVec;

  string_t = Cardinal;
  TString = string_t;

  BOOL = Integer;

  //qboolean = (_false = 0, _true = 1);
  qboolean = System.LongBool;
  TQBoolean = qboolean;
  {$IF SizeOf(TQBoolean) <> 4} {$MESSAGE WARN 'Type size mismatch @ TQBoolean.'} {$DEFINE MSME} {$IFEND}

  color24 = packed record
    R, G, B: Byte;
  end;
  TColor24 = color24;
  PColor24 = ^TColor24;
  {$IF SizeOf(TColor24) <> 3} {$MESSAGE WARN 'Structure size mismatch @ TColor24.'} {$DEFINE MSME} {$IFEND}

  colorVec = record
    R, G, B, A: Cardinal;
  end;
  TColorVec = colorVec;
  PColorVec = ^TColorVec;
  {$IF SizeOf(TColorVec) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TColorVec.'} {$DEFINE MSME} {$IFEND}

  link_s = record
    prev, next: ^link_s;
  end;
  link_t = link_s;

  TLink = link_t;
  PLink = ^TLink;
  {$IF SizeOf(TLink) <> 8} {$MESSAGE WARN 'Structure size mismatch @ TLink.'} {$DEFINE MSME} {$IFEND}

  PEdict = ^TEdict;

  entvars_s = record
    classname: TString;
    globalname: TString;
    origin: TVec3;
    oldorigin: TVec3;
    velocity: TVec3;
    basevelocity: TVec3;
    clbasevelocity: TVec3; // Base velocity that was passed in to server physics so
                           //  client can predict conveyors correctly.  Server zeroes it, so we need to store here, too.
    movedir: TVec3;

    angles: TVec3;         // Model angles
    avelocity: TVec3;      // angle velocity (degrees per second)
    punchangle: TVec3;     // auto-decaying view angle adjustment
    v_angle: TVec3;        // Viewing angle (player only)

    // For parametric entities
    endpos: TVec3;
    startpos: TVec3;
    impacttime: Single;
    starttime: Single;

    fixangle: Integer;     // 0:nothing, 1:force view angles, 2:add avelocity
    idealpitch: Single;
    pitch_speed: Single;
    ideal_yaw: Single;
    yaw_speed: Single;
    modelindex: Integer;
    model: TString;
    viewmodel: Integer;    // player's viewmodel
    weaponmodel: Integer;  // what other players see

    absmin: TVec3;         // BB max translated to world coord
    absmax: TVec3;         // BB max translated to world coord
    mins: TVec3;           // local BB min
    maxs: TVec3;           // local BB max
    size: TVec3;           // maxs - mins

    ltime: Single;
    nextthink: Single;

    movetype: Integer;
    solid: Integer;

    skin: Integer;
    body: Integer;         // sub-model selection for studiomodels
    effects: Integer;

    gravity: Single;       // % of "normal" gravity
    friction: Single;      // inverse elasticity of MOVETYPE_BOUNCE

    light_level: Integer;

    sequence: Integer;     // animation sequence
    gaitsequence: Integer; // movement animation sequence for player (0 for none)
    frame: Integer;        // % playback position in animation sequences (0..255)
    animtime: Single;      // world time when frame was set
    framerate: Single;     // animation playback rate (-8x to 8x)
    controller: array[0..3] of Byte;  // bone controller setting (0..255)
    blending: array[0..1] of Byte;    // blending amount between sub-sequences (0..255)

    scale: Single;         // sprite rendering scale (0..255)

    rendermode: Integer;
    renderamt: Single;
    rendercolor: TVec3;
    renderfx: Integer;

    health: Single;
    frags: Single;
    weapons: Integer;      // bit mask for available weapons
    takedamage: Single;

    deadflag: Integer;
    view_ofs: TVec3;       // eye position

    button: Integer;
    impulse: Integer;

    chain: PEdict;         // Entity pointer when linked into a linked list
    dmg_inflictor: PEdict;
    enemy: PEdict;
    aiment: PEdict;        // entity pointer when MOVETYPE_FOLLOW
    owner: PEdict;
    groundentity: PEdict;

    spawnflags: Integer;
    flags: Integer;

    colormap: Integer;     // lowbyte topcolor, highbyte bottomcolor
    team: Integer;

    max_health: Single;
    teleport_time: Single;
    armortype: Single;
    armorvalue: Single;
    waterlevel: Integer;
    watertype: Integer;

    target: TString;
    targetname: TString;
    netname: TString;
    &message: TString;

    dmg_take: Single;
    dmg_save: Single;
    dmg: Single;
    dmgtime: Single;

    noise: TString;
    noise1: TString;
    noise2: TString;
    noise3: TString;

    speed: Single;
    air_finished: Single;
    pain_finished: Single;
    radsuit_finished: Single;

    pContainingEntity: PEdict;

    playerclass: Integer;
    maxspeed: Single;

    fov: Single;
    weaponanim: Integer;

    pushmsec: Integer;

    bInDuck: Integer;
    flTimeStepSound: Integer;
    flSwimTime: Integer;
    flDuckTime: Integer;
    iStepLeft: Integer;
    flFallVelocity: Single;

    gamestate: Integer;

    oldbuttons: Integer;

    groupinfo: Integer;

    // For mods
    iuser1: Integer;
    iuser2: Integer;
    iuser3: Integer;
    iuser4: Integer;
    fuser1: Single;
    fuser2: Single;
    fuser3: Single;
    fuser4: Single;
    vuser1: TVec3;
    vuser2: TVec3;
    vuser3: TVec3;
    vuser4: TVec3;
    euser1: PEdict;
    euser2: PEdict;
    euser3: PEdict;
    euser4: PEdict;
  end;
  entvars_t = entvars_s;

  PEntVars = ^TEntVars;
  TEntVars = entvars_t;
  {$IF SizeOf(TEntVars) <> 676} {$MESSAGE WARN 'Structure size mismatch @ TEntVars.'} {$DEFINE MSME} {$IFEND}

  edict_s = record
    free: qboolean;
    serialnumber: Integer;
    area: link_t;           // linked to a division node or leaf

    headnode: Integer;      // -1 to use normal leaf check
    num_leafs: Integer;
    leafnums: array[0..MAX_ENT_LEAFS - 1] of Word;

    freetime: Single;       // sv.time when the object was freed

    pvPrivateData: Pointer; // Alloced and freed by engine, used by DLLs

    v: entvars_t;           // C exported fields from progs

    // other fields from progs come immediately after
  end;
  edict_t = edict_s;

  TEdict = edict_t;
  {$IF SizeOf(TEdict) <> 804} {$MESSAGE WARN 'Structure size mismatch @ TEdict.'} {$DEFINE MSME} {$IFEND}

  sizebuf_s = record
    buffername: PAnsiChar;
    flags: Word;
    data: PByte;
    maxsize: Integer;
    cursize: Integer;
  end;
  sizebuf_t = sizebuf_s;

  TSizeBuf = sizebuf_s;
  PSizeBuf = ^TSizeBuf;
  {$IF SizeOf(TSizeBuf) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TSizeBuf.'} {$DEFINE MSME} {$IFEND}

  downloadtime_s = record
    bUsed: qboolean;
    fTime: Single;
    nBytesRemaining: Integer;
  end;
  TDownloadTime = downloadtime_s;
  PDownloadTime = ^TDownloadTime;
  {$IF SizeOf(TDownloadTime) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TDownloadTime.'} {$DEFINE MSME} {$IFEND}

  incomingtransfer_s = record
    doneregistering: qboolean;
    percent: Integer;
    downloadrequested: qboolean;
    rgStats: array[0..7] of downloadtime_s;
    nCurStat: Integer;
    nTotalSize: Integer;
    nTotalToTransfer: Integer;
    nRemainingToTransfer: Integer;
    fLastStatusUpdate: Single;
    custom: qboolean;
  end;
  incomingtransfer_t = incomingtransfer_s;

  TIncomingTransfer = incomingtransfer_s;
  PIncomingTransfer = ^TIncomingTransfer;
  {$IF SizeOf(TIncomingTransfer) <> 132} {$MESSAGE WARN 'Structure size mismatch @ TIncomingTransfer.'} {$DEFINE MSME} {$IFEND}

  wrect_t = record
	  left: Integer;
	  right: Integer;
	  top: Integer;
	  bottom: Integer;
  end;
  rect_s = wrect_t;

  TWRect = wrect_t;
  PWRect = ^TWRect;

  TRect = rect_s;
  PRect = ^rect_s;
  {$IF SizeOf(TRect) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TRect.'} {$DEFINE MSME} {$IFEND}

  cvar_s = record
	  name: PAnsiChar;
	  &string: PAnsiChar;
    flags: Integer;
    value: Single;
    next: ^cvar_s;
  end;
  cvar_t = cvar_s;

  TCVar = cvar_t;
  PCVar = ^TCVar;
  {$IF SizeOf(TCVar) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TCVar.'} {$DEFINE MSME} {$IFEND}

  xcommand_t = procedure; cdecl;
  TXCommand = xcommand_t;

  cmd_function_s = record
    next: ^cmd_function_s;
    name: PAnsiChar;
    &function: xcommand_t;
    flags: Integer;
  end;
  cmd_function_t = cmd_function_s;

  TCmdFunction = cmd_function_t;
  PCmdFunction = ^TCmdFunction;
  {$IF SizeOf(TCmdFunction) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TCmdFunction.'} {$DEFINE MSME} {$IFEND}

  cmd_source_t = (src_client = 0, src_command = 1);
  TCmdSource = cmd_source_t;
  {$IF SizeOf(TCmdSource) <> 4} {$MESSAGE WARN 'Type size mismatch @ TCmdSource.'} {$DEFINE MSME} {$IFEND}

  pfnUserMsgHook = function(pszName: PAnsiChar; iSize: Integer; pbuf: PByte): Integer; cdecl;
  TUserMsgHook = pfnUserMsgHook;

  CRC32_t = LongWord;
  TCRC32 = CRC32_t;
  {$IF SizeOf(CRC32_t) <> 4} {$MESSAGE WARN 'Type size mismatch @ CRC32_t.'} {$DEFINE MSME} {$IFEND}

  weapon_data_s = record
    m_iId: Integer;
    m_iClip: Integer;
    m_flNextPrimaryAttack: Single;
    m_flNextSecondaryAttack: Single;
    m_flTimeWeaponIdle: Single;
    m_fInReload: Integer;
    m_fInSpecialReload: Integer;
    m_flNextReload: Integer;
    m_flPumpTime: Single;
    m_fReloadTime: Single;
    m_fAimedDamage: Single;
    m_fNextAimBonus: Single;
    m_fInZoom: Integer;
    m_iWeaponState: Integer;
    iuser1: Integer;
    iuser2: Integer;
    iuser3: Integer;
    iuser4: Integer;
    fuser1: Single;
    fuser2: Single;
    fuser3: Single;
    fuser4: Single;
  end;
  weapon_data_t = weapon_data_s;

  TWeaponData = weapon_data_t;
  PWeaponData = ^TWeaponData;
  {$IF SizeOf(TWeaponData) <> 88} {$MESSAGE WARN 'Structure size mismatch @ TWeaponData.'} {$DEFINE MSME} {$IFEND}

  netadr_s = record
    &Type: netadrtype_t;
    ip: array[0..3] of Byte;
    ipx: array[0..9] of Byte;
    port: Word;
  end;
  netadr_t = netadr_s;

  TNetAdr = netadr_t;
  PNetAdr = ^TNetAdr;
  {$IF SizeOf(TNetAdr) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TNetAdr.'} {$DEFINE MSME} {$IFEND}

  event_s = record
    index: Word;
    filename: PAnsiChar;
    filesize: Integer;
    pszScript: PAnsiChar;
  end;
  event_t = event_s;

  TEvent = event_s;
  PEvent = ^TEvent;
  {$IF SizeOf(TEvent) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TEvent.'} {$DEFINE MSME} {$IFEND}

  usercmd_s = record
    lerp_msec: Word;
    msec: Byte;
    viewangles: TVec3;
    forwardmove: Single;
    sidemove: Single;
    upmove: Single;
    lightlevel: Byte;
    buttons: Word;
    impulse: Byte;
    weaponselect: Byte;
    impact_index: Integer;
    impact_position: TVec3;
  end;
  usercmd_t = usercmd_s;

  TUserCmd = usercmd_t;
  PUserCmd = ^TUserCmd;
  {$IF SizeOf(TUserCmd) <> 52} {$MESSAGE WARN 'Structure size mismatch @ TUserCmd.'} {$DEFINE MSME} {$IFEND}

  entity_state_s = record
    entityType: Integer;
    number: Integer;
    msg_time: Single;
    messagenum: Integer;
    origin: TVec3;
    angles: TVec3;
    modelindex: Integer;
    sequence: Integer;
    frame: Single;
    colormap: Integer;
    skin: Word;
    solid: Word;
    effects: Integer;
    scale: Single;
    eflags: Byte;
    rendermode: Integer;
    renderamt: Integer;
    rendercolor: TColor24;
    renderfx: Integer;
    movetype: Integer;
    animtime: Single;
    framerate: Single;
    body: Integer;
    controller: array[0..3] of Byte;
    blending: array[0..3] of Byte;
    velocity: TVec3;
    mins: TVec3;
    maxs: TVec3;
    aiment: Integer;
    owner: Integer;
    friction: Single;
    gravity: Single;
    team: Integer;
    playerclass: Integer;
    health: Integer;
    spectator: qboolean;
    weaponmodel: Integer;
    gaitsequence: Integer;
    basevelocity: TVec3;
    usehull: Integer;
    oldbuttons: Integer;
    onground: Integer;
    iStepLeft: Integer;
    flFallVelocity: Single;
    fov: Single;
    weaponanim: Integer;
    startpos: TVec3;
    endpos: TVec3;
    impacttime: Single;
    starttime: Single;
    iuser1: Integer;
    iuser2: Integer;
    iuser3: Integer;
    iuser4: Integer;
    fuser1: Single;
    fuser2: Single;
    fuser3: Single;
    fuser4: Single;
    vuser1: TVec3;
    vuser2: TVec3;
    vuser3: TVec3;
    vuser4: TVec3;
  end;
  entity_state_t = entity_state_s;

  TEntityState = entity_state_t;
  PEntityState = ^TEntityState;
  {$IF SizeOf(TEntityState) <> 340} {$MESSAGE WARN 'Structure size mismatch @ TEntityState.'} {$DEFINE MSME} {$IFEND}

  packet_entities_t = record
    num_entities: Integer;
    flags: array[0..31] of Byte;
    entities: ^entity_state_s;
  end;
  TPacketEntities = packet_entities_t;
  PPacketEntities = ^TPacketEntities;
  {$IF SizeOf(TPacketEntities) <> 40} {$MESSAGE WARN 'Structure size mismatch @ TPacketEntities.'} {$DEFINE MSME} {$IFEND}

  resource_s = record
    szFileName: array[0..MAX_QPATH - 1] of AnsiChar;
    &type: resourcetype_t;
    nIndex: Integer;
    nDownloadSize: Integer;
    ucFlags: Byte;
    rgucMD5_hash: array[0..15] of Byte;
    playernum: Byte;
    rguc_reserved: array[0..31] of Byte;
    pNext: ^resource_s;
    pPrev: ^resource_s;
  end;
  resource_t = resource_s;

  TResource = resource_t;
  PResource = ^resource_s;
  {$IF SizeOf(TResource) <> 136} {$MESSAGE WARN 'Structure size mismatch @ TResource.'} {$DEFINE MSME} {$IFEND}

  customization_s = record
    bInUse: qboolean;
    resource: resource_s;
    bTranslated: qboolean;
    nUserData1: Integer;
    nUserData2: Integer;
    pInfo: Pointer;
    pBuffer: Pointer;
    pNext: ^customization_s;
  end;
  customization_t = customization_s;

  TCustomization = customization_t;
  PCustomization = ^TCustomization;
  {$IF SizeOf(TCustomization) <> 164} {$MESSAGE WARN 'Structure size mismatch @ TCustomization.'} {$DEFINE MSME} {$IFEND}

//  netsrc_s = (NS_CLIENT = 0, NS_SERVER = 1, NS_MULTICAST = 2);
//  netsrc_t = netsrc_s;
//  TNetSrc = netsrc_t;
//  {$IF SizeOf(TNetSrc) <> 4} {$MESSAGE WARN 'Type size mismatch @ TNetSrc.'} {$DEFINE MSME} {$IFEND}

  flowstats_t = record
    size: Integer;
    time: Double;
  end;
  TFlowStats = flowstats_t;
  PFlowStats = ^TFlowStats;
  {$IF SizeOf(TFlowStats) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TFlowStats.'} {$DEFINE MSME} {$IFEND}

  flow_t = record
    stats: array[0..31] of flowstats_t;
    current: Integer;
    nextcompute: Double;
    kbytespersec: Single;
    avgkbytespersec: Single;
  end;
  TFlow = flow_t;
  PFlow = ^TFlow;
  {$IF SizeOf(TFlow) <> 536} {$MESSAGE WARN 'Structure size mismatch @ TFlow.'} {$DEFINE MSME} {$IFEND}

  fragbuf_s = record
    next: ^fragbuf_s;
    bufferid: Integer;
    frag_message: sizebuf_s;
    frag_message_buf: array[0..FRAGMENT_MAX_SIZE - 1] of Byte;
    isfile: qboolean;
    isbuffer: qboolean;
    iscompressed: qboolean;
    filename: array[0..MAX_PATH - 1] of Byte;
    foffset: Integer;
    size: Integer;
  end;
  fragbuf_t = fragbuf_s;

  TFragBuf = fragbuf_t;
  PFragBuf = ^TFragBuf;
  {$IF SizeOf(TFragBuf) <> 1708} {$MESSAGE WARN 'Structure size mismatch @ TFragBuf.'} {$DEFINE MSME} {$IFEND}

  fragbufwaiting_s = record
    next: ^fragbufwaiting_s;
    fragbufcount: Integer;
    fragbufs: Integer;
  end;
  fragbufwaiting_t = fragbufwaiting_s;

  TFragBufWaiting = fragbufwaiting_t;
  PFragBufWaiting = ^TFragBufWaiting;
  {$IF SizeOf(TFragBufWaiting) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TFragBufWaiting.'} {$DEFINE MSME} {$IFEND}

  netchan_s = record
    // NS_SERVER or NS_CLIENT, depending on channel.
    sock: netsrc_s;

    // Address this channel is talking to.
    remote_address: netadr_s;

    // For timeouts.  Time last message was received.
    player_slot: Integer;

	  // For timeouts.  Time last message was received.
    last_received: Single;

  	// Time when channel was connected.
    connect_time: Single;

	  // Bandwidth choke
  	// Bytes per second
    rate: Double;

    // If realtime > cleartime, free to send next packet
    cleartime: Double;

    // Sequencing variables
    //
    // Increasing count of sequence numbers
    incoming_sequence: Integer;
    // # of last outgoing message that has been ack'd.
    incoming_acknowledged: Integer;
    // Toggles T/F as reliable messages are received.
    incoming_reliable_acknowledged: Integer;
    // single bit, maintained local
    incoming_reliable_sequence: Integer;
    // Message we are sending to remote
    outgoing_sequence: Integer;
    // Whether the message contains reliable payload, single bit
    reliable_sequence: Integer;
    // Outgoing sequence number of last send that had reliable data
    last_reliable_sequence: Integer;

    connection_status: Pointer;
    pfnNetchan_Blocksize: procedure(state: Pointer); cdecl;

    // Staging and holding areas
    &message: sizebuf_s;
    message_buf: array[0..MAX_MSGLEN - 1] of Byte;

    // Reliable message buffer. We keep adding to it until reliable is acknowledged. Then we clear it.
    reliable_length: Integer;
    reliable_buf: array[0..MAX_MSGLEN - 1] of Byte;

    // Waiting list of buffered fragments to go onto queue. Multiple outgoing buffers can be queued in succession.
    waitlist: array[0..1] of ^fragbufwaiting_s;

    // Is reliable waiting buf a fragment?
    reliable_fragment: array[0..1] of Integer;
    // Buffer id for each waiting fragment
    reliable_fragid: array[0..1] of Cardinal;

    // The current fragment being set
    fragbufs: array[0..1] of ^fragbuf_s;
    // The total number of fragments in this stream
    fragbufcount: array[0..1] of Integer;

    // Position in outgoing buffer where frag data starts
    frag_startpos: array[0..1] of Smallint;
    // Length of frag data in the buffer
    frag_length: array[0..1] of Smallint;

    // Incoming fragments are stored here
    incomingbufs: array[0..1] of ^fragbuf_s;
    // Set to true when incoming data is ready
    incomingready: array[0..1] of qboolean;

    // Only referenced by the FRAG_FILE_STREAM component
    // Name of file being downloaded
    incomingfilename: array[0..MAX_PATH - 1] of AnsiChar;

    tempbuffer: Pointer;
    tempbuffersize: Integer;

    // Incoming and outgoing flow metrics
    flow: array[0..1] of flow_t;
  end;
  netchan_t = netchan_s;

  TNetchan = netchan_t;
  PNetchan = ^netchan_t;
  {$IF SizeOf(TNetchan) <> 9504} {$MESSAGE WARN 'Structure size mismatch @ TNetchan.'} {$DEFINE MSME} {$IFEND}

  screenfade_s = record
    // How fast to fade (tics / second) (+ fade in, - f)ade out)
    fadeSpeed: Single;
    // When the fading hits maximum
    fadeEnd: Single;
    // Total End Time of the fade (used for FFADE_OUT)
    fadeTotalEnd: Single;
    // When to reset to not fading (for fadeout and hold)
    fadeReset: Single;

    // Fade color

    fader: Byte;
    fadeg: Byte;
    fadeb: Byte;
    fadealpha: Byte;

    // Fading flags
    fadeFlags: Integer;
  end;
  screenfade_t = screenfade_s;

  TScreenFade = screenfade_t;
  PScreenFade = ^TScreenFade;
  {$IF SizeOf(TScreenFade) <> 24} {$MESSAGE WARN 'Structure size mismatch @ TScreenFade.'} {$DEFINE MSME} {$IFEND}

  efrag_s = record
    leaf: ^efrag_s;
    leafnext: ^efrag_s;
    entity: PPointer; // ^cl_entity_s
    entnext: ^efrag_s;
  end;
  efrag_t = efrag_s;

  TEFlag = efrag_t;
  PEFlag = ^TEFlag;
  {$IF SizeOf(TEFlag) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TEFlag.'} {$DEFINE MSME} {$IFEND}

  mleaf_s = record
    // common with node
    contents: Integer; // wil be a negative contents number
    visframe: Integer; // node needs to be traversed if current

    minmaxs: array[0..5] of Smallint; // for bounding box culling

    parent: PPointer; // mnode_s;

    // leaf specific
    compressed_vis: PByte;
    efrags: ^efrag_s;

    firstmarksurface: ^PPointer; // ^^msurface_t
    nummarksurfaces: Integer;
    key: Integer; // BSP sequence number for leaf's contents
    ambient_sound_level: array[0..3] of Byte;
  end;
  mleaf_t = mleaf_s;

  TMLeaf = mleaf_t;
  PMLeaf = ^TMLeaf;
  {$IF SizeOf(TMLeaf) <> 48} {$MESSAGE WARN 'Structure size mismatch @ TMLeaf.'} {$DEFINE MSME} {$IFEND}

  position_history_t = record
    // Time stamp for this movement
    animtime: Single;

    origin: vec3_t;
    angles: vec3_t;
  end;

  TPositionHistory = position_history_t;
  PPositionHistory = ^TPositionHistory;
  {$IF SizeOf(TPositionHistory) <> 28} {$MESSAGE WARN 'Structure size mismatch @ TPositionHistory.'} {$DEFINE MSME} {$IFEND}

  mouth_t = record
    mouthopen: Byte; // 0 = mouth closed, 255 = mouth agape
    sndcount: Byte; // counter for running average
    sndavg: Integer; // running average
  end;

  TMouth = mouth_t;
  PMouth = ^TMouth;
  {$IF SizeOf(TMouth) <> 8} {$MESSAGE WARN 'Structure size mismatch @ TMouth.'} {$DEFINE MSME} {$IFEND}

  latchedvars_t = record
    prevanimtime: Single;
    sequencetime: Single;
    prevseqblending: array[0..1] of Byte;
    prevorigin: vec3_t;
    prevangles: vec3_t;

    prevsequence: Integer;
    prevframe: Single;

  	prevcontroller: array[0..3] of Byte;
    prevblending: array[0..1] of Byte;
  end;

  TLatchedVars = latchedvars_t;
  PLatcherVars = ^TLatchedVars;
  {$IF SizeOf(TLatchedVars) <> 52} {$MESSAGE WARN 'Structure size mismatch @ TLatchedVars.'} {$DEFINE MSME} {$IFEND}

  dmodel_s = record
    mins, maxs: array[0..2] of Single;
    origin: array[0..2] of Single;
    headnode: array[0..3] of Integer;
    visleafs: Integer; // not including the solid leaf 0
    firstface, numfaces: Integer;
  end;
  dmodel_t = dmodel_s;

  TDModel = dmodel_s;
  PDModel = ^dmodel_s;
  {$IF SizeOf(TDModel) <> 64} {$MESSAGE WARN 'Structure size mismatch @ TDModel.'} {$DEFINE MSME} {$IFEND}

  mplane_s = record
    normal: vec3_t;			// surface normal
    dist: Single;			// closest appoach to origin
    &type: Byte;			// for texture axis selection and fast side tests
    signbits: Byte;		// signx + signy<<1 + signz<<1
    pad: array[0..1] of Byte;
  end;
  mplane_t = mplane_s;

  TMPlane = mplane_s;
  PMPlane = ^mplane_s;
  {$IF SizeOf(TMPlane) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TMPlane.'} {$DEFINE MSME} {$IFEND}

  mvertex_s = record
    position: vec3_t;
  end;
  mvertex_t = mvertex_s;

  TMVertex = mvertex_s;
  PMVertex = ^mvertex_s;
  {$IF SizeOf(TMVertex) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TMVertex.'} {$DEFINE MSME} {$IFEND}

  medge_t = record
    v: array[0..1] of Word;
    cachededgeoffset: Cardinal;
  end;

  TMedge = medge_t;
  PMedge = ^medge_t;
  {$IF SizeOf(TMedge) <> 8} {$MESSAGE WARN 'Structure size mismatch @ TMedge.'} {$DEFINE MSME} {$IFEND}

  mnode_s = record
    // common with leaf
    contents: Integer;		// 0, to differentiate from leafs
    visframe: Integer;		// node needs to be traversed if current

    minmaxs: array[0..5] of Smallint;		// for bounding box culling

    parent: ^mnode_s;

    // node specific
    plane: ^mplane_t;
    children: array[0..1] of ^mnode_s;

    firstsurface: Word;
    numsurfaces: Word;
  end;
  mnode_t = mnode_s;

  TMNode = mnode_s;
  PMNode = ^mnode_s;
  {$IF SizeOf(TMNode) <> 40} {$MESSAGE WARN 'Structure size mismatch @ TMNode.'} {$DEFINE MSME} {$IFEND}

  PSurfCache = ^surfcache_s;
  surfcache_s = record
    next: ^surfcache_s;
    owner: ^PSurfCache;
    lightadj: array[0..3] of Integer;
    dlight: Integer;
    size: Integer;
    width: Cardinal;
    height: Cardinal;
    mipscale: Single;
    texture: PPointer; // texture_s
    data: array[0..3] of AnsiChar;
  end;
  surfcache_t = surfcache_s;

  TSurfCache = surfcache_s;
  {$IF SizeOf(TSurfCache) <> 52} {$MESSAGE WARN 'Structure size mismatch @ TSurfCache.'} {$DEFINE MSME} {$IFEND}

  msurface_s = record
    visframe: Integer;		// should be drawn when node is crossed

    dlightframe: Integer;	// last frame the surface was checked by an animated light
    dlightbits: Integer;	// dynamically generated. Indicates if the surface illumination
                          // is modified by an animated light.

    plane: ^mplane_s;		// pointer to shared plane
    flags: Integer;			// see SURF_ #defines

    firstedge: Integer;	// look up in model->surfedges[], negative numbers
    numedges: Integer;	// are backwards edges

    // surface generation data
    cachespots: array[0..3] of ^surfcache_s;

    texturemins: array[0..1] of Smallint; // smallest s/t position on the surface.
    extents: array[0..1] of Smallint; // ?? s/t texture size, 1..256 for all non-sky surfaces

    texinfo: PPointer; // mtexinfo_t

    // lighting info
    styles: array[0..3] of Byte;	// index into d_lightstylevalue[] for animated lights
                                  // no one surface can be effected by more than 4
                                  // animated lights.
    samples: ^color24;

    pdecals: PPointer; // decal_t
  end;
  msurface_t = msurface_s;

  TMSurface = msurface_s;
  PMSurface = ^msurface_s;
  {$IF SizeOf(TMSurface) <> 68} {$MESSAGE WARN 'Structure size mismatch @ TMSurface.'} {$DEFINE MSME} {$IFEND}

  // JAY: Compress this as much as possible
  decal_s = record
    pnext: ^decal_s;       // linked list for each surface
    psurface: ^msurface_t; // Surface id for persistence / unlinking
    dx: Smallint;          // Offsets into surface texture (in texture coordinates, so we don't need floats)
    dy: Smallint;
    texture: Word;		// Decal texture
    scale: Byte;			// Pixel scale
    flags: Byte;			// Decal flags

    entityIndex: Smallint;	// Entity this is attached to
  end;
  decal_t = decal_s;

  TDecal = decal_s;
  PDecal = ^decal_s;
  {$IF SizeOf(TDecal) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TDecal.'} {$DEFINE MSME} {$IFEND}

  texture_s = record
    name: array[0..15] of AnsiChar;
    width, height: Cardinal;
    gl_texturenum: Integer;
    texturechain: ^msurface_s;

	  anim_total: Integer;			    // total tenths in sequence ( 0 = no)
    anim_min, anim_max: Integer;	// time for this frame min <=time< max
    anim_next: ^texture_s;		    // in the animation sequence
    alternate_anims: ^texture_s;	// bmodels in frame 1 use these
    offsets: array[0..3] of Cardinal;	// four mip maps stored

  	pPal: PByte;
  end;
  texture_t = texture_s;

  TTexture = texture_s;
  PTexture = ^texture_s;
  {$IF SizeOf(TTexture) <> 72} {$MESSAGE WARN 'Structure size mismatch @ TTexture.'} {$DEFINE MSME} {$IFEND}

  mtexinfo_s = record
    vecs: array[0..1] of array[0..3] of Single; // [s/t] unit vectors in world space.
                                                // [i][3] is the s/t offset relative to the origin.
                                                // s or t = dot(3Dpoint,vecs[i])+vecs[i][3]
    mipadjust: Single;
    texture: ^texture_t;
    flags: Integer; // sky or slime, no lightmap or 256 subdivision
  end;
  mtexinfo_t = mtexinfo_s;

  TMTexInfo = mtexinfo_s;
  PMTexInfo = ^mtexinfo_s;
  {$IF SizeOf(TMTexInfo) <> 44} {$MESSAGE WARN 'Structure size mismatch @ TMTexInfo.'} {$DEFINE MSME} {$IFEND}

  dclipnode_s = record
    planenum: Integer;
    children: array[0..1] of Smallint;	// negative numbers are contents
  end;
  dclipnode_t = dclipnode_s;

  TDClipNode = dclipnode_s;
  PDClipNode = ^dclipnode_s;
  {$IF SizeOf(TDClipNode) <> 8} {$MESSAGE WARN 'Structure size mismatch @ TDClipNode.'} {$DEFINE MSME} {$IFEND}

  hull_s = record
    clipnodes: ^dclipnode_t;
    planes: ^mplane_t;
    firstclipnode: Integer;
    lastclipnode: Integer;
    clip_mins, clip_maxs: vec3_t;
  end;
  hull_t = hull_s;

  THull = hull_s;
  PHull = ^hull_s;
  {$IF SizeOf(THull) <> 40} {$MESSAGE WARN 'Structure size mismatch @ THull.'} {$DEFINE MSME} {$IFEND}

  cache_user_s = record
    data: Pointer;
  end;
  cache_user_t = cache_user_s;

  TCacheUser = cache_user_s;
  PCacheUser = ^cache_user_s;
  {$IF SizeOf(TCacheUser) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TCacheUser.'} {$DEFINE MSME} {$IFEND}

  model_s = record
    name: array[0..63] of AnsiChar;

    needload: Integer;		// bmodels and sprites don't cache normally

    &type: modtype_t;
    numframes: Integer;
    synctype: synctype_t;

    flags: Integer;

    //
    // volume occupied by the model
    //
    mins, maxs: vec3_t;
    radius: Single;

    //
    // brush model
    //
    firstmodelsurface, nummodelsurfaces: Integer;

    numsubmodels: Integer;
    submodels: ^dmodel_t;

    numplanes: Integer;
    planes: ^mplane_t;

    numleafs: Integer;		// number of visible leafs, not counting 0
    leafs: ^mleaf_s;

    numvertexes: Integer;
    vertexes: ^mvertex_t;

    numedges: Integer;
    edges: ^medge_t;

    numnodes: Integer;
    nodes: ^mnode_t;

    numtexinfo: Integer;
    texinfo: ^mtexinfo_t;

    numsurfaces: Integer;
    surfaces: ^msurface_t;

    numsurfedges: Integer;
    surfedges: PInteger;

    numclipnodes: Integer;
    clipnodes: ^dclipnode_t;

    nummarksurfaces: Integer;
    marksurfaces: ^PMSurface;

    hulls: array[0..3] of hull_t;

    numtextures: Integer;
    textures: ^PTexture;

    visdata: PByte;

    lightdata: ^color24;

    entities: PAnsiChar;

    //
    // additional model data
    //
    cache: cache_user_t;			// only access through Mod_Extradata
  end;
  model_t = model_s;

  TModel = model_s;
  PModel = ^TModel;
  {$IF SizeOf(TModel) <> 392} {$MESSAGE WARN 'Structure size mismatch @ TModel.'} {$DEFINE MSME} {$IFEND}

  cl_entity_s = record
    index: Integer; // Index into cl_entities ( should match actual slot, but not necessarily )

    player: qboolean;     // True if this entity is a "player"

    baseline: entity_state_t;   // The original state from which to delta during an uncompressed message
    prevstate: entity_state_t;  // The state information from the penultimate message received from the server
    curstate: entity_state_t;   // The state information from the last message received from server

    current_position: Integer;  // Last received history update index
    ph: array[0..63] of position_history_t;   // History of position and angle updates for this player

    mouth: mouth_t; // For synchronizing mouth movements.

    latched: latchedvars_t;		// Variables used by studio model rendering routines

    // Information based on interplocation, extrapolation, prediction, or just copied from last msg received.
    //
    lastmove: Single;

    // Actual render position and angles
    origin: vec3_t;
    angles: vec3_t;

    // Attachment points
    attachment: array[0..3] of vec3_t;

    // Other entity local information
    trivial_accept: Integer;

    model: ^model_s;			// cl.model_precache[ curstate.modelindes ];  all visible entities have a model
    efrag: ^efrag_s;			// linked list of efrags
    topnode: ^mnode_s;		// for bmodels, first world node that splits bmodel, or NULL if not split

    syncbase: Single;		// for client-side animations -- used by obsolete alias animation system, remove?
    visframe: Integer;		// last frame this entity was found in an active leaf
    cvFloorColor: colorVec;
  end;
  cl_entity_t = cl_entity_s;

  TCLEntity = cl_entity_t;
  PCLEntity = ^TCLEntity;
  {$IF SizeOf(TCLEntity) <> 3000} {$MESSAGE WARN 'Structure size mismatch @ TCLEntity.'} {$DEFINE MSME} {$IFEND}

  clientdata_s = record
    origin: vec3_t;
    velocity: vec3_t;

    viewmodel: Integer;
    punchangle: vec3_t;
    flags: Integer;
    waterlevel: Integer;
    watertype: Integer;
    view_ofs: vec3_t;
    health: Single;

    bInDuck: Integer;

    weapons: Integer; // remove?

    flTimeStepSound: Integer;
    flDuckTime: Integer;
    flSwimTime: Integer;
    waterjumptime: Integer;

    maxspeed: Single;

    fov: Single;
    weaponanim: Integer;

    m_iId: Integer;
    ammo_shells: Integer;
    ammo_nails: Integer;
    ammo_cells: Integer;
    ammo_rockets: Integer;
    m_flNextAttack: Single;

    tfstate: Integer;

    pushmsec: Integer;

    deadflag: Integer;

    physinfo: array[0..255] of AnsiChar;

    // For mods
    iuser1: Integer;
    iuser2: Integer;
    iuser3: Integer;
    iuser4: Integer;
    fuser1: Single;
    fuser2: Single;
    fuser3: Single;
    fuser4: Single;
    vuser1: vec3_t;
    vuser2: vec3_t;
    vuser3: vec3_t;
    vuser4: vec3_t;
  end;
  clientdata_t = clientdata_s;

  TClientData = clientdata_s;
  PClientData = ^clientdata_s;
  {$IF SizeOf(TClientData) <> 476} {$MESSAGE WARN 'Structure size mismatch @ TClientData.'} {$DEFINE MSME} {$IFEND}

  local_state_s = record
    playerstate: entity_state_t;
    client: clientdata_t;
    weapondata: array[0..63] of weapon_data_t;
  end;
  local_state_t = local_state_s;

  TLocalState = local_state_s;
  PLocalState = ^local_state_s;
  {$IF SizeOf(TLocalState) <> 6448} {$MESSAGE WARN 'Structure size mismatch @ TLocalState.'} {$DEFINE MSME} {$IFEND}

  event_args_s = record
    flags: Integer;

    // Transmitted
    entindex: Integer;

    origin: array[0..2] of Single;
    angles: array[0..2] of Single;
    velocity: array[0..2] of Single;

    ducking: Integer;

    fparam1: Single;
    fparam2: Single;

    iparam1: Integer;
    iparam2: Integer;

    bparam1: Integer;
    bparam2: Integer;
  end;
  event_args_t = event_args_s;

  TEventArgs = event_args_s;
  PEventArgs = ^event_args_s;
  {$IF SizeOf(TEventArgs) <> 72} {$MESSAGE WARN 'Structure size mismatch @ TEventArgs.'} {$DEFINE MSME} {$IFEND}

  event_info_s = record
    index: Word;			  // 0 implies not in use

    packet_index: Smallint;      // Use data from state info for entity in delta_packet .  -1 implies separate info based on event
                             // parameter signature
    entity_index: Smallint;      // The edict this event is associated with

    fire_time: Single;        // if non-zero, the time when the event should be fired ( fixed up on the client )

    args: event_args_t;

    // CLIENT ONLY
    flags: Integer;			// Reliable or not, etc.
  end;
  event_info_t = event_info_s;

  TEventInfo = event_info_s;
  PEventInfo = ^event_info_s;
  {$IF SizeOf(TEventInfo) <> 88} {$MESSAGE WARN 'Structure size mismatch @ TEventInfo.'} {$DEFINE MSME} {$IFEND}

  consistency_s = record
    filename: PAnsiChar;
    issound: Integer;
    orig_index: Integer;
    value: Integer;
    check_type: Integer;
    mins: array[0..2] of Single;
    maxs: array[0..2] of Single;
  end;
  consistency_t = consistency_s;

  TConsistency = consistency_s;
  PConsistency = ^consistency_s;
  {$IF SizeOf(TConsistency) <> 44} {$MESSAGE WARN 'Structure size mismatch @ TConsistency.'} {$DEFINE MSME} {$IFEND}

  cmd_s = record
    cmd: usercmd_t;
    senttime: Single;
    receivedtime: Single;
    frame_lerp: Single;
    processedfuncs: qboolean;
    heldback: qboolean;
    sendsize: Integer;
  end;
  cmd_t = cmd_s;

  TCmd = cmd_s;
  PCmd = ^cmd_s;
  {$IF SizeOf(TCmd) <> 76} {$MESSAGE WARN 'Structure size mismatch @ TCmd.'} {$DEFINE MSME} {$IFEND}

  frame_s = record
    receivedtime: Double;
    latency: Double;
    invalid: qboolean;
    choked: qboolean;
    playerstate: array[0..31] of entity_state_t;
    time: Double;
    clientdata: clientdata_t;
    weapondata: array[0..63] of weapon_data_t;
    packet_entities: packet_entities_t;
    clientbytes: UInt16;
    playerinfobytes: UInt16;
    packetentitybytes: UInt16;
    tentitybytes: UInt16;
    soundbytes: UInt16;
    eventbytes: UInt16;
    usrbytes: UInt16;
    voicebytes: UInt16;
    msgbytes: UInt16;
  end;
  frame_t = frame_s;

  TFrame = frame_s;
  PFrame = ^frame_s;
  {$IF SizeOf(TFrame) <> 17080} {$MESSAGE WARN 'Structure size mismatch @ TFrame.'} {$DEFINE MSME} {$IFEND}

  player_info_t = record
    userid: Integer;
    userinfo: array[0..255] of AnsiChar;
    name: array[0..31] of AnsiChar;
    spectator: Integer;
    ping: Integer;
    packet_loss: Integer;
    model: array[0..63] of AnsiChar;
    topcolor: Integer;
    bottomcolor: Integer;
    renderframe: Integer;
    gaitsequence: Integer;
    gaitframe: Single;
    gaityaw: Single;
    prevgaitorigin: vec3_t;
    customdata: customization_t;
    hashedcdkey: array[0..15] of AnsiChar;
    m_nSteamID: UInt64;
  end;
  player_info_s = player_info_t;

  TPlayerInfo = player_info_s;
  PPlayerInfo = ^player_info_s;
  {$IF SizeOf(TPlayerInfo) <> 592} {$MESSAGE WARN 'Structure size mismatch @ TPlayerInfo.'} {$DEFINE MSME} {$IFEND}

  dlight_s = record
    origin: vec3_t;
    radius: Single;
    color: color24;
    die: Single;				// stop lighting after this time
    decay: Single;				// drop this each second
    minlight: Single;			// don't add when contributing less
    key: Integer;
    dark: qboolean;			// subtracts light instead of adding
  end;
  dlight_t = dlight_s;

  TDLight = dlight_s;
  PDLight = ^dlight_s;
  {$IF SizeOf(TDLight) <> 40} {$MESSAGE WARN 'Structure size mismatch @ TDLight.'} {$DEFINE MSME} {$IFEND}

  cactive_e =
  (
    ca_dedicated,
    ca_disconnected,
    ca_connecting,
    ca_connected,
    ca_uninitialized,
    ca_active
  );
  cactive_t = cactive_e;

  TActive = cactive_e;
  PActive = ^cactive_e;
  {$IF SizeOf(TActive) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TActive.'} {$DEFINE MSME} {$IFEND}

  soundfade_s = record
    nStartPercent: Integer;
    nClientSoundFadePercent: Integer;
    soundFadeStartTime: Double;
    soundFadeOutTime: Integer;
    soundFadeHoldTime: Integer;
    soundFadeInTime: Integer;
  end;
  soundfade_t = soundfade_s;

  TSoundFade = soundfade_s;
  PSoundFade = ^soundfade_s;
  {$IF SizeOf(TSoundFade) <> 32} {$MESSAGE WARN 'Structure size mismatch @ TSoundFade.'} {$DEFINE MSME} {$IFEND}

  client_static_s = record
    state: cactive_e;
    netchan: netchan_s;
    datagram: sizebuf_s;
    datagram_buf: array[0..3999] of Byte;
    connect_time: Double;
    connect_retry: Integer;
    challenge: Integer;
    authprotocol: Byte;
    userid: Integer;
    trueaddress: array[0..31] of AnsiChar;
    slist_time: Single;
    signon: Integer;
    servername: array[0..259] of AnsiChar;
    mapstring: array[0..63] of AnsiChar;
    spawnparms: array[0..2047] of AnsiChar;
    userinfo: array[0..255] of AnsiChar;
    nextcmdtime: Single;
    lastoutgoingcommand: Integer;
    demonum: Integer;
    demos: array[0..31] of array[0..15] of AnsiChar;
    demorecording: qboolean;
    demoplayback: qboolean;
    timedemo: qboolean;
    demostarttime: Single;
    demostartframe: Integer;
    forcetrack: Integer;
    demofile: FileHandle_t;
    demoheader: FileHandle_t;
    demowaiting: qboolean;
    demoappending: qboolean;
    demofilename: array[0..259] of AnsiChar;
    demoframecount: Integer;
    td_lastframe: Integer;
    td_startframe: Integer;
    td_starttime: Single;
    dl: incomingtransfer_s;
    packet_loss: Single;
    packet_loss_recalc_time: Double;
    playerbits: Integer;
    soundfade: soundfade_s;
    physinfo: array[0..255] of AnsiChar;
    md5_clientdll: array[0..15] of Byte;
    game_stream: netadr_s;
    connect_stream: netadr_s;
    passive: qboolean;
    spectator: qboolean;
    director: qboolean;
    fSecureClient: qboolean;
    isVAC2Secure: qboolean;
    GameServerSteamID: UInt64; // UInt32?
    build_num: Integer;
  end;
  client_static_t = client_static_s;

  TClientStatic = client_static_s;
  PClientStatic = ^client_static_s;
  {$IF SizeOf(TClientStatic) <> 17608} {$MESSAGE WARN 'Structure size mismatch @ TClientStatic.'} {$DEFINE MSME} {$IFEND}

  // @xref: VoiceSE_StartChannel
  sfx_s = record
    Name: array[0..63] of AnsiChar;
    cache: cache_user_s;
    servercount: Integer;
  end;
  sfx_t = sfx_s;

  TSfx = sfx_s;
  PSfx = ^sfx_s;
  {$IF SizeOf(TSfx) <> 72} {$MESSAGE WARN 'Structure size mismatch @ TSfx.'} {$DEFINE MSME} {$IFEND}

  event_state_s = record
    ei: array[0..63] of event_info_s;
  end;
  event_state_t = event_state_s;

  TEventState = event_state_s;
  PEventState = ^event_state_s;
  {$IF SizeOf(TEventState) <> 5632} {$MESSAGE WARN 'Structure size mismatch @ TEventState.'} {$DEFINE MSME} {$IFEND}

  // @xref: "CL_ClearClientState"
  client_state_s = record
    max_edicts: Integer;
    resourcesonhand: resource_t;
    resourcesneeded: resource_t;
    resourcelist: array[0..1279] of resource_t;
    num_resources: Integer;
    need_force_consistency_response: qboolean;
    serverinfo: array[0..511] of AnsiChar;
    servercount: Integer;
    validsequence: Integer;
    parsecount: Integer;
    parsecountmod: Integer;
    stats: array[0..31] of Integer;
    weapons: Integer;
    cmd: usercmd_t;
    viewangles: vec3_t;
    punchangle: vec3_t;
    crosshairangle: vec3_t;
    simorg: vec3_t;
    simvel: vec3_t;
    simangles: vec3_t;
    predicted_origins: array[0..63] of vec3_t;
    prediction_error: vec3_t;
    idealpitch: Single;
    viewheight: vec3_t;
    sf: screenfade_t;
    paused: qboolean;
    onground: Integer;
    moving: Integer;
    waterlevel: Integer;
    sehull: Integer;
    maxspeed: Single;
    pushmsec: Integer;
    light_level: Integer;
    intermission: Integer;
    mtime: array[0..1] of Double;
    time: Double;
    oldtime: Double;
    frames: array[0..63] of frame_s;
    commands: array[0..63] of cmd_s;
    predicted_frames: array[0..63] of local_state_s;
    delta_sequence: Integer;
    playernum: Integer;
    event_precache: array[0..255] of event_s;
    model_precache: array[0..511] of ^model_s;
    model_precache_count: Integer;
    sound_precache: array[0..511] of ^sfx_s;
    consistency_list: array[0..511] of consistency_t;
    num_consistency: Integer;
    highentity: Integer;
    levelname: array[0..39] of AnsiChar;
    maxclients: Integer;
    gametype: Integer;
    viewentity: Integer;
    worldmodel: ^model_s;
    free_efrags: ^efrag_s;
    num_entities: Integer;
    num_statics: Integer;
    viewent: cl_entity_s;
    cdtrack: Integer;
    looptrack: Integer;
    serverCRC: CRC32_t;
    clientdllmd5: array[0..15] of Byte;
    weaponstarttime: Single;
    weaponsequence: Integer;
    fPrecaching: Integer;
    pLight: ^dlight_s;
    players: array[0..31] of player_info_t;
    instanced_baseline: array[0..63] of entity_state_t;
    instanced_baseline_number: Integer;
    mapCRC: CRC32_t;
    events: event_state_s;
    downloadUrl: array[0..127] of AnsiChar;
  end;
  client_state_t = client_state_s;

  TClientState = client_state_s;
  PClientState = ^client_state_s;
  {$IF SizeOf(TClientState) <> 1767024} {$MESSAGE WARN 'Structure size mismatch @ TClientState.'} {$DEFINE MSME} {$IFEND}

  PParticle = ^particle_s;
  particle_s = record
    // driver-usable fields
    org: vec3_t;
    color: Smallint;
    packedColor: Smallint;

    // drivers never touch the following fields
    next: ^particle_s;
    vel: vec3_t;
    ramp: Single;
    die: Single;
    &type: ptype_t;
    deathfunc: procedure(particle: PParticle); cdecl;

    // for pt_clientcusttom, we'll call this function each frame
    callback: procedure(particle: PParticle; frametime: Single); cdecl;

    // For deathfunc, etc.
    context: Byte;
  end;
  particle_t = particle_s;

  TParticle = particle_s;
  {$IF SizeOf(TParticle) <> 56} {$MESSAGE WARN 'Structure size mismatch @ TParticle.'} {$DEFINE MSME} {$IFEND}

  // @xref: R_BeamClear
  beam_s = record
    next: ^beam_s;
    &type: Integer;
    flags: Integer;
    source: vec3_t;
    target: vec3_t;
    delta: vec3_t;
    t: Single;		// 0 .. 1 over lifetime of beam
    freq: Single;
    die: Single;
    width: Single;
    amplitude: Single;
    r, g, b: Single;
    brightness: Single;
    speed: Single;
    frameRate: Single;
    frame: Single;
    segments: Integer;
    startEntity: Integer;
    endEntity: Integer;
    modelIndex: Integer;
    frameCount: Integer;
    pFollowModel: ^model_s;
    particles: ^particle_s;
  end;
  BEAM = beam_s;

  TBeam = beam_s;
  PBeam = ^beam_s;
  {$IF SizeOf(TBeam) <> 124} {$MESSAGE WARN 'Structure size mismatch @ TBeam.'} {$DEFINE MSME} {$IFEND}

  pmplane_t = record
    normal: vec3_t;
    dist: Single;
  end;

  TPMPlane = pmplane_t;
  PPMPlane = ^pmplane_t;
  {$IF SizeOf(TPMPlane) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TPMPlane.'} {$DEFINE MSME} {$IFEND}

  pmtrace_s = record
    allsolid: qboolean;	        // if true, plane is not valid
    startsolid: qboolean;	      // if true, the initial point was in a solid area
    inopen, inwater: qboolean;  // End point is in empty space or in water
    fraction: Single;		        // time completed, 1.0 = didn't hit anything
    endpos: vec3_t;			        // final position
    plane: pmplane_t;		        // surface normal at impact
    ent: Integer;			          // entity at impact
    deltavelocity: vec3_t;      // Change in player's velocity caused by impact.
                                // Only run on server.
    hitgroup: Integer;
  end;
  pmtrace_t = pmtrace_s;

  TPMTrace = pmtrace_s;
  PPMTrace = ^pmtrace_s;
  {$IF SizeOf(TPMTrace) <> 68} {$MESSAGE WARN 'Structure size mismatch @ TPMTrace.'} {$DEFINE MSME} {$IFEND}

  // @xref: CL_InitTEnts
  tempent_s = record
    flags: Integer;
    die: Single;
    frameMax: Single;
    x: Single;
    y: Single;
    z: Single;
    fadeSpeed: Single;
    bounceFactor: Single;
    hitSound: Integer;
    hitcallback: procedure(ent: tempent_s; ptr: pmtrace_s); cdecl;
    callback: procedure(ent: tempent_s; frametime: Single; currenttime: Single); cdecl;

    next: ^tempent_s;
    priority: Integer;
    clientIndex: Smallint;	// if attached, this is the index of the client to stick to
                            // if COLLIDEALL, this is the index of the client to ignore
                            // TENTS with FTENT_PLYRATTACHMENT MUST set the clientindex!

    tentOffset: vec3_t;		  // if attached, client origin + tentOffset = tent origin.
    entity: cl_entity_s;

    // baseline.origin		- velocity
    // baseline.renderamt	- starting fadeout intensity
    // baseline.angles		- angle velocity
  end;
  TEMPENTITY = tempent_s;

  TTempEntity = tempent_s;
  PTempEntity = ^tempent_s;
  PPTempEntity = ^PTempEntity;
  {$IF SizeOf(TTempEntity) <> 3068} {$MESSAGE WARN 'Structure size mismatch @ TTempEntity.'} {$DEFINE MSME} {$IFEND}

  HSPRITE = Cardinal;

  SCREENINFO_s = record
    iSize: Integer;
    iWidth: Integer;
    iHeight: Integer;
    iFlags: Integer;
    iCharHeight: Integer;
    charWidths: array[0..255] of Smallint;
  end;
  SCREENINFO = SCREENINFO_s;

  TScreenInfo = SCREENINFO;
  PScreenInfo = ^SCREENINFO;

  hud_player_info_s = record
    name: PAnsiChar;
    ping: Smallint;
    thisplayer: Boolean; // TRUE if this is the calling player

    spectator: Boolean;
    packetloss: Boolean;

    model: PAnsiChar;
    topcolor: Smallint;
    bottomcolor: Smallint;

    m_nSteamID: UInt64;
  end;
  hud_player_info_t = hud_player_info_s;

  THudPlayerInfo = hud_player_info_s;
  PHudPlayerInfo = ^hud_player_info_s;

  extra_player_info_t = record
    frags: Smallint;	     // pev->frags
    deaths: Smallint;	     // m_iDeaths
    team_id: Smallint;	   // unused

    has_c4: Integer;	     // fills by server in 'Radar', 'ScoreAttrib' and 'DeathMsg'
                           // usermsgs

    vip: Integer;		       // fills by server in 'ScoreAttrib' usermsg
    origin: vec3_t;        // radar flash coord (?)

    radarflash: Single;    // next radar flash time
    radarflashon: Integer; // need to do radar flash? (?)
    radarflashes: Integer; // radar flash count (?)

    playerclass: Smallint; // needs for some radar stuff (?), can be 0 or 1

    teamnumber: Smallint;	 // m_iTeam; player team
    teamname: array[0..15] of AnsiChar;	// player's team name, fills by server in 'TeamInfo' usermsg,
                                        // but can be also filled by client in 'HostagePos'
                                        // and 'BombDrop' usermsgs; can be 'SPECTATOR', 'T' or 'CT'

    dead: Integer;			// is player dead?
    showhealth: Single;
    health: Integer;		// fills when you are spectator or HLTV

    location: array[0..31] of AnsiChar;	// fills by server in 'Location' usermsg
                                        // when player is spectator or in the same team
                                        // as another player

    // WARNING: These values are available only for newest game builds (8xxx and above)!

    sb_health: Integer;
    sb_account: Integer;
    has_defuse_kit: Integer;
  end;

  cmdalias_s = record
    next: ^cmdalias_s;
    name: array[0..31] of AnsiChar;
    value: PAnsiChar;
  end;
  cmdalias_t = cmdalias_s;

  TCmdAlias = cmdalias_s;
  PCmdAlias = ^cmdalias_s;

  triangleapi_s = record
    version: Integer;

    RenderMode: procedure(mode: Integer); cdecl;
    &Begin: procedure(primitiveCode: Integer); cdecl;
    &End: procedure; cdecl;

    Color4f: procedure(r, g, b, a: Single); cdecl;
    Color4ub: procedure(r, g, b, a: Byte); cdecl;
    TexCoord2f: procedure(u, v: Single); cdecl;
    Vertex3fv: procedure(worldPnt: PSingle); cdecl;
    Vertex3f: procedure(x, y, z: Single); cdecl;
    Brightness: procedure(brightness: Single); cdecl;
    CullFace: procedure(style: TRICULLSTYLE); cdecl;
    SpriteTexture: function(pSpriteModel: PModel; frame: Integer): Integer; cdecl;
    WorldToScreen: function(world, screen: PSingle): Integer; cdecl;  // Returns 1 if it's z clipped
    Fog: procedure(flFogColor: PVec3; flStart, flEnd: Single; bOn: Integer); cdecl; // Works just like GL_FOG, flFogColor is r/g/b.
    ScreenToWorld: procedure(screen, world: PSingle); cdecl;
    GetMatrix: procedure(pname: Integer; matrix: PSingle); cdecl;
    BoxInPVS: function(mins, maxs: PSingle): Integer; cdecl;
    LightAtPoint: procedure(pos, value: PSingle); cdecl;
    Color4fRendermode: procedure(r, g, b, a: Single; rendermode: Integer); cdecl;
    FogParams: procedure(flDensity: Single; iFogSkybox: Integer); cdecl; // Used with Fog()...sets fog density and whether the fog should be applied to the skybox
  end;
  triangleapi_t = triangleapi_s;

  TTriangleAPI = triangleapi_s;
  PTriangleAPI = ^triangleapi_s;

  physent_s = record
    name: array[0..31] of AnsiChar;
    player: Integer;
    origin: vec3_t;
    model: ^model_s;
    studiomodel: ^model_s;
    mins: vec3_t;
    maxs: vec3_t;
    info: Integer;
    angles: vec3_t;
    solid: Integer;
    skin: Integer;
    rendermode: Integer;
    frame: Single;
    sequence: Integer;
    controller: array[0..3] of Byte;
    blending: array[0..1] of Byte;
    movetype: Integer;
    takedamage: Integer;
    blooddecal: Integer;
    team: Integer;
    classnumber: Integer;
    iuser1: Integer;
    iuser2: Integer;
    iuser3: Integer;
    iuser4: Integer;
    fuser1: Single;
    fuser2: Single;
    fuser3: Single;
    fuser4: Single;
    vuser1: vec3_t;
    vuser2: vec3_t;
    vuser3: vec3_t;
    vuser4: vec3_t;
  end;
  physent_t = physent_s;

  TPhysEnt = physent_s;
  PPhysEnt = ^physent_s;

  event_api_s = record
    Version: Integer;
    EV_PlaySound: procedure(ent: Integer; origin: PSingle; channel: Integer; sample: PAnsiChar; volume, attenuation: Single; fFlags: Integer; pitch: Integer); cdecl;
    EV_StopSound: procedure(ent: Integer; channel: Integer; sample: PAnsiChar); cdecl;
    EV_FindModelIndex: function(pmodel: PAnsiChar): Integer; cdecl;
    EV_IsLocal: function(playernum: Integer): Integer; cdecl;
    EV_LocalPlayerDucking: function: Integer; cdecl;
    EV_LocalPlayerViewheight: procedure(viewheight: PSingle); cdecl;
    EV_LocalPlayerBounds: procedure(hull: Integer; mins, maxs: PSingle); cdecl;
    EV_IndexFromTrace: function(pTrace: PPMTrace): Integer; cdecl;
    EV_GetPhysent: function(idx: Integer): physent_s; cdecl;
    EV_SetUpPlayerPrediction: procedure(dopred: Integer; bIncludeLocalClient: Integer); cdecl;
    EV_PushPMStates: procedure; cdecl;
    EV_PopPMStates: procedure; cdecl;
    EV_SetSolidPlayers: procedure(playernum: Integer); cdecl;
    EV_SetTraceHull: procedure(hull: Integer); cdecl;
    EV_PlayerTrace: procedure(start, &end: PSingle; traceFlags: Integer; ignore_pe: Integer; tr: PPMTrace); cdecl;
    EV_WeaponAnimation: procedure(sequence: Integer; body: Integer); cdecl;
    EV_PrecacheEvent: function(&type: Integer; psz: PAnsiChar): Word; cdecl;
    EV_PlaybackEvent: procedure(flags: Integer; pInvoker: PEdict; eventindex: Word; delay: Single; origin: Single; angles: PSingle; fparam1, fparam2: Single; iparam1, iparam2: Integer; bparam1, bparam2: Integer); cdecl;
    EV_TraceTexture: function(ground: Integer; vstart: PSingle; vend: PSingle): PAnsiChar; cdecl;
    EV_StopAllSounds: procedure(entnum: Integer; entchannel: Integer); cdecl;
    EV_KillEvents: procedure(entnum: Integer; eventname: PAnsiChar); cdecl;
  end;
  event_api_t = event_api_s;

  TEventAPI = event_api_s;
  PEventAPI = ^event_api_s;

  demo_api_s = record
    IsRecording: function: Integer; cdecl;
    IsPlayingback: function: Integer; cdecl;
    IsTimeDemo: function: Integer; cdecl;
    WriteBuffer: procedure(Size: Integer; buffer: PByte); cdecl;
  end;
  demo_api_t = demo_api_s;

  TDemoAPI = demo_api_s;
  PDemoAPI = ^demo_api_s;

  net_status_s = record
		// Connected to remote server?  1 == yes, 0 otherwise
    connected: Integer;
    // Client's IP address
    local_address: netadr_t;
    // Address of remote server
    remote_address: netadr_t;
    // Packet Loss ( as a percentage )
    packet_loss: Integer;
    // Latency, in seconds ( multiply by 1000.0 to get milliseconds )
    latency: Double;
    // Connection time, in seconds
    connection_time: Double;
    // Rate setting ( for incoming data )
    rate: Double;
  end;
  net_status_t = net_status_s;

  TNetStatus = net_status_s;
  PNetStatus = ^net_status_s;

  net_response_s = record
    // NET_SUCCESS or an error code
    error: Integer;

    // Context ID
    context: Integer;
    // Type
    &type: Integer;

    // Server that is responding to the request
    remote_address: netadr_s;

    // Response RTT ping time
    ping: Double;
    // Key/Value pair string ( separated by backlash \ characters )
    // WARNING:  You must copy this buffer in the callback function, because it is freed
    //  by the engine right after the call!!!!
    // ALSO:  For NETAPI_REQUEST_SERVERLIST requests, this will be a pointer to a linked list of net_adrlist_t's
    response: Pointer;
  end;
  net_response_t = net_response_s;

  TNetResponse = net_response_s;
  PNetResponse = ^net_response_s;

  net_api_response_func_t = procedure(var response: net_response_s); cdecl;

  net_api_query_s = record
    next: ^net_api_query_s;
    context: Integer;
    &type: Integer;
    flags: Integer;
    requesttime: Double;
    timeout: Double;
    request: netadr_t;
    callback: net_api_response_func_t;
  end;
  net_api_query_t = net_api_query_s;

  TNetAPIQuery = net_api_query_s;
  PNetAPIQuery = ^net_api_query_s;

  net_api_s = record
    InitNetworking: procedure; cdecl;
    Status: procedure(var status: net_status_s); cdecl;
    SendRequest: procedure(context: Integer; request: Integer; flags: Integer; timeout: Double; const remote_address: netadr_s; response: net_api_response_func_t); cdecl;
    CancelRequest: procedure(context: Integer); cdecl;
    CancelAllRequests: procedure; cdecl;
    AdrToString: function(const a: netadr_s): PAnsiChar; cdecl;
    CompareAdr: function(const a, b: netadr_s): Integer; cdecl;
    StringToAdr: function(s: PAnsiChar; var a: netadr_s): Integer; cdecl;
    ValueForKey: function(s: PAnsiChar; key: PAnsiChar): PAnsiChar; cdecl;
    RemoveKey: procedure(s: PAnsiChar; key: PAnsiChar); cdecl;
    SetValueForKey: procedure(s: PAnsiChar; key: PAnsiChar; value: PAnsiChar; maxsize: Integer); cdecl;
  end;
  net_api_t = net_api_s;

  TNetAPI = net_api_s;
  PNetAPI = ^net_api_s;

  IVoiceTweak_s = record
    // These turn voice tweak mode on and off. While in voice tweak mode, the user's voice is echoed back
    // without sending to the server.
    StartVoiceTweakMode: function: Integer; cdecl;	// Returns 0 on error.
    EndVoiceTweakMode: procedure; cdecl;

    // Get/set control values.
    SetControlFloat: procedure(iControl: VoiceTweakControl; value: Single); cdecl;
    GetControlFloat: function(iControl: VoiceTweakControl): Single; cdecl;

    GetSpeakingVolume: function: Integer; cdecl;
  end;
  IVoiceTweak = IVoiceTweak_s;

  TVoiceTweak = IVoiceTweak_s;
  PVoiceTweak = ^IVoiceTweak_s;

  particle_callback_t = procedure(const particle: particle_s; frametime: Single); cdecl;
  particle_hitcallback_t = procedure(const ent: tempent_s; const ptr: pmtrace_s); cdecl;
  particle_deathfunc_t = procedure(const particle: particle_s); cdecl;
  tempent_alloc_custom = procedure(const ent: tempent_s; frametime, currenttime: Single) cdecl;

  efx_api_s = record
    R_AllocParticle: function(callback: particle_callback_t): PParticle; cdecl;
    R_BlobExplosion: procedure(const org: vec3_t); cdecl;
    R_Blood: procedure(const org, dir: vec3_t; pcolor, speed: Integer); cdecl;
    R_BloodSprite: procedure(const org: vec3_t; colorindex, modelIndex, modelIndex2: Integer; size: Single); cdecl;
    R_BreakModel: procedure(const org, size, dir: vec3_t; random, life: Single; count, modelIndex: Integer; flags: ShortInt); cdecl;
    R_Bubbles: procedure(const mins, maxs: vec3_t; height: Single; modelIndex, count: Integer; speed: Single); cdecl;
    R_BubbleTrail: procedure(const start, &end: vec3_t; height: Single; modelIndex, count: Integer; speed: Single); cdecl;
    R_BulletImpactParticles: procedure(const pos: vec3_t); cdecl;
    R_EntityParticles: procedure(const ent: cl_entity_s); cdecl;
    R_Explosion: procedure(const pos: vec3_t; model: Integer; scale, framerate: Single; flags: Integer); cdecl;
    R_FizzEffect: procedure(const pent: cl_entity_s; modelIndex, density: Integer); cdecl;
    R_FireField: procedure(const org: vec3_t; radius, modelIndex, count, flags: Integer; life: Single); cdecl;
    R_FlickerParticles: procedure(const org: vec3_t); cdecl;
    R_FunnelSprite: procedure(const org: vec3_t; modelIndex, reverse: Integer); cdecl;
    R_Implosion: procedure(const &end: vec3_t; radius: Single; count: Integer; life: Single); cdecl;
    R_LargeFunnel: procedure(const org: vec3_t; reverse: Integer); cdecl;
    R_LavaSplash: procedure(const org: vec3_t); cdecl;
    R_MultiGunshot: procedure(const org, dir, noise: vec3_t; count, decalCount: Integer; decalIndices: PInteger); cdecl;
    R_MuzzleFlash: procedure(const pos1: vec3_t; &type: Integer); cdecl;
    R_ParticleBox: procedure(const mins, maxs: vec3_t; r, g, b: Byte; life: Single); cdecl;
    R_ParticleBurst: procedure(const pos: vec3_t; size, color: Integer; life: Single); cdecl;
    R_ParticleExplosion: procedure(const org: vec3_t); cdecl;
    R_ParticleExplosion2: procedure(const org: vec3_t; colorStart, colorLength: Integer); cdecl;
    R_ParticleLine: procedure(const start, &end: vec3_t; r, g, b: Byte; life: Single); cdecl;
    R_PlayerSprites: procedure(client, modelIndex, count, size: Integer); cdecl;
    R_Projectile: procedure(const origin: vec3_t; const velocity: vec3_t; modelIndex, life, owner: Integer; hitcallback: particle_hitcallback_t); cdecl;
    R_RicochetSound: procedure(const pos: vec3_t); cdecl;
    R_RicochetSprite: procedure(const pos: vec3_t; const pmodel: model_s; duration, scale: Single); cdecl;
    R_RocketFlare: procedure(const pos: vec3_t); cdecl;
    R_RocketTrail: procedure(const start, &end: vec3_t; &type: Integer); cdecl;
    R_RunParticleEffect: procedure(const org, dir: vec3_t; color, count: Integer); cdecl;
    R_ShowLine: procedure(const start, &end: vec3_t); cdecl;
    R_SparkEffect: procedure(const pos: vec3_t; count, velocityMin, velocityMax: Integer); cdecl;
    R_SparkShower: procedure(const pos: vec3_t); cdecl;
    R_SparkStreaks: procedure(const pos: vec3_t; count, velocityMin, velocityMax: Integer); cdecl;
    R_Spray: procedure(const pos, dir: vec3_t; modelIndex, count, speed, spread, rendermode: Integer); cdecl;
    R_Sprite_Explode: procedure(const pTemp: TEMPENTITY; scale: Single; flags: Integer); cdecl;
    R_Sprite_Smoke: procedure(const pTemp: TEMPENTITY; scale: Single); cdecl;
    R_Sprite_Spray: procedure(const pos, dir: vec3_t; modelIndex, count, speed, iRand: Integer); cdecl;
    R_Sprite_Trail: procedure(&type: Integer; const start, &end: vec3_t; modelIndex, count: Integer; life, size, amplitude: Single; renderamt: Integer; speed: Single); cdecl;
    R_Sprite_WallPuff: procedure(const pTemp: TEMPENTITY; scale: Single); cdecl;
    R_StreakSplash: procedure(const pos, dir: vec3_t; color, count: Integer; speed: Single; velocityMin, velocityMax: Integer); cdecl;
    R_TracerEffect: procedure(const start, &end: vec3_t); cdecl;
    R_UserTracerParticle: procedure(const org, vel: vec3_t; life: Single; colorIndex: Integer; length: Single; deathcontext: Byte; deathfunc: particle_deathfunc_t); cdecl;
    R_TracerParticles: function(const org, vel: vec3_t; life: Single): PParticle; cdecl;
    R_TeleportSplash: procedure(const org: vec3_t); cdecl;
    R_TempSphereModel: procedure(const pos: vec3_t; speed, life: Single; count, modelIndex: Integer); cdecl;
    R_TempModel: function(const pos, dir, angles: vec3_t; life: Single; modelIndex, soundtype: Integer): PTempEntity; cdecl;
    R_DefaultSprite: function(const pos: vec3_t; spriteIndex: Integer; framerate: Single): PTempEntity; cdecl;
    R_TempSprite: function(const pos, dir: vec3_t; scale: Single; modelIndex, rendermode, renderfx: Integer; a, life: Single; flags: Integer): PTempEntity; cdecl;
    Draw_DecalIndex: function(id: Integer): Integer; cdecl;
    Draw_DecalIndexFromName: function(Name: PAnsiChar): Integer; cdecl;
    R_DecalShoot: procedure(textureIndex, entity, modelIndex: Integer; const position: vec3_t; flags: Integer); cdecl;
    R_AttachTentToPlayer: procedure(client, modelIndex: Integer; zoffset, life: Single); cdecl;
    R_KillAttachedTents: procedure(client: Integer); cdecl;
    R_BeamCirclePoints: function(&type: Integer; const start, &end: vec3_t; modelIndex: Integer; life: Single; width, amplitude, brightness, speed: Single; startFrame: Integer; framerate, r, g, b: Single): PBeam; cdecl;
    R_BeamEntPoint: function(startEnt: Integer; const &end: vec3_t; modelIndex: Integer; life, width, amplitude, brightness, speed: Single; startFrame: Integer; framerate, r, g, b: Single): PBeam; cdecl;
    R_BeamEnts: function(startEnt, endEnt, modelIndex: Integer; life, width, amplitude, brightness, speed: Single; startFrame: Integer; framerate, r, g, b: Single): PBeam; cdecl;
    R_BeamFollow: function(startEnt: Integer; modelIndex: Integer; life, width, r, g, b, brightness: Single): PBeam; cdecl;
    R_BeamKill: procedure(deadEntity: Integer); cdecl;
    R_BeamLightning: function(const start, &end: vec3_t; modelIndex: Integer; life, width, amplitude, brightness, speed: Single): PBeam; cdecl;
    R_BeamPoints: function(const start, &end: vec3_t; modelIndex: Integer; life, width, amplitude, brightness, speed: Single; startFrame: Integer; framerate, r, g, b: Single): PBeam; cdecl;
    R_BeamRing: function(startEnt, endEnt, modelIndex: Integer; life, width, amplitude, brightness, speed: Single; startFrame: Integer; framerate, r, g, b: Single): PBeam; cdecl;
    CL_AllocDlight: function(key: Integer): PDLight; cdecl;
    CL_AllocElight: function(key: Integer): PDLight; cdecl;
    CL_TempEntAlloc: function(const org: vec3_t; const model: model_s): PTempEntity; cdecl;
    CL_TempEntAllocNoModel: function(const org: vec3_t): PTempEntity; cdecl;
    CL_TempEntAllocHigh: function(const org: vec3_t; const model: model_s): PTempEntity; cdecl;
    CL_TentEntAllocCustom: function(const origin: vec3_t; const model: model_s; high: Integer; callback: tempent_alloc_custom): PTempEntity; cdecl;
    R_GetPackedColor: procedure(&packed: PSmallint; color: Smallint); cdecl;
    R_LookupColor: function(r, g, b: Byte): Integer; cdecl;
    R_DecalRemoveAll: procedure(textureIndex: Integer); //textureIndex points to the decal index in the array, not the actual texture index.
    R_FireCustomDecal: procedure(textureIndex, entity, modelIndex: Integer; const position: vec3_t; flags: Integer; scale: Single); cdecl;
  end;
  efx_api_t = efx_api_s;

  TEfxAPI = efx_api_s;
  PEfxAPI = ^efx_api_s;

  con_nprint_s = record
    index: Integer;			          // Row #
    time_to_live: Single;	        // # of seconds before it dissappears
    color: array[0..2] of Single;	// RGB colors ( 0.0 -> 1.0 scale )
  end;
  con_nprint_t = con_nprint_s;

  TConNPrint = con_nprint_s;
  PConNPrint = ^con_nprint_s;

  client_sprite_s = record
    szName: array[0..63] of AnsiChar;
    szSprite: array[0..63] of AnsiChar;
    hspr: Integer;
    iRes: Integer;
    rc: wrect_t;
  end;
  client_sprite_t = client_sprite_s;

  TClientSprite = client_sprite_s;
  PClientSprite = ^client_sprite_s;

  client_textmessage_s = record
    effect: Integer;
    r1, g1, b1, a1: Byte;		// 2 colors for effects
    r2, g2, b2, a2: Byte;
    x: Single;
    y: Single;
    fadein: Single;
    fadeout: Single;
    holdtime: Single;
    fxtime: Single;
    pName: PAnsiChar;
    pMessage: PAnsiChar;
  end;
  client_textmessage_t = client_textmessage_s;

  TClientTextMessage = client_textmessage_s;
  PClientTextMessage = ^client_textmessage_s;

  //---------------------------------------------------------------------------
  // sequenceCommandLine_s
  //
  // Structure representing a single command (usually 1 line) from a
  //	.SEQ file entry.
  //---------------------------------------------------------------------------
  sequenceCommandLine_ = record
    commandType: Integer;		                // Specifies the type of command
    clientMessage: client_textmessage_t;    // Text HUD message struct
    speakerName: PAnsiChar;                 // Targetname of speaking entity
    listenerName: PAnsiChar;                // Targetname of entity being spoken to
    soundFileName: PAnsiChar;               // Name of sound file to play
    sentenceName: PAnsiChar;                // Name of sentences.txt to play
    fireTargetNames: PAnsiChar;             // List of targetnames to fire
    killTargetNames: PAnsiChar;             // List of targetnames to remove
    delay: Single;                          // Seconds 'till next command
    repeatCount: Integer;                   // If nonzero, reset execution pointer to top of block (N times, -1 = infinite)
    textChannel: Integer;                   // Display channel on which text message is sent
    modifierBitField: Integer;	            // Bit field to specify what clientmessage fields are valid
    nextCommandLine: ^sequenceCommandLine_;	// Next command (linked list)
  end;
  sequenceCommandLine_s = sequenceCommandLine_;

  TSequenceCommandLine = sequenceCommandLine_;
  PSequenceCommandLine = ^sequenceCommandLine_;

  //---------------------------------------------------------------------------
  // sequenceEntry_s
  //
  // Structure representing a single command (usually 1 line) from a
  //	.SEQ file entry.
  //---------------------------------------------------------------------------
  sequenceEntry_ = record
    fileName: PAnsiChar;                  // Name of sequence file without .SEQ extension
    entryName: PAnsiChar;		              // Name of entry label in file
    firstCommand: ^sequenceCommandLine_;  // Linked list of commands in entry
    nextEntry: ^sequenceEntry_;           // Next loaded entry
    isGlobal: qboolean;                   // Is entry retained over level transitions?
  end;
  sequenceEntry_s = sequenceEntry_;

  TSequenceEntry = sequenceEntry_;
  PSequenceEntry = ^sequenceEntry_;

  //---------------------------------------------------------------------------
  // sentenceEntry_s
  // Structure representing a single sentence of a group from a .SEQ
  // file entry.  Sentences are identical to entries in sentences.txt, but
  // can be unique per level and are loaded/unloaded with the level.
  //---------------------------------------------------------------------------
  sentenceEntry_ = record
    data: PAnsiChar;			        // sentence data (ie "We have hostiles" )
    nextEntry: ^sentenceEntry_;		// Next loaded entry
    isGlobal: qboolean;		        // Is entry retained over level transitions?
    index: Cardinal;			        // this entry's position in the file.
  end;
  sentenceEntry_s = sentenceEntry_;

  TSentenceEntry = sentenceEntry_;
  PSentenceEntry = ^sentenceEntry_;

  POINT_s = record
    x, y: Integer;
  end;
  POINT = POINT_s;

  TPoint = POINT_s;
  PPoint = ^POINT_s;

  pfnEngSrc_Callback_t = procedure; cdecl;
  pfnEvent_Callback_t = procedure(const args: event_args_s); cdecl;

  pfnEngDst_pfnSPR_Load_t = procedure(var szPicName: PAnsiChar); cdecl;
  pfnEngDst_pfnSPR_Frames_t = procedure(var hPic: HSPRITE); cdecl;
  pfnEngDst_pfnSPR_Height_t = procedure(var hPic: HSPRITE; var frame: Integer); cdecl;
  pfnEngDst_pfnSPR_Width_t = procedure(var hPic: HSPRITE; var frame: Integer); cdecl;
  pfnEngDst_pfnSPR_Set_t = procedure(var hPic: HSPRITE; var r, g, b: Integer); cdecl;
  pfnEngDst_pfnSPR_Draw_t = procedure(var frame: Integer; var x, y: Integer; var prc: PWRect); cdecl;
  pfnEngDst_pfnSPR_DrawHoles_t = procedure(var frame: Integer; var x, y: Integer; var prc: PWRect); cdecl;
  pfnEngDst_pfnSPR_DrawAdditive_t = procedure(var frame, x, y: Integer; var prc: PWRect); cdecl;
  pfnEngDst_pfnSPR_EnableScissor_t = procedure(var x, y, width, height: Integer); cdecl;
  pfnEngDst_pfnSPR_DisableScissor_t = procedure; cdecl;
  pfnEngDst_pfnSPR_GetList_t = procedure(var psz: PAnsiChar; var piCount: PInteger); cdecl;
  pfnEngDst_pfnFillRGBA_t = procedure(var x, y, width, height, r, g, b, a: Integer); cdecl;
  pfnEngDst_pfnGetScreenInfo_t = procedure(var pscrinfo: PScreenInfo); cdecl;
  pfnEngDst_pfnSetCrosshair_t = procedure(var hspr: HSPRITE; var rc: wrect_t; var r, g, b: Integer); cdecl;
  pfnEngDst_pfnRegisterVariable_t = procedure(var szName, szValue: PAnsiChar; var flags: Integer); cdecl;
  pfnEngDst_pfnGetCvarFloat_t = procedure(var szName: PAnsiChar); cdecl;
  pfnEngDst_pfnGetCvarString_t = procedure(var szName: PAnsiChar); cdecl;
  pfnEngDst_pfnAddCommand_t = procedure(var cmd_name: PAnsiChar; var pfnEngSrc_function: pfnEngSrc_Callback_t); cdecl;
  pfnEngDst_pfnHookUserMsg_t = procedure(var szMsgName: PAnsiChar; var pfn: pfnUserMsgHook); cdecl;
  pfnEngDst_pfnServerCmd_t = procedure(var szCmdString: PAnsiChar); cdecl;
  pfnEngDst_pfnClientCmd_t = procedure(var szCmdString: PAnsiChar); cdecl;
  pfnEngDst_pfnPrimeMusicStream_t = procedure(var szFilename: PAnsiChar; var looping: Integer); cdecl;
  pfnEngDst_pfnGetPlayerInfo_t = procedure(var ent_num: Integer; var pinfo: PHudPlayerInfo); cdecl;
  pfnEngDst_pfnPlaySoundByName_t = procedure(var szSound: PAnsiChar; var volume: Single); cdecl;
  pfnEngDst_pfnPlaySoundByNameAtPitch_t = procedure(var szSound: PAnsiChar; var volume: Single; var pitch: Integer); cdecl;
  pfnEngDst_pfnPlaySoundVoiceByName_t = procedure(var szSound: PAnsiChar; var volume: Single; var pitch: Integer); cdecl;
  pfnEngDst_pfnPlaySoundByIndex_t = procedure(var iSound: Integer; var volume: Single); cdecl;
  pfnEngDst_pfnAngleVectors_t = procedure(var vecAngles: Single; var &forward, right, up: PVec3); cdecl;
  pfnEngDst_pfnTextMessageGet_t = procedure(var pName: PAnsiChar); cdecl;
  pfnEngDst_pfnDrawCharacter_t = procedure(var x, y, number, r, g, b: Integer); cdecl;
  pfnEngDst_pfnDrawConsoleString_t = procedure(var x, y: Integer; var &string: PAnsiChar); cdecl;
  pfnEngDst_pfnDrawSetTextColor_t = procedure(var r, g, b: Single); cdecl;
  pfnEngDst_pfnDrawConsoleStringLen_t = procedure(var &string: PAnsiChar; var width, height: Integer); cdecl;
  pfnEngDst_pfnConsolePrint_t = procedure(var &string: PAnsiChar); cdecl;
  pfnEngDst_pfnCenterPrint_t = procedure(var &string: PAnsiChar); cdecl;
  pfnEngDst_GetWindowCenterX_t = procedure; cdecl;
  pfnEngDst_GetWindowCenterY_t = function: Integer; cdecl;
  pfnEngDst_GetViewAngles_t = procedure(var va: PVec3); cdecl;
  pfnEngDst_SetViewAngles_t = procedure(var va: PVec3); cdecl;
  pfnEngDst_GetMaxClients_t = procedure; cdecl;
  pfnEngDst_Cvar_SetValue_t = procedure(var cvar: PAnsiChar; var value: Single); cdecl;
  pfnEngDst_Cmd_Argc_t = procedure; cdecl;
  pfnEngDst_Cmd_Argv_t = procedure(var arg: Integer); cdecl;
  pfnEngDst_Con_Printf_t = procedure(var fmt: PAnsiChar); cdecl varargs;
  pfnEngDst_Con_DPrintf_t = procedure(var fmt: PAnsiChar); cdecl varargs;
  pfnEngDst_Con_NPrintf_t = procedure(var pos: Integer; var fmt: PAnsiChar); cdecl varargs;
  pfnEngDst_Con_NXPrintf_t = procedure(var info: PConNPrint; var fmt: PAnsiChar); cdecl varargs;
  pfnEngDst_PhysInfo_ValueForKey_t = procedure(var key: PAnsiChar); cdecl;
  pfnEngDst_ServerInfo_ValueForKey_t = procedure(var key: PAnsiChar); cdecl;
  pfnEngDst_GetClientMaxspeed_t = function: Single; cdecl;
  pfnEngDst_CheckParm_t = procedure(var parm: PAnsiChar; var ppnext: PPAnsiChar); cdecl;
  pfnEngDst_Key_Event_t = procedure(var key, down: Integer); cdecl;
  pfnEngDst_GetMousePosition_t = procedure(var mx, my: Integer); cdecl;
  pfnEngDst_IsNoClipping_t = procedure; cdecl;
  pfnEngDst_GetLocalPlayer_t = procedure; cdecl;
  pfnEngDst_GetViewModel_t = procedure; cdecl;
  pfnEngDst_GetEntityByIndex_t = procedure(var idx: Integer); cdecl;
  pfnEngDst_GetClientTime_t = procedure; cdecl;
  pfnEngDst_V_CalcShake_t = procedure; cdecl;
  pfnEngDst_V_ApplyShake_t = procedure(var origin, angles: PVec3; var factor: Single); cdecl;
  pfnEngDst_PM_PointContents_t = procedure(var point: PVec3; var truecontents: Integer); cdecl;
  pfnEngDst_PM_WaterEntity_t = procedure(var p: PVec3); cdecl;
  pfnEngDst_PM_TraceLine_t = procedure(var start, &end: PVec3; var flags, usehull, ignore_pe: Integer); cdecl;
  pfnEngDst_CL_LoadModel_t = procedure(var modelname: PAnsiChar; var index: Integer); cdecl;
  pfnEngDst_CL_CreateVisibleEntity_t = procedure(var &type: Integer; var ent: PCLEntity); cdecl;
  pfnEngDst_GetSpritePointer_t = procedure(var hSprite: HSPRITE); cdecl;
  pfnEngDst_pfnPlaySoundByNameAtLocation_t = procedure(var szSound: PAnsiChar; var volume: Single; var origin: PVec3); cdecl;
  pfnEngDst_pfnPrecacheEvent_t = function(var &type: Integer; var psz: PAnsiChar): Word; cdecl;
  pfnEngDst_pfnPlaybackEvent_t = procedure(var flags: Integer; var pInvoker: PEdict; var eventindex: Word; var delay: Single; var origin, angles: PVec3; var fparam1, fparam2: Single; var iparam1, iparam2: Integer; var bparam1, bparam2: Integer); cdecl;
  pfnEngDst_pfnWeaponAnim_t = procedure(var iAnim, body: Integer); cdecl;
  pfnEngDst_pfnRandomFloat_t = procedure(var flLow, flHigh: Single); cdecl;
  pfnEngDst_pfnRandomLong_t = procedure(var lLow, lHigh: Longint); cdecl;
  pfnEngDst_pfnHookEvent_t = procedure(var name: PAnsiChar; var pfnEvent: pfnEvent_Callback_t); cdecl;
  pfnEngDst_Con_IsVisible_t = procedure; cdecl;
  pfnEngDst_pfnGetGameDirectory_t = procedure; cdecl;
  pfnEngDst_pfnGetCvarPointer_t = procedure(var szName: PAnsiChar); cdecl;
  pfnEngDst_Key_LookupBinding_t = procedure(var pBinding: PAnsiChar); cdecl;
  pfnEngDst_pfnGetLevelName_t = procedure; cdecl;
  pfnEngDst_pfnGetScreenFade_t = procedure(var fade: PScreenFade); cdecl;
  pfnEngDst_pfnSetScreenFade_t = procedure(var fade: PScreenFade); cdecl;
  pfnEngDst_VGui_GetPanel_t = procedure; cdecl;
  pfnEngDst_VGui_ViewportPaintBackground_t = procedure(var extents: PInteger); cdecl;
  pfnEngDst_COM_LoadFile_t = procedure(var path: PAnsiChar; var usehunk: Integer; var pLength: PInteger); cdecl;
  pfnEngDst_COM_ParseFile_t = procedure(var data, token: PAnsiChar); cdecl;
  pfnEngDst_COM_FreeFile_t = procedure(var buffer: Pointer); cdecl;
  pfnEngDst_IsSpectateOnly_t = procedure; cdecl;
  pfnEngDst_LoadMapSprite_t = procedure(var filename: PAnsiChar); cdecl;
  pfnEngDst_COM_AddAppDirectoryToSearchPath_t = procedure(var pszBaseDir, appName: PAnsiChar); cdecl;
  pfnEngDst_COM_ExpandFilename_t = procedure(var fileName: PAnsiChar; var nameOutBuffer: PAnsiChar; var nameOutBufferSize: Integer); cdecl;
  pfnEngDst_PlayerInfo_ValueForKey_t = procedure(var playerNum: Integer; var key: PAnsiChar); cdecl;
  pfnEngDst_PlayerInfo_SetValueForKey_t = procedure(var key, value: PAnsiChar); cdecl;
  pfnEngDst_GetPlayerUniqueID_t = procedure(var iPlayer: Integer; var playerID: PAnsiChar); cdecl;
  pfnEngDst_GetTrackerIDForPlayer_t = procedure(var playerSlot: Integer); cdecl;
  pfnEngDst_GetPlayerForTrackerID_t = procedure(var trackerID: Integer); cdecl;
  pfnEngDst_pfnServerCmdUnreliable_t = procedure(var szCmdString: PAnsiChar); cdecl;
  pfnEngDst_GetMousePos_t = procedure(var ppt: PPoint); cdecl;
  pfnEngDst_SetMousePos_t = procedure(var x, y: Integer); cdecl;
  pfnEngDst_SetMouseEnable_t = procedure(var fEnable: qboolean); cdecl;
  pfnEngDst_GetFirstCVarPtr_t = procedure; cdecl;
  pfnEngDst_GetFirstCmdFunctionHandle_t = procedure; cdecl;
  pfnEngDst_GetNextCmdFunctionHandle_t = procedure; cdecl;
  pfnEngDst_GetCmdFunctionName_t = procedure(var cmdhandle: PCmdFunction); cdecl;
  pfnEngDst_GetClientOldTime_t = procedure; cdecl;
  pfnEngDst_GetServerGravityValue_t = procedure; cdecl;
  pfnEngDst_GetModelByIndex_t = procedure(var index: Integer); cdecl;
  pfnEngDst_pfnSetFilterMode_t = procedure(var mode: Integer); cdecl;
  pfnEngDst_pfnSetFilterColor_t = procedure(var r, g, b: Single); cdecl;
  pfnEngDst_pfnSetFilterBrightness_t = procedure(var brightness: Single); cdecl;
  pfnEngDst_pfnSequenceGet_t = procedure(var fileName, entryName: PAnsiChar); cdecl;
  pfnEngDst_pfnSPR_DrawGeneric_t = procedure(var frame, x, y: Integer; var prc: PWRect; var src, dest, w, h: Integer); cdecl;
  pfnEngDst_pfnSequencePickSentence_t = procedure(var sentenceName: PAnsiChar; var pickMethod: Integer; var entryPicked: PInteger); cdecl;
  pfnEngDst_pfnDrawString_t = procedure(var x, y: Integer; var str: PAnsiChar; var r, g, b: Integer); cdecl;
  pfnEngDst_pfnDrawStringReverse_t = procedure(var x, y: Integer; var str: PAnsiChar; var r, g, b: Integer); cdecl;
  pfnEngDst_LocalPlayerInfo_ValueForKey_t = procedure(var key: PAnsiChar); cdecl;
  pfnEngDst_pfnVGUI2DrawCharacter_t = procedure(var x, y, ch: Integer; var font: Cardinal); cdecl;
  pfnEngDst_pfnVGUI2DrawCharacterAdd_t = procedure(var x, y, ch, r, g, b: Integer; var font: Cardinal); cdecl;
  pfnEngDst_COM_GetApproxWavePlayLength = procedure(var filename: PAnsiChar); cdecl;
  pfnEngDst_pfnGetCareerUI_t = procedure; cdecl;
  pfnEngDst_Cvar_Set_t = procedure(var cvar: PAnsiChar; var value: PAnsiChar); cdecl;
  pfnEngDst_pfnIsPlayingCareerMatch_t = procedure; cdecl;
  pfnEngDst_GetAbsoluteTime_t = procedure; cdecl;
  pfnEngDst_pfnProcessTutorMessageDecayBuffer_t = procedure(var buffer: Pointer; var bufferLength: Integer); cdecl;
  pfnEngDst_pfnConstructTutorMessageDecayBuffer_t = procedure(var buffer: Pointer; var bufferLength: Integer); cdecl;
  pfnEngDst_pfnResetTutorMessageDecayData_t = procedure; cdecl;
  pfnEngDst_pfnFillRGBABlend_t = procedure(var x, y, width, height, r, g, b, a: Integer); cdecl;
  pfnEngDst_pfnGetAppID_t = procedure; cdecl;
  pfnEngDst_pfnGetAliases_t = procedure; cdecl;
  pfnEngDst_pfnVguiWrap2_GetMouseDelta_t = procedure(var x, y: PInteger); cdecl;
  pfnEngDst_pfnFilteredClientCmd_t = procedure(var pszCmdString: PAnsiChar); cdecl;

  cl_enginefunc_dst_t = record
    pfnSPR_Load: pfnEngDst_pfnSPR_Load_t;
    pfnSPR_Frames: pfnEngDst_pfnSPR_Frames_t;
    pfnSPR_Height: pfnEngDst_pfnSPR_Height_t;
    pfnSPR_Width: pfnEngDst_pfnSPR_Width_t;
    pfnSPR_Set: pfnEngDst_pfnSPR_Set_t;
    pfnSPR_Draw: pfnEngDst_pfnSPR_Draw_t;
    pfnSPR_DrawHoles: pfnEngDst_pfnSPR_DrawHoles_t;
    pfnSPR_DrawAdditive: pfnEngDst_pfnSPR_DrawAdditive_t;
    pfnSPR_EnableScissor: pfnEngDst_pfnSPR_EnableScissor_t;
    pfnSPR_DisableScissor: pfnEngDst_pfnSPR_DisableScissor_t;
    pfnSPR_GetList: pfnEngDst_pfnSPR_GetList_t;
    pfnFillRGBA: pfnEngDst_pfnFillRGBA_t;
    pfnGetScreenInfo: pfnEngDst_pfnGetScreenInfo_t;
    pfnSetCrosshair: pfnEngDst_pfnSetCrosshair_t;
    pfnRegisterVariable: pfnEngDst_pfnRegisterVariable_t;
    pfnGetCvarFloat: pfnEngDst_pfnGetCvarFloat_t;
    pfnGetCvarString: pfnEngDst_pfnGetCvarString_t;
    pfnAddCommand: pfnEngDst_pfnAddCommand_t;
    pfnHookUserMsg: pfnEngDst_pfnHookUserMsg_t;
    pfnServerCmd: pfnEngDst_pfnServerCmd_t;
    pfnClientCmd: pfnEngDst_pfnClientCmd_t;
    pfnGetPlayerInfo: pfnEngDst_pfnGetPlayerInfo_t;
    pfnPlaySoundByName: pfnEngDst_pfnPlaySoundByName_t;
    pfnPlaySoundByIndex: pfnEngDst_pfnPlaySoundByIndex_t;
    pfnAngleVectors: pfnEngDst_pfnAngleVectors_t;
    pfnTextMessageGet: pfnEngDst_pfnTextMessageGet_t;
    pfnDrawCharacter: pfnEngDst_pfnDrawCharacter_t;
    pfnDrawConsoleString: pfnEngDst_pfnDrawConsoleString_t;
    pfnDrawSetTextColor: pfnEngDst_pfnDrawSetTextColor_t;
    pfnDrawConsoleStringLen: pfnEngDst_pfnDrawConsoleStringLen_t;
    pfnConsolePrint: pfnEngDst_pfnConsolePrint_t;
    pfnCenterPrint: pfnEngDst_pfnCenterPrint_t;
    GetWindowCenterX: pfnEngDst_GetWindowCenterX_t;
    GetWindowCenterY: pfnEngDst_GetWindowCenterY_t;
    GetViewAngles: pfnEngDst_GetViewAngles_t;
    SetViewAngles: pfnEngDst_SetViewAngles_t;
    GetMaxClients: pfnEngDst_GetMaxClients_t;
    Cvar_SetValue: pfnEngDst_Cvar_SetValue_t;
    Cmd_Argc: pfnEngDst_Cmd_Argc_t;
    Cmd_Argv: pfnEngDst_Cmd_Argv_t;
    Con_Printf: pfnEngDst_Con_Printf_t;
    Con_DPrintf: pfnEngDst_Con_DPrintf_t;
    Con_NPrintf: pfnEngDst_Con_NPrintf_t;
    Con_NXPrintf: pfnEngDst_Con_NXPrintf_t;
    PhysInfo_ValueForKey: pfnEngDst_PhysInfo_ValueForKey_t;
    ServerInfo_ValueForKey: pfnEngDst_ServerInfo_ValueForKey_t;
    GetClientMaxspeed: pfnEngDst_GetClientMaxspeed_t;
    CheckParm: pfnEngDst_CheckParm_t;
    Key_Event: pfnEngDst_Key_Event_t;
    GetMousePosition: pfnEngDst_GetMousePosition_t;
    IsNoClipping: pfnEngDst_IsNoClipping_t;
    GetLocalPlayer: pfnEngDst_GetLocalPlayer_t;
    GetViewModel: pfnEngDst_GetViewModel_t;
    GetEntityByIndex: pfnEngDst_GetEntityByIndex_t;
    GetClientTime: pfnEngDst_GetClientTime_t;
    V_CalcShake: pfnEngDst_V_CalcShake_t;
    V_ApplyShake: pfnEngDst_V_ApplyShake_t;
    PM_PointContents: pfnEngDst_PM_PointContents_t;
    PM_WaterEntity: pfnEngDst_PM_WaterEntity_t;
    PM_TraceLine: pfnEngDst_PM_TraceLine_t;
    CL_LoadModel: pfnEngDst_CL_LoadModel_t;
    CL_CreateVisibleEntity: pfnEngDst_CL_CreateVisibleEntity_t;
    GetSpritePointer: pfnEngDst_GetSpritePointer_t;
    pfnPlaySoundByNameAtLocation: pfnEngDst_pfnPlaySoundByNameAtLocation_t;
    pfnPrecacheEvent: pfnEngDst_pfnPrecacheEvent_t;
    pfnPlaybackEvent: pfnEngDst_pfnPlaybackEvent_t;
    pfnWeaponAnim: pfnEngDst_pfnWeaponAnim_t;
    pfnRandomFloat: pfnEngDst_pfnRandomFloat_t;
    pfnRandomLong: pfnEngDst_pfnRandomLong_t;
    pfnHookEvent: pfnEngDst_pfnHookEvent_t;
    Con_IsVisible: pfnEngDst_Con_IsVisible_t;
    pfnGetGameDirectory: pfnEngDst_pfnGetGameDirectory_t;
    pfnGetCvarPointer: pfnEngDst_pfnGetCvarPointer_t;
    Key_LookupBinding: pfnEngDst_Key_LookupBinding_t;
    GetLevelName: pfnEngDst_pfnGetLevelName_t;
    pfnGetScreenFade: pfnEngDst_pfnGetScreenFade_t;
    pfnSetScreenFade: pfnEngDst_pfnSetScreenFade_t;
    VGui_GetPanel: pfnEngDst_VGui_GetPanel_t;
    VGui_ViewportPaintBackground: pfnEngDst_VGui_ViewportPaintBackground_t;
    COM_LoadFile: pfnEngDst_COM_LoadFile_t;
    COM_ParseFile: pfnEngDst_COM_ParseFile_t;
    COM_FreeFile: pfnEngDst_COM_FreeFile_t;

    pTriAPI: ^triangleapi_s;
    pEfxAPI: ^efx_api_s;
    pEventAPI: ^event_api_s;
    pDemoAPI: ^demo_api_s;
    pNetAPI: ^net_api_s;
    pVoiceTweak: ^IVoiceTweak_s;

    IsSpectateOnly: pfnEngDst_IsSpectateOnly_t;
    LoadMapSprite: pfnEngDst_LoadMapSprite_t;
    COM_AddAppDirectoryToSearchPath: pfnEngDst_COM_AddAppDirectoryToSearchPath_t;
    COM_ExpandFilename: pfnEngDst_COM_ExpandFilename_t;
    PlayerInfo_ValueForKey: pfnEngDst_PlayerInfo_ValueForKey_t;
    PlayerInfo_SetValueForKey: pfnEngDst_PlayerInfo_SetValueForKey_t;
    GetPlayerUniqueID: pfnEngDst_GetPlayerUniqueID_t;
    GetTrackerIDForPlayer: pfnEngDst_GetTrackerIDForPlayer_t;
    GetPlayerForTrackerID: pfnEngDst_GetPlayerForTrackerID_t;
    pfnServerCmdUnreliable: pfnEngDst_pfnServerCmdUnreliable_t;
    pfnGetMousePos: pfnEngDst_GetMousePos_t;
    pfnSetMousePos: pfnEngDst_SetMousePos_t;
    pfnSetMouseEnable: pfnEngDst_SetMouseEnable_t;
    GetFirstCvarPtr: pfnEngDst_GetFirstCVarPtr_t;
    GetFirstCmdFunctionHandle: pfnEngDst_GetFirstCmdFunctionHandle_t;
    GetNextCmdFunctionHandle: pfnEngDst_GetNextCmdFunctionHandle_t;
    GetCmdFunctionName: pfnEngDst_GetCmdFunctionName_t;
    hudGetClientOldTime: pfnEngDst_GetClientOldTime_t;
    hudGetServerGravityValue: pfnEngDst_GetServerGravityValue_t;
    hudGetModelByIndex: pfnEngDst_GetModelByIndex_t;
    pfnSetFilterMode: pfnEngDst_pfnSetFilterMode_t;
    pfnSetFilterColor: pfnEngDst_pfnSetFilterColor_t;
    pfnSetFilterBrightness: pfnEngDst_pfnSetFilterBrightness_t;
    pfnSequenceGet: pfnEngDst_pfnSequenceGet_t;
    pfnSPR_DrawGeneric: pfnEngDst_pfnSPR_DrawGeneric_t;
    pfnSequencePickSentence: pfnEngDst_pfnSequencePickSentence_t;
    pfnDrawString: pfnEngDst_pfnDrawString_t;
    pfnDrawStringReverse: pfnEngDst_pfnDrawStringReverse_t;
    LocalPlayerInfo_ValueForKey: pfnEngDst_LocalPlayerInfo_ValueForKey_t;
    pfnVGUI2DrawCharacter: pfnEngDst_pfnVGUI2DrawCharacter_t;
    pfnVGUI2DrawCharacterAdd: pfnEngDst_pfnVGUI2DrawCharacterAdd_t;
    COM_GetApproxWavePlayLength: pfnEngDst_COM_GetApproxWavePlayLength;
    pfnGetCareerUI: pfnEngDst_pfnGetCareerUI_t;
    Cvar_Set: pfnEngDst_Cvar_Set_t;
    pfnIsCareerMatch: pfnEngDst_pfnIsPlayingCareerMatch_t;
    pfnPlaySoundVoiceByName: pfnEngDst_pfnPlaySoundVoiceByName_t;
    pfnPrimeMusicStream: pfnEngDst_pfnPrimeMusicStream_t;
    GetAbsoluteTime: pfnEngDst_GetAbsoluteTime_t;
    pfnProcessTutorMessageDecayBuffer: pfnEngDst_pfnProcessTutorMessageDecayBuffer_t;
    pfnConstructTutorMessageDecayBuffer: pfnEngDst_pfnConstructTutorMessageDecayBuffer_t;
    pfnResetTutorMessageDecayData: pfnEngDst_pfnResetTutorMessageDecayData_t;
    pfnPlaySoundByNameAtPitch: pfnEngDst_pfnPlaySoundByNameAtPitch_t;
    pfnFillRGBABlend: pfnEngDst_pfnFillRGBABlend_t;
    pfnGetAppID: pfnEngDst_pfnGetAppID_t;
    pfnGetAliasList: pfnEngDst_pfnGetAliases_t;
    pfnVguiWrap2_GetMouseDelta: pfnEngDst_pfnVguiWrap2_GetMouseDelta_t;
    pfnFilteredClientCmd: pfnEngDst_pfnFilteredClientCmd_t;
  end;

  TCLEngineFuncDst = cl_enginefunc_dst_t;
  PCLEngineFuncDst = ^cl_enginefunc_dst_t;

  glpoly_s = record
    next: ^glpoly_s;
    chain: ^glpoly_s;
    numverts: Integer;
    flags: Integer;
    verts: array[0..3] of array[0..6] of Single;
  end;
  glpoly_t = glpoly_s;

  TGLPoly = glpoly_s;
  PGLPoly = ^glpoly_s;

  server_state_t =
  (
    ss_dead = 0,
    ss_loading,
    ss_active
  );

  TServerState = server_state_t;

  extra_baselines_s = record
    number: Integer;
    classname: array[0..NUM_BASELINES - 1] of Integer;
    baseline: array[0..NUM_BASELINES - 1] of entity_state_t;
  end;
  extra_baselines_t = extra_baselines_s;

  TExtraBaselines = extra_baselines_s;
  PExtraBaselines = ^extra_baselines_s;

  // @xref: Host_ShutdownServer
  server_t = record
    active: qboolean;
    paused: qboolean;
    loadgame: qboolean;
    time: Double;
    oldtime: Double;
    lastcheck: Integer;
    lastchecktime: Double;
    name: array[0..63] of AnsiChar;
    oldname: array[0..63] of AnsiChar;
    startspot: array[0..63] of AnsiChar;
    modelname: array[0..63] of AnsiChar;
    worldmodel: ^model_s;
    worldmapCRC: CRC32_t;
    clientdllmd5: array[0..15] of Byte;
    resourcelist: array[0..MAX_RESOURCE_LIST - 1] of resource_s;
    num_resources: Integer;
    consistency_list: array[0..MAX_CONSISTENCY_LIST - 1] of consistency_s;
    num_consistency: Integer;
    model_precache: array[0..MAX_MODELS - 1] of PAnsiChar;
    models: array[0..MAX_MODELS - 1] of ^model_s;
    model_precache_flags: array[0..MAX_MODELS - 1] of Byte;
    event_precache: array[0..MAX_EVENTS - 1] of event_s;
    sound_precache: array[0..MAX_SOUNDS - 1] of PAnsiChar;
    sound_precache_hashedlookup: array[0..MAX_SOUNDS_HASHLOOKUP_SIZE - 1] of Smallint;
    sound_precache_hashedlookup_built: qboolean;
    generic_precache: array[0..MAX_GENERIC - 1] of PAnsiChar;
    generic_precache_names: array [0..MAX_GENERIC - 1] of array[0..63] of AnsiChar;
    num_generic_names: Integer;
    lightstyles: array[0..MAX_LIGHTSTYLES - 1] of PAnsiChar;
    num_edicts: Integer;
    max_edicts: Integer;
    edicts: ^edict_s;
    baselines: ^entity_state_s;
    instance_baselines: ^extra_baselines_s;
    state: server_state_t;
    datagram: sizebuf_s;
    datagram_buf: array[0..MAX_DATAGRAM - 1] of Byte;
    reliable_datagram: sizebuf_s;
    reliable_datagram_buf: array[0..MAX_DATAGRAM - 1] of Byte;
    multicast: sizebuf_s;
    multicast_buf: array[0..1023] of Byte;
    spectator: sizebuf_s;
    spectator_buf: array[0..1023] of Byte;
    signon: sizebuf_s;
    signon_data: array[0..32767] of Byte;
  end;

  TServer = server_t;
  PServer = ^server_t;
  {$IF SizeOf(TServer) <> 287768} {$MESSAGE WARN 'Structure size mismatch @ TServer.'} {$DEFINE MSME} {$IFEND}

  _resourceinfo_t = record
    size: Integer;
  end;

  resourceinfo_s = record
  	info: array[0..Ord(rt_max) - 1] of _resourceinfo_t;
  end;
  resourceinfo_t = resourceinfo_s;

  TResourceInfo = resourceinfo_s;
  PResourceInfo = ^resourceinfo_s;

  // @note: cachepic_t in rehlds
  cacheentry_s = record
    name: array[0..63] of AnsiChar;
    cache: cache_user_s;
  end;
  cacheentry_t = cacheentry_s;

  TCacheEntry = cacheentry_s;
  PCacheEntry = ^cacheentry_s;

  lumpinfo_s = record
    filepos: Integer;
    disksize: Integer;
    size: Integer;
    &type: AnsiChar;
    compression: AnsiChar;
    pad1, pad2: AnsiChar;
    name: array[0..15] of AnsiChar;
  end;
  lumpinfo_t = lumpinfo_s;

  TLumpInfo = lumpinfo_s;
  PLumpInfo = ^lumpinfo_s;

  PFNCACHE = procedure(wad: Pointer {cachewad_t}; data: PByte); cdecl;

  cachewad_s = record
    name: PAnsiChar;
    cache: ^cacheentry_s;
    cacheCount: Integer;
    cacheMax: Integer;
    lumps: ^lumpinfo_s;
    cacheExtra: Integer;
    pfnCacheBuild: PFNCACHE;
    numpaths: Integer;
    basedirs: PPAnsiChar;
    lumppathindices: PInteger;
    tempWad: Integer;
  end;
  cachewad_t = cachewad_s;

  TCacheWad = cachewad_s;
  PCacheWad = ^cachewad_s;

  FileSystemSeek_t =
  (
    FILESYSTEM_SEEK_HEAD = 0,
    FILESYSTEM_SEEK_CURRENT,
    FILESYSTEM_SEEK_TAIL
  );
  TFileSystemSeek = FileSystemSeek_t;

  FileWarningLevel_t =
  (
    FILESYSTEM_WARNING = -1,					   // A problem!
    FILESYSTEM_WARNING_QUIET = 0,			   // Don't print anything
    FILESYSTEM_WARNING_REPORTUNCLOSED,   // On shutdown, report names of files left unclosed
    FILESYSTEM_WARNING_REPORTUSAGE,		   // Report number of times a file was opened, closed
    FILESYSTEM_WARNING_REPORTALLACCESSES // Report all open/close events to console (!slow!)
  );
  TFileWarningLevel = FileWarningLevel_t;

  lump_s = record
    fileofs: Integer;
    filelen: Integer;
  end;
  lump_t = lump_s;

  TLump = lump_s;
  PLump = ^lump_s;

  dheader_s = record
    version: Integer;
    lumps: array[0..14] of lump_t;
  end;
  dheader_t = dheader_s;

  TDHeader = dheader_s;
  PDHeader = ^dheader_s;

  delta_stats_s = record
    sendcount: Integer;
    receivedcount: Integer;
  end;
  delta_stats_t = delta_stats_s;

  TDeltaStats = delta_stats_s;
  PDeltaStats = ^delta_stats_s;

  delta_description_s = record
    fieldType: Integer;
    fieldName: array[0..31] of AnsiChar;
    fieldOffset: Integer;
    fieldSize: Smallint;
    significant_bits: Integer;
    premultiply: Single;
    postmultiply: Single;
    flags: Integer;
    stats: delta_stats_t;
  end;
  delta_description_t = delta_description_s;

  TDeltaDescription = delta_description_s;
  PDeltaDescription = ^delta_description_s;
  {$IF SizeOf(TDeltaDescription) <> 68} {$MESSAGE WARN 'Structure size mismatch @ TDeltaDescription.'} {$DEFINE MSME} {$IFEND}

  encoder_t = procedure(field: Pointer {^delta_s}; from, &to: PByte); cdecl;

  delta_s = record
    &dynamic: Integer;
    fieldCount: Integer;
    conditionalencodename: array[0..31] of AnsiChar;
    conditionalencode: encoder_t;
    pdd: ^delta_description_t;
  end;
  delta_t = delta_s;

  TDelta = delta_s;
  PDelta = ^delta_s;

  MOD_GAMEPLAY_TYPE_E =
  (
    BOTH = 0,
    SINGLEPLAYER_ONLY,
    MULTIPLAYER_ONLY
  );

  modinfo_s = record
    bIsMod: qboolean;
    szInfo: array[0..255] of AnsiChar;
    szDL: array[0..255] of AnsiChar;
    szHLVersion: array[0..31] of AnsiChar;
    version: Integer;
    size: Integer;
    svonly: qboolean;
    cldll: qboolean;
    secure: qboolean;
    &type: MOD_GAMEPLAY_TYPE_E;
    num_edicts: Integer;
    clientcrccheck: qboolean;
  end;
  modinfo_t = modinfo_s;

  TModInfo = modinfo_s;
  PModInfo = ^modinfo_s;

  bf_write_s = record
    nCurOutputBit: Integer;
    pOutByte: PByte;
    pbuf: ^sizebuf_s;
  end;
  bf_write_t = bf_write_s;

  TBfWrite = bf_write_s;
  PBfWrite = ^bf_write_s;

  bf_read_s = record
    msg_readcount: Integer;
    pbuf: ^sizebuf_s;
    nBitFieldReadStartByte: Integer;
    nBytesRead: Integer;
    nCurInputBit: Integer;
    pInByte: PByte;
  end;
  bf_read_t = bf_read_s;

  TBfRead = bf_read_s;
  PBfRead = ^bf_read_s;

  pfnCvar_HookVariable_t = procedure(cvar: PCVar); cdecl;
  TCVarHookVariable = pfnCvar_HookVariable_t;

  cvarhook_s = record
    hook: pfnCvar_HookVariable_t;
    cvar: ^cvar_s;
    next: ^cvarhook_s;
  end;
  cvarhook_t = cvarhook_s;

  TCVarHook = cvarhook_s;
  PCVarHook = ^cvarhook_s;

  // MD5 Hash
  MD5Context_t = record
    buf: array[0..3] of Cardinal;
    bits: array[0..1] of Cardinal;
    &in: array[0..63] of Byte;
  end;

  TMD5Context = MD5Context_t;
  PMD5Context = ^MD5Context_t;

  miptex_s = record
    name: array[0..15] of AnsiChar;
    width: Cardinal;
    height: Cardinal;
    offsets: array[0..3] of Cardinal;
  end;
  miptex_t = miptex_s;

  TMipTex = miptex_s;
  PMipTex = ^miptex_s;

  decalname_s = record
    name: array[0..15] of AnsiChar;
    ucFlags: Byte;
  end;
  decalname_t = decalname_s;

  TDecalName = decalname_s;
  PDecalName = ^decalname_s;

  wadinfo_s = record
    identification: array[0..3] of AnsiChar;
    numlumps: Integer;
    infotableofs: Integer;
  end;
  wadinfo_t = wadinfo_s;

  TWadInfo = wadinfo_s;
  PWadInfo = ^wadinfo_s;

  delta_encoder_s = record
    next: ^delta_encoder_s;
    name: PAnsiChar;
    conditionalencode: encoder_t;
  end;
  delta_encoder_t = delta_encoder_s;

  TDeltaEncoder = delta_encoder_s;
  PDeltaEncoder = ^delta_encoder_s;

  delta_link_s = record
    next: ^delta_link_s;
    delta: ^delta_description_s;
  end;
  delta_link_t = delta_link_s;

  TDeltaLink = delta_link_s;
  PDeltaLink = ^delta_link_s;

  delta_definition_s = record
    fieldName: PAnsiChar;
    fieldOffset: Integer;
  end;
  delta_definition_t = delta_definition_s;

  TDeltaDefinition = delta_definition_s;
  PDeltaDefinition = ^delta_definition_s;

  delta_definition_list_s = record
    next: ^delta_definition_list_s;
    ptypename: PAnsiChar;
    numelements: Integer;
    pdefinition: ^delta_definition_s;
  end;
  delta_definition_list_t = delta_definition_list_s;

  TDeltaDefinitionList = delta_definition_list_s;
  PDeltaDefinitionList = ^delta_definition_list_s;

  delta_registry_s = record
    next: ^delta_registry_s;
    name: PAnsiChar;
    pdesc: ^delta_s;
  end;
  delta_registry_t = delta_registry_s;

  TDeltaRegistry = delta_registry_s;
  PDeltaRegistry = ^delta_registry_s;

  LEVELLIST = record
    mapName: array[0..31] of AnsiChar;
    landmarkName: array[0..31] of AnsiChar;
    pentLandmark: ^edict_t;
    vecLandmarkOrigin: vec3_t;
  end;

  quakeparms_s = record
    basedir: PAnsiChar;
    cachedir: PAnsiChar;
    argc: Integer;
    argv: PPAnsiChar;
    membase: Pointer;
    memsize: Integer;
  end;
  quakeparms_t = quakeparms_s;

  TQuakeParms = quakeparms_s;
  PQuakeParms = ^quakeparms_s;

  BlobFootprint_s = record
    m_hDll: Longint;
  end;
  BlobFootprint_t = ^BlobFootprint_s;

  TBlobFootprint = BlobFootprint_s;
  PBlobFootprint = ^BlobFootprint_s;

  TLevelList = LEVELLIST;
  PLevelList = ^LEVELLIST;

  hash_pack_entry_s = record
    resource: resource_s;
    nOffset: Integer;
    nFileLength: Integer;
  end;
  hash_pack_entry_t = hash_pack_entry_s;

  THashPackEntry = hash_pack_entry_s;
  PHashPackEntry = ^hash_pack_entry_s;

  hash_pack_directory_s = record
    nEntries: Integer;
    p_rgEntries: ^hash_pack_entry_s;
  end;
  hash_pack_directory_t = hash_pack_directory_s;

  THashPackDirectory = hash_pack_directory_s;
  PHashPackDirectory = ^hash_pack_directory_s;

  hash_pack_header_s = record
    szFileStamp: array[0..3] of AnsiChar;
    version: Integer;
    nDirectoryOffset: Integer;
  end;
  hash_pack_header_t = hash_pack_header_s;

  THashPackHeader = hash_pack_header_s;
  PHashPackHeader = ^hash_pack_header_s;

  hash_pack_queue_s = record
    pakname: PAnsiChar;
    resource: resource_s;
    datasize: Integer;
    data: Pointer;
    next: ^hash_pack_queue_s;
  end;
  hash_pack_queue_t = hash_pack_queue_s;

  THashPackQueue = hash_pack_queue_s;
  PHashPackQueue = ^hash_pack_queue_s;

  plane_t = record
    normal: vec3_t;
    dist: Single;
  end;

  TPlane = plane_t;
  PPlane = ^plane_t;

  trace_t = record
    allsolid: qboolean;    // if true, plane is not valid
    startsolid: qboolean;  // if true, the initial point was in a solid area
    inopen: qboolean;
    inwater: qboolean;
    fraction: Single;      // time completed, 1.0 = didn't hit anything
    endpos: vec3_t;        // final position
    plane: plane_t;        // surface normal at impact
    ent: ^edict_s;         // entity the surface is on
    hitgroup: Integer;     // 0 == generic, non zero is specific body part
  end;

  TTrace = trace_t;
  PTrace = ^trace_t;

  USERID_s = record
    idtype: Integer;
    m_SteamID: UInt64;
    clientip: Cardinal;
  end;
  USERID_t = USERID_s;

  TUserID = USERID_s;
  PUserID = ^USERID_s;
  {$IF SizeOf(TUserID) <> 24} {$MESSAGE WARN 'Structure size mismatch @ TUserID.'} {$DEFINE MSME} {$IFEND}

  server_log_t = record
    active: qboolean;
    net_log: qboolean;
    net_address: netadr_t;
    &file: Pointer;
  end;
  server_log_s = server_log_t;

  TServerLog = server_log_t;
  PServerLog = ^server_log_t;

  server_stats_s = record
    num_samples: Integer;
    at_capacity: Integer;
    at_empty: Integer;
    capacity_percent: Single;
    empty_percent: Single;
    minusers: Integer;
    maxusers: Integer;
    cumulative_occupancy: Single;
    occupancy: Single;
    num_sessions: Integer;
    cumulative_sessiontime: Single;
    average_session_len: Single;
    cumulative_latency: Single;
    average_latency: Single;
  end;
  server_stats_t = server_stats_s;

  TServerStats = server_stats_s;
  PServerStats = ^server_stats_s;

  client_frame_s = record
    senttime: Double;
    ping_time: Single;
    clientdata: clientdata_t;
    weapondata: array[0..63] of weapon_data_t;
    entities: packet_entities_t;
  end;
  client_frame_t = client_frame_s;

  TClientFrame = client_frame_s;
  PClientFrame = ^client_frame_s;

  // @xref: Host_ClearClients
  client_s = record
    active: qboolean;
    spawned: qboolean;
    fully_connected: qboolean;
    connected: qboolean;
    uploading: qboolean;
    hasusrmsgs: qboolean;
    has_force_unmodified: qboolean;
    netchan: netchan_s;
    chokecount: Integer;
    delta_sequence: Integer;
    fakeclient: qboolean;
    proxy: qboolean;
    lastcmd: usercmd_s;
    connecttime: Double;
    cmdtime: Double;
    ignorecmdtime: Double;
    latency: Single;
    packet_loss: Single;
    localtime: Double;
    nextping: Double;
    svtimebase: Double;
    datagram: sizebuf_s;
    datagram_buf: array[0..3999] of Byte;
    connection_started: Double;
    next_messagetime: Double;
    next_messageinterval: Double;
    send_message: qboolean;
    skip_message: qboolean;
    frames: ^client_frame_s;
    events: event_state_s;
    edict: ^edict_s;
    pViewEntity: ^edict_s;
    userid: Integer;
    network_userid: USERID_t;
    userinfo: array[0..255] of AnsiChar;
    sendinfo: qboolean;
    sendinfo_time: Single;
    hashedcdkey: array[0..63] of AnsiChar;
    name: array[0..31] of AnsiChar;
    topcolor: Integer;
    bottomcolor: Integer;
    entityId: Integer;
    resourcesonhand: resource_s;
    resourcesneeded: resource_s;
    upload: FileHandle_t;
    uploaddoneregistering: qboolean;
    customdata: customization_s;
    crcValue: Integer;
    lw: Integer;
    lc: Integer;
    physinfo: array[0..255] of AnsiChar;
    m_bLoopback: qboolean;
    m_VoiceStreams: array[0..1] of LongWord;
    m_lastvoicetime: Double;
    m_sendrescount: Integer;
  end;
  client_t = client_s;

  TClient = client_s;
  PClient = ^client_s;
  {$IF SizeOf(TClient) <> 20504} {$MESSAGE WARN 'Structure size mismatch @ TClient.'} {$DEFINE MSME} {$IFEND}

type
  server_static_s = record
    dll_initialized: qboolean;
    clients: ^client_s;
    maxclients: Integer;
    maxclientslimit: Integer;
    spawncount: Integer;
    serverflags: Integer;
    log: server_log_t;
    next_cleartime: Double;
    next_sampletime: Double;
    stats: server_stats_t;
    isSecure: qboolean;
  end;
  server_static_t = server_static_s;

  TServerStatic = server_static_s;
  PServerStatic = ^server_static_s;

  ENTITYTABLE = record
    id: Integer;    // Ordinal ID of this entity (used for entity <--> pointer conversions)
    pent: ^edict_t; // Pointer to the in-game entity

    location: Integer;   // Offset from the base data of this entity
    size: Integer;       // Byte size of this entity's data
    flags: Integer;      // This could be a short -- bit mask of transitions that this entity is in the PVS of
    classname: string_t; // entity class name
  end;

  TEntityTable = ENTITYTABLE;
  PEntityTable = ^ENTITYTABLE;

  // Passed to pfnKeyValue
  KeyValueData_s = record
	  szClassName: PAnsiChar;	// in: entity classname
	  szKeyName: PAnsiChar;		// in: name of key
	  szValue: PAnsiChar;		  // in: value of key
		fHandled: qboolean;     // out: DLL sets to true if key-value pair was understood
  end;
  KeyValueData = KeyValueData_s;

  TKeyValueData = KeyValueData_s;
  PKeyValueData = ^KeyValueData_s;

  saverestore_s = record
    pBaseData: PAnsiChar;		// Start of all entity save data
    pCurrentData: PAnsiChar;	// Current buffer pointer for sequential access
    size: Integer;			// Current data size
    bufferSize: Integer;		// Total space for data
    tokenSize: Integer;		// Size of the linear list of tokens
    tokenCount: Integer;		// Number of elements in the pTokens table
    pTokens: PPAnsiChar;		// Hash table of entity strings (sparse)
    currentIndex: Integer;	// Holds a global entity table ID
    tableCount: Integer;		// Number of elements in the entity table
    connectionCount: Integer;// Number of elements in the levelList[]
    pTable: ^ENTITYTABLE;		// Array of ENTITYTABLE elements (1 for each entity)
    levelList: array[0..MAX_LEVEL_CONNECTIONS - 1] of LEVELLIST;		// List of connections from this level

    // smooth transition
    fUseLandmark: Integer;
    szLandmarkName: array[0..19] of AnsiChar; // landmark we'll spawn near in next level
    vecLandmarkOffset: vec3_t; // for landmark transitions
    time: Single;
    szCurrentMapName: array[0..31] of AnsiChar;	// To check global entities
  end;
  SAVERESTOREDATA = saverestore_s;

  TSaveRestoreData = saverestore_s;
  PSaveRestoreData = ^saverestore_s;

  // Returned by TraceLine
  TraceResult = record
    fAllSolid: Integer;     // if true, plane is not valid
    fStartSolid: Integer;		// if true, the initial point was in a solid area
    fInOpen: Integer;
    fInWater: Integer;
    flFraction: Single;			// time completed, 1.0 = didn't hit anything
    vecEndPos: vec3_t;			// final position
    flPlaneDist: Single;
    vecPlaneNormal: vec3_t; // surface normal at impact
    pHit: ^edict_t;				  // entity the surface is on
    iHitgroup: Integer;			// 0 == generic, non zero is specific body part
  end;

  TTraceResult = TraceResult;
  PTraceResult = ^TraceResult;

  _fieldtypes =
  (
    FIELD_FLOAT = 0,		// Any floating point value
    FIELD_STRING,			// A string ID (return from ALLOC_STRING)
    FIELD_ENTITY,			// An entity offset (EOFFSET)
    FIELD_CLASSPTR,			// CBaseEntity *
    FIELD_EHANDLE,			// Entity handle
    FIELD_EVARS,			// EVARS *
    FIELD_EDICT,			// edict_t *, or edict_t *  (same thing)
    FIELD_VECTOR,			// Any vector
    FIELD_POSITION_VECTOR,	// A world coordinate (these are fixed up across level transitions automagically)
    FIELD_POINTER,			// Arbitrary data pointer... to be removed, use an array of FIELD_CHARACTER
    FIELD_INTEGER,			// Any integer or enum
    FIELD_FUNCTION,			// A class function pointer (Think, Use, etc)
    FIELD_BOOLEAN,			// boolean, implemented as an int, I may use this as a hint for compression
    FIELD_SHORT,			// 2 byte integer
    FIELD_CHARACTER,		// a byte
    FIELD_TIME,				// a floating point time (these are fixed up automatically too!)
    FIELD_MODELNAME,		// Engine string that is a model name (needs precache)
    FIELD_SOUNDNAME		// Engine string that is a sound name (needs precache)
  );
  FIELDTYPE = _fieldtypes;

  TFieldType = _fieldtypes;
  PFieldType = ^_fieldtypes;

const
  // @todo: validate
  FIELD_TYPECOUNT = SizeOf(_fieldtypes) div SizeOf(FIELD_FLOAT);

type
  TYPEDESCRIPTION = record
    fieldType: FIELDTYPE;
    fieldName: PAnsiChar;
    fieldOffset: Integer;
    fieldSize: Smallint;
    flags: Smallint;
  end;

  TTypeDescription = TYPEDESCRIPTION;
  PTypeDescription = ^TYPEDESCRIPTION;

  // @xref: CL_SetDemoViewInfo
  movevars_s = record
    gravity: Single;			// Gravity for map
    stopspeed: Single;		// Deceleration when not moving
    maxspeed: Single;			// Max allowed speed
    spectatormaxspeed: Single;
    accelerate: Single;		// Acceleration factor
    airaccelerate: Single;	// Same for when in open air
    wateraccelerate: Single;	// Same for when in water
    friction: Single;
    edgefriction: Single;		// Extra friction near dropofs
    waterfriction: Single;	// Less in water
    entgravity: Single;		// 1.0
    bounce: Single;			// Wall bounce value. 1.0
    stepsize: Single;			// sv_stepsize;
    maxvelocity: Single;		// maximum server velocity.
    zmax: Single;				// Max z-buffer range (for GL)
    waveHeight: Single;		// Water wave height (for GL)
    footsteps: qboolean;		// Play footstep sounds
    skyName: array[0..31] of AnsiChar;		// Name of the sky map
    rollangle: Single;
    rollspeed: Single;
    skycolor_r: Single;		// Sky color
    skycolor_g: Single;
    skycolor_b: Single;
    skyvec_x: Single;			// Sky vector
    skyvec_y: Single;
    skyvec_z: Single;
  end;
  movevars_t = movevars_s;

  TMoveVars = movevars_s;
  PMoveVars = ^movevars_s;
  {$IF SizeOf(TMoveVars) <> 132} {$MESSAGE WARN 'Structure size mismatch @ TMoveVars.'} {$DEFINE MSME} {$IFEND}

  pfnIgnore_t = function(const pe: physent_t): Integer; cdecl;

  playermove_s = record
    player_index: integer;				// So we don't try to run the PM_CheckStuck nudging too quickly.
    server: qboolean;				// For debugging, are we running physics code on server side?
    multiplayer: qboolean;			// 1 == multiplayer server
    time: Single;						// realtime on host, for reckoning duck timing
    frametime: Single;				// Duration of this frame
    &forward, right, up: vec3_t;		// Vectors for angles
    origin: vec3_t;					// Movement origin.
    angles: vec3_t;					// Movement view angles.
    oldangles: vec3_t;				// Angles before movement view angles were looked at.
    velocity: vec3_t;				// Current movement direction.
    movedir: vec3_t;					// For waterjumping, a forced forward velocity so we can fly over lip of ledge.
    basevelocity: vec3_t;			// Velocity of the conveyor we are standing, e.g.
    view_ofs: vec3_t;				// For ducking/dead
                    // Our eye position.
    flDuckTime: Single;				// Time we started duck
    bInDuck: qboolean;				// In process of ducking or ducked already?
    flTimeStepSound: Integer;	 // For walking/falling
                               // Next time we can play a step sound
    iStepLeft: Integer;
    flFallVelocity: Single;
    punchangle: vec3_t;
    flSwimTime: Single;
    flNextPrimaryAttack: Single;
    effects: Integer;					// MUZZLE FLASH, e.g.
    flags: Integer;						// FL_ONGROUND, FL_DUCKING, etc.
    usehull: Integer;					// 0 = regular player hull, 1 = ducked player hull, 2 = point hull
    gravity: Single;					// Our current gravity and friction.
    friction: Single;
    oldbuttons: Integer;					// Buttons last usercmd
    waterjumptime: Single;			// Amount of time left in jumping out of water cycle.
    dead: qboolean;					// Are we a dead player?
    deadflag: Integer;
    spectator: Integer;					// Should we use spectator physics model?
    movetype: Integer;					// Our movement type, NOCLIP, WALK, FLY
    onground: Integer;					// -1 = in air, else pmove entity number
    waterlevel: Integer;
    watertype: Integer;
    oldwaterlevel: Integer;
    sztexturename: array[0..255] of AnsiChar;
    chtexturetype: AnsiChar;
    maxspeed: Single;
    clientmaxspeed: Single;
    iuser1: Integer;
    iuser2: Integer;
    iuser3: Integer;
    iuser4: Integer;
    fuser1: Single;
    fuser2: Single;
    fuser3: Single;
    fuser4: Single;
    vuser1: vec3_t;
    vuser2: vec3_t;
    vuser3: vec3_t;
    vuser4: vec3_t;
    numphysent: Integer;	// world state
                          // Number of entities to clip against.
    physents: array[0..MAX_PHYSENTS - 1] of physent_s;
    nummoveent: Integer;	// Number of momvement entities (ladders)
    moveents: array[0..MAX_MOVEENTS - 1] of physent_s;	// just a list of ladders
    numvisent: Integer;	  // All things being rendered, for tracing against things you don't actually collide with
    visents: array[0..MAX_PHYSENTS - 1] of physent_s;
    cmd: usercmd_s;			// input to run through physics.
    numtouch: Integer;	// Trace results for objects we collided with.
    touchindex: array[0..MAX_PHYSENTS - 1] of pmtrace_t;
    physinfo: array[0..MAX_PHYSINFO_STRING - 1] of AnsiChar;	// Physics info string
    movevars: ^movevars_s;
    player_mins: array[0..3] of array[0..2] of vec_t;
    player_maxs: array[0..3] of array[0..2] of vec_t;

    PM_Info_ValueForKey: function(s, key: PAnsiChar): PAnsiChar; cdecl;
    PM_Particle: procedure(origin: PSingle; color: Integer; life: Single; zpos, zvel: Integer); cdecl;
    PM_TestPlayerPosition: function(pos: PSingle; ptrace: PPMTrace): Integer; cdecl;
    Con_NPrintf: procedure(idx: Integer; fmt: PAnsiChar); cdecl varargs;
    Con_DPrintf: procedure(fmt: PAnsiChar); cdecl varargs;
    Con_Printf: procedure(fmt: PAnsiChar); cdecl varargs;
    Sys_FloatTime: function: Double; cdecl;
    PM_StuckTouch: procedure(hitent: Integer; ptraceresult: PPMTrace); cdecl;
    PM_PointContents: function(p: PVec; var truecontents: Integer): Integer; cdecl;
    PM_TruePointContents: function(p: PVec): Integer; cdecl;
    PM_HullPointContents: function(hull: PHull; num: Integer; p: PVec): Integer; cdecl;
    PM_PlayerTrace: function(start, &end: PVec; traceFlags, ignore_pe: Integer): pmtrace_t; cdecl;
    PM_TraceLine: function(start, &end: PVec; flags, usehulll, ignore_pe: Integer): PPMTrace; cdecl;
    RandomLong: function(lLow, lHigh: Longint): Longint; cdecl;
    RandomFloat: function(flLow, flHigh: Single): Single; cdecl;
    PM_GetModelType: function(const &mod: model_s): Integer; cdecl;
    PM_GetModelBounds: procedure(const &mod: model_s; var mins, maxs: vec_t); cdecl;
    PM_HullForBsp: function(const pe: physent_s; offset: PVec): Pointer; cdecl;
    PM_TraceModel: function(const pEnt: physent_s; start, &end: PVec; const trace: trace_t): Single; cdecl;
    COM_FileSize: function(filename: PAnsiChar): Integer; cdecl;
    COM_LoadFile: function(path: PAnsiChar; usehunk: Integer; var pLength: Integer): PByte; cdecl;
    COM_FreeFile: procedure(buffer: Pointer); cdecl;
    memfgets: function(pMemFile: PByte; fileSize: Integer; var pFilePos: Integer; pBuffer: PAnsiChar; bufferSize: Integer): PAnsiChar; cdecl;
    runfuncs: qboolean;
    PM_PlaySound: procedure(channel: Integer; sample: PAnsiChar; volume, attenuation: Single; fFlags, pitch: Integer); cdecl;
    PM_TraceTexture: function(ground: Integer; vstart, vend: PVec): PAnsiChar; cdecl;
    PM_PlaybackEventFull: procedure(flags, clientindex: Integer; eventindex: Word; delay: Single; origin, angles: PVec; fparam1, fparam2: Single; iparam1, iparam2: Integer; bparam1, bparam2: Integer); cdecl;
    PM_PlayerTraceEx: function(start, &end: PVec; traceFlags: Integer; pfnIgnore: pfnIgnore_t): pmtrace_s; cdecl;
    PM_TestPlayerPositionEx: function(pos: PVec; var ptrace: pmtrace_t; pfnIgnore: pfnIgnore_t): Integer; cdecl;
    PM_TraceLineEx: function(start, &end: PVec; flags, usehulll: Integer; pfnIgnore: pfnIgnore_t): pmtrace_s; cdecl;
  end;
  playermove_t = playermove_s;

  TPlayerMove = playermove_s;
  PPlayerMove = ^playermove_s;
  {$IF SizeOf(TPlayerMove) <> 325068} {$MESSAGE WARN 'Structure size mismatch @ TPlayerMove.'} {$DEFINE MSME} {$IFEND}

  DLL_FUNCTIONS = record
    // Initialize/shutdown the game (one-time call after loading of game .dll )
    pfnGameInit: procedure; cdecl;
    pfnSpawn: function(const pent: edict_t): Integer; cdecl;
    pfnThink: procedure(const pent: edict_t); cdecl;
    pfnUse: procedure(const pentUsed: edict_t; pentOther: edict_t); cdecl;
    pfnTouch: procedure(const pentTouched: edict_t; const pentOther: edict_t); cdecl;
    pfnBlocked: procedure(const pentBlocked: edict_t; const pentOther: edict_t); cdecl;
    pfnKeyValue: procedure(const pentKeyvalue: edict_t; const pkvd: KeyValueData); cdecl;
    pfnSave: procedure(const pent: edict_t; const pSaveData: SAVERESTOREDATA); cdecl;
    pfnRestore: function(const pent: edict_t; const pSaveData: SAVERESTOREDATA; globalEntity: Integer): Integer; cdecl;
    pfnSetAbsBox: procedure(const pent: edict_t); cdecl;

    pfnSaveWriteFields: procedure(const pSaveData: SAVERESTOREDATA; pname: PAnsiChar; pBaseData: Pointer; const pFields: TYPEDESCRIPTION; fieldCount: Integer); cdecl;
    pfnSaveReadFields: procedure(const pSaveData: SAVERESTOREDATA; pname: PAnsiChar; pBaseData: Pointer; const pFields: TYPEDESCRIPTION; fieldCount: Integer); cdecl;

    pfnSaveGlobalState: procedure(const pSaveData: SAVERESTOREDATA); cdecl;
    pfnRestoreGlobalState: procedure(const pSaveData: SAVERESTOREDATA); cdecl;
    pfnResetGlobalState: procedure; cdecl;

    pfnClientConnect: function(const pEntity: edict_t; pszName, pszAddress: PAnsiChar; szRejectReason: PAnsiChar): Integer; cdecl;

    pfnClientDisconnect: procedure(const pEntity: edict_t); cdecl;
    pfnClientKill: procedure(const pEntity: edict_t); cdecl;
    pfnClientPutInServer: procedure(const pEntity: edict_t); cdecl;
    pfnClientCommand: procedure(pEntity: edict_t); cdecl;
    pfnClientUserInfoChanged: procedure(pEntity: edict_t; infobuffer: PAnsiChar); cdecl;

    pfnServerActivate: procedure(const pEdictList: edict_t; edictCount, clientMax: Integer); cdecl;
    pfnServerDeactivate: procedure; cdecl;

    pfnPlayerPreThink: procedure(const pEntity: edict_t); cdecl;
    pfnPlayerPostThink: procedure(const pEntity: edict_t); cdecl;

    pfnStartFrame: procedure; cdecl;
    pfnParmsNewLevel: procedure; cdecl;
    pfnParmsChangeLevel: procedure; cdecl;

     // Returns string describing current .dll.  E.g., TeamFotrress 2, Half-Life
    pfnGetGameDescription: function: PAnsiChar; cdecl;

    // Notify dll about a player customization.
    pfnPlayerCustomization: procedure(const pEntity: edict_t; const pCustom: customization_t); cdecl;

    // Spectator funcs
    pfnSpectatorConnect: procedure(const pEntity: edict_t); cdecl;
    pfnSpectatorDisconnect: procedure(const pEntity: edict_t); cdecl;
    pfnSpectatorThink: procedure(const pEntity: edict_t); cdecl;

    // Notify game .dll that engine is going to shut down.  Allows mod authors to set a breakpoint.
    pfnSys_Error: procedure(error_string: PAnsiChar); cdecl;

    pfnPM_Move: procedure(const ppmove: playermove_s; server: qboolean); cdecl;
    pfnPM_Init: procedure(const ppmove: playermove_s); cdecl;
    pfnPM_FindTextureType: function(name: PAnsiChar): PAnsiChar; cdecl;
    pfnSetupVisibility: procedure(const pViewEntity: edict_s; const pClient: edict_s; pvs: PPointer; pas: PPointer); cdecl;
    pfnUpdateClientData: procedure(const ent: edict_s; sendweapons: Integer; const cd: clientdata_s); cdecl;
    pfnAddToFullPack: function(const state: entity_state_s; e: Integer; const ent: edict_t; const host: edict_t; hostflags, player: Integer; pSet: PByte): Integer; cdecl;
    pfnCreateBaseline: procedure(player: Integer; eindex: Integer; const baseline: entity_state_s; const entity: edict_s; playermodelindex: Integer; const player_mins, player_maxs: vec3_t); cdecl;
    pfnRegisterEncoders: procedure; cdecl;
    pfnGetWeaponData: function(const player: edict_s; const info: weapon_data_s): Integer; cdecl;

    pfnCmdStart: procedure(const player: edict_t; const cmd: usercmd_s; random_seed: Cardinal); cdecl;
    pfnCmdEnd: procedure(const player: edict_t); cdecl;

    // Return 1 if the packet is valid.  Set response_buffer_size if you want to send a response packet.  Incoming, it holds the max
    //  size of the response_buffer, so you must zero it out if you choose not to respond.
    pfnConnectionlessPacket: function(const net_from_: netadr_s; args: PAnsiChar; response_buffer: PAnsiChar; var response_buffer_size: Integer): Integer; cdecl;

    // Enumerates player hulls.  Returns 0 if the hull number doesn't exist, 1 otherwise
    pfnGetHullBounds: function(hullnumber: Integer; var mins, maxs: vec3_t): Integer; cdecl;

    // Create baselines for certain "unplaced" items.
    pfnCreateInstancedBaselines: procedure; cdecl;

    // One of the pfnForceUnmodified files failed the consistency check for the specified player
    // Return 0 to allow the client to continue, 1 to force immediate disconnection ( with an optional disconnect message of up to 256 characters )
    pfnInconsistentFile: function(const player: edict_s; filename: PAnsiChar; disconnect_message: PAnsiChar): Integer; cdecl;

    // The game .dll should return 1 if lag compensation should be allowed ( could also just set
    //  the sv_unlag cvar.
    // Most games right now should return 0, until client-side weapon prediction code is written
    //  and tested for them.
    pfnAllowLagCompensation: function: Integer; cdecl;
  end;

  TDLLFunctions = DLL_FUNCTIONS;
  PDLLFunctions = ^DLL_FUNCTIONS;

const
  // Current version.
  NEW_DLL_FUNCTIONS_VERSION	= 1;

type
  NEW_DLL_FUNCTIONS = record
    // Called right before the object's memory is freed.
    // Calls its destructor.
    pfnOnFreeEntPrivateData: procedure(const pEnt: edict_t); cdecl;
    pfnGameShutdown: procedure; cdecl;
    pfnShouldCollide: function(const pentTouched: edict_t; const pentOther: edict_t): Integer; cdecl;
    pfnCvarValue: procedure(const pEnt: edict_t; value: PAnsiChar); cdecl;
    pfnCvarValue2: procedure(const pEnt: edict_t; requestID: Integer; cvarName: PAnsiChar; value: PAnsiChar); cdecl;
  end;

  NEW_DLL_FUNCTIONS_FN = function(var pFunctionTable: NEW_DLL_FUNCTIONS; var interfaceVersion: Integer): Integer; cdecl;

  APIFUNCTION = function(var pFunctionTable: DLL_FUNCTIONS; interfaceVersion: Integer): Integer; cdecl;
  APIFUNCTION2 = function(var pFunctionTable: DLL_FUNCTIONS; var interfaceVersion: Integer): Integer; cdecl;

  mspriteframe_s = record
    width: Integer;
    height: Integer;
    up: Single;
    down: Single;
    left: Single;
    right: Single;
    gl_texturenum: Integer;
  end;
  mspriteframe_t = mspriteframe_s;

  TMSpriteFrame = mspriteframe_s;
  PMSpriteFrame = ^mspriteframe_s;

  mspriteframedesc_t = record
    &type: spriteframetype_t;
    frameptr: ^mspriteframe_t;
  end;

  TMSpriteFrameDesc = mspriteframedesc_t;
  PMSpriteFrameDesc = ^mspriteframedesc_t;

  msprite_s = record
    &type: Smallint;
    &texFormat: Smallint;
    maxwidth: Integer;
    maxheight: Integer;
    numframes: Integer;
    paloffset: Integer;
    beamlength: Single;
    cachespot: Pointer;
    frames: array[0..0] of mspriteframedesc_t;
  end;
  msprite_t = msprite_s;

  TMSprite = msprite_s;
  PMSprite = ^msprite_s;

  // @xref: V_SetRefParams
  ref_params_s = record
    // Output
    vieworg: array[0..2] of Single;
    viewangles: array[0..2] of Single;

    &forward: array[0..2] of Single;
    right: array[0..2] of Single;
    up: array[0..2] of Single;

    // Client frametime;
    frametime: Single;
    // Client time
    time: Single;

    // Misc
    intermission: Integer;
    paused: Integer;
    spectator: Integer;
    onground: Integer;
    waterlevel: Integer;

    simvel: array[0..2] of Single;
    simorg: array[0..2] of Single;

    viewheight: array[0..2] of Single;
    idealpitch: Single;

    cl_viewangles: array[0..2] of Single;

    health: Integer;
    crosshairangle: array[0..2] of Single;
    viewsize: Single;

    punchangle: array[0..2] of Single;
    maxclients: Integer;
    viewentity: Integer;
    playernum: Integer;
    max_entities: Integer;
    demoplayback: Integer;
    hardware: Integer;

    smoothing: Integer;

    // Last issued usercmd
    cmd: ^usercmd_s;

    // Movevars
    movevars: ^movevars_s;

    viewport: array[0..3] of Integer;		// the viewport coordinates x ,y , width, height

    nextView: Integer;			  // the renderer calls ClientDLL_CalcRefdef() and Renderview
                              // so long in cycles until this value is 0 (multiple views)
    onlyClientDraw: Integer;	// if !=0 nothing is drawn by the engine except clientDraw functions
  end;
  ref_params_t = ref_params_s;

  TRefParms = ref_params_s;
  PRefParms = ^ref_params_s;
  {$IF SizeOf(TRefParms) <> 232} {$MESSAGE WARN 'Structure size mismatch @ TRefParms.'} {$DEFINE MSME} {$IFEND}

  mstudioevent_s = record
    frame: Integer;
    event: Integer;
    &type: Integer;
    options: array[0..63] of AnsiChar;
  end;
  mstudioevent_t = mstudioevent_s;

  TMStudioEvent = mstudioevent_s;
  PMStudioEvent = ^mstudioevent_s;

  client_data_s = record
    // fields that cannot be modified  (ie. have no effect if changed)
    origin: vec3_t;

    // fields that can be changed by the cldll
    viewangles: vec3_t;
    iWeaponBits: Integer;
    fov: Single;	// field of view
  end;
  client_data_t = client_data_s;

  // @note: TClientData (clientdata_s) already exists
  TClient_Data = client_data_s;
  PClient_Data = ^client_data_s;

  module_s = record
    ucMD5Hash: array[0..15] of Byte;  // hash over code
    fLoaded: qboolean;                // true if successfully loaded
  end;
  module_t = module_s;

  TModule = module_s;
  PModule = ^module_s;

  kbutton_s = record
    down: array[0..1] of Integer;
    state: Integer;
  end;
  kbutton_t = kbutton_s;

  TKButton = kbutton_s;
  PKButton = ^kbutton_s;

  pfnEngSrc_pfnSPR_Load_t = function(szPicName: PAnsiChar): HSPRITE; cdecl;
  pfnEngSrc_pfnSPR_Frames_t = function(hPic: HSPRITE): Integer; cdecl;
  pfnEngSrc_pfnSPR_Height_t = function(hPic: HSPRITE; frame: Integer): Integer; cdecl;
  pfnEngSrc_pfnSPR_Width_t = function(hPic: HSPRITE; frame: Integer): Integer; cdecl;
  pfnEngSrc_pfnSPR_Set_t = procedure(hPic: HSPRITE; r, g, b: Integer); cdecl;
  pfnEngSrc_pfnSPR_Draw_t = procedure(frame: Integer; x, y: Integer; const prc: rect_s); cdecl;
  pfnEngSrc_pfnSPR_DrawHoles_t = procedure(frame: Integer; x, y: Integer; const prc: rect_s); cdecl;
  pfnEngSrc_pfnSPR_DrawAdditive_t = procedure(frame, x, y: Integer; const prc: rect_s); cdecl;
  pfnEngSrc_pfnSPR_EnableScissor_t = procedure(x, y, width, height: Integer); cdecl;
  pfnEngSrc_pfnSPR_DisableScissor_t = procedure; cdecl;
  pfnEngSrc_pfnSPR_GetList_t = function(psz: PAnsiChar; var piCount: Integer): PClientSprite; cdecl;
  pfnEngSrc_pfnFillRGBA_t = procedure(x, y, width, height, r, g, b, a: Integer); cdecl;
  pfnEngSrc_pfnGetScreenInfo_t = function(var pscrinfo: SCREENINFO_s): Integer; cdecl;
  pfnEngSrc_pfnSetCrosshair_t = procedure(hspr: HSPRITE; rc: wrect_t; r, g, b: Integer); cdecl;
  pfnEngSrc_pfnRegisterVariable_t = function(szName, szValue: PAnsiChar; flags: Integer): PCVar; cdecl;
  pfnEngSrc_pfnGetCvarFloat_t = function(szName: PAnsiChar): Single; cdecl;
  pfnEngSrc_pfnGetCvarString_t = function(szName: PAnsiChar): PAnsiChar; cdecl;
  pfnEngSrc_pfnAddCommand_t = function(cmd_name: PAnsiChar; pfnEngSrc_function: pfnEngSrc_Callback_t): Integer; cdecl;
  pfnEngSrc_pfnHookUserMsg_t = function(szMsgName: PAnsiChar; pfn: pfnUserMsgHook): Integer; cdecl;
  pfnEngSrc_pfnServerCmd_t = function(szCmdString: PAnsiChar): Integer; cdecl;
  pfnEngSrc_pfnClientCmd_t = function(szCmdString: PAnsiChar): Integer; cdecl;
  pfnEngSrc_pfnPrimeMusicStream_t = procedure(szFilename: PAnsiChar; looping: Integer); cdecl;
  pfnEngSrc_pfnGetPlayerInfo_t = procedure(ent_num: Integer; var pinfo: hud_player_info_s); cdecl;
  pfnEngSrc_pfnPlaySoundByName_t = procedure(szSound: PAnsiChar; volume: Single); cdecl;
  pfnEngSrc_pfnPlaySoundByNameAtPitch_t = procedure(szSound: PAnsiChar; volume: Single; pitch: Integer); cdecl;
  pfnEngSrc_pfnPlaySoundVoiceByName_t = procedure(szSound: PAnsiChar; volume: Single; pitch: Integer); cdecl;
  pfnEngSrc_pfnPlaySoundByIndex_t = procedure(iSound: Integer; volume: Single); cdecl;
  pfnEngSrc_pfnAngleVectors_t = procedure(vecAngles: Single; var &forward, right, up: vec3_t); cdecl;
  pfnEngSrc_pfnTextMessageGet_t = function(pName: PAnsiChar): PClientTextMessage; cdecl;
  pfnEngSrc_pfnDrawCharacter_t = function(x, y, number, r, g, b: Integer): Integer; cdecl;
  pfnEngSrc_pfnDrawConsoleString_t = function(x, y: Integer; &string: PAnsiChar): Integer; cdecl;
  pfnEngSrc_pfnDrawSetTextColor_t = procedure(r, g, b: Single); cdecl;
  pfnEngSrc_pfnDrawConsoleStringLen_t = procedure(&string: PAnsiChar; var width, height: Integer); cdecl;
  pfnEngSrc_pfnConsolePrint_t = procedure(&string: PAnsiChar); cdecl;
  pfnEngSrc_pfnCenterPrint_t = procedure(&string: PAnsiChar); cdecl;
  pfnEngSrc_GetWindowCenterX_t = procedure; cdecl;
  pfnEngSrc_GetWindowCenterY_t = function: Integer; cdecl;
  pfnEngSrc_GetViewAngles_t = procedure(var va: vec3_t); cdecl;
  pfnEngSrc_SetViewAngles_t = procedure(const va: vec3_t); cdecl;
  pfnEngSrc_GetMaxClients_t = procedure; cdecl;
  pfnEngSrc_Cvar_SetValue_t = procedure(cvar: PAnsiChar; value: Single); cdecl;
  pfnEngSrc_Cmd_Argc_t = function: Integer; cdecl;
  pfnEngSrc_Cmd_Argv_t = function(arg: Integer): PAnsiChar; cdecl;
  pfnEngSrc_Con_Printf_t = procedure(fmt: PAnsiChar); cdecl varargs;
  pfnEngSrc_Con_DPrintf_t = procedure(fmt: PAnsiChar); cdecl varargs;
  pfnEngSrc_Con_NPrintf_t = procedure(pos: Integer; fmt: PAnsiChar); cdecl varargs;
  pfnEngSrc_Con_NXPrintf_t = procedure(info: con_nprint_s; fmt: PAnsiChar); cdecl varargs;
  pfnEngSrc_PhysInfo_ValueForKey_t = function(key: PAnsiChar): PAnsiChar; cdecl;
  pfnEngSrc_ServerInfo_ValueForKey_t = function(key: PAnsiChar): PAnsiChar; cdecl;
  pfnEngSrc_GetClientMaxspeed_t = function: Single; cdecl;
  pfnEngSrc_CheckParm_t = function(parm: PAnsiChar; ppnext: PPAnsiChar): Integer; cdecl;
  pfnEngSrc_Key_Event_t = procedure(key, down: Integer); cdecl;
  pfnEngSrc_GetMousePosition_t = procedure(var mx, my: Integer); cdecl;
  pfnEngSrc_IsNoClipping_t = function: Integer; cdecl;
  pfnEngSrc_GetLocalPlayer_t = function: PCLEntity; cdecl;
  pfnEngSrc_GetViewModel_t = function: PCLEntity; cdecl;
  pfnEngSrc_GetEntityByIndex_t = function(idx: Integer): PCLEntity; cdecl;
  pfnEngSrc_GetClientTime_t = function: Single; cdecl;
  pfnEngSrc_V_CalcShake_t = procedure; cdecl;
  pfnEngSrc_V_ApplyShake_t = procedure(const origin, angles: vec3_t; factor: Single); cdecl;
  pfnEngSrc_PM_PointContents_t = function(const point: vec3_t; var truecontents: Integer): Integer; cdecl;
  pfnEngSrc_PM_WaterEntity_t = function(const p: vec3_t): Integer; cdecl;
  pfnEngSrc_PM_TraceLine_t = function(const start, &end: vec3_t; flags, usehull, ignore_pe: Integer): PPMTrace; cdecl;
  pfnEngSrc_CL_LoadModel_t = function(modelname: PAnsiChar; var index: Integer): PModel; cdecl;
  pfnEngSrc_CL_CreateVisibleEntity_t = function(&type: Integer; const ent: cl_entity_s): Integer; cdecl;
  pfnEngSrc_GetSpritePointer_t = function(hSprite: HSPRITE): PModel; cdecl;
  pfnEngSrc_pfnPlaySoundByNameAtLocation_t = procedure(szSound: PAnsiChar; volume: Single; const origin: vec3_t); cdecl;
  pfnEngSrc_pfnPrecacheEvent_t = function(&type: Integer; psz: PAnsiChar): Word; cdecl;
  pfnEngSrc_pfnPlaybackEvent_t = procedure(flags: Integer; const pInvoker: edict_s; eventindex: Word; delay: Single; const origin, angles: vec3_t; fparam1, fparam2: Single; iparam1, iparam2: Integer; bparam1, bparam2: Integer); cdecl;
  pfnEngSrc_pfnWeaponAnim_t = procedure(iAnim, body: Integer); cdecl;
  pfnEngSrc_pfnRandomFloat_t = function(flLow, flHigh: Single): Single; cdecl;
  pfnEngSrc_pfnRandomLong_t = function(lLow, lHigh: Longint): Longint; cdecl;
  pfnEngSrc_pfnHookEvent_t = procedure(name: PAnsiChar; pfnEvent: pfnEvent_Callback_t); cdecl;
  pfnEngSrc_Con_IsVisible_t = function: Integer; cdecl;
  pfnEngSrc_pfnGetGameDirectory_t = function: PAnsiChar; cdecl;
  pfnEngSrc_pfnGetCvarPointer_t = function(szName: PAnsiChar): PCVar; cdecl;
  pfnEngSrc_Key_LookupBinding_t = function(pBinding: PAnsiChar): PAnsiChar; cdecl;
  pfnEngSrc_pfnGetLevelName_t = function: PAnsiChar; cdecl;
  pfnEngSrc_pfnGetScreenFade_t = procedure(var fade: screenfade_s); cdecl;
  pfnEngSrc_pfnSetScreenFade_t = procedure(const fade: screenfade_s); cdecl;
  pfnEngSrc_VGui_GetPanel_t = function: Pointer; cdecl;
  pfnEngSrc_VGui_ViewportPaintBackground_t = procedure(extents: PInteger); cdecl;
  pfnEngSrc_COM_LoadFile_t = function(path: PAnsiChar; usehunk: Integer; var pLength: Integer): PByte; cdecl;
  pfnEngSrc_COM_ParseFile_t = function(data, token: PAnsiChar): PAnsiChar; cdecl;
  pfnEngSrc_COM_FreeFile_t = procedure(buffer: Pointer); cdecl;
  pfnEngSrc_IsSpectateOnly_t = function: Integer; cdecl;
  pfnEngSrc_LoadMapSprite_t = function(filename: PAnsiChar): PModel; cdecl;
  pfnEngSrc_COM_AddAppDirectoryToSearchPath_t = procedure(pszBaseDir, appName: PAnsiChar); cdecl;
  pfnEngSrc_COM_ExpandFilename_t = function(fileName: PAnsiChar; nameOutBuffer: PAnsiChar; nameOutBufferSize: Integer): Integer; cdecl;
  pfnEngSrc_PlayerInfo_ValueForKey_t = function(playerNum: Integer; key: PAnsiChar): PAnsiChar; cdecl;
  pfnEngSrc_PlayerInfo_SetValueForKey_t = procedure(key, value: PAnsiChar); cdecl;
  pfnEngSrc_GetPlayerUniqueID_t = function(iPlayer: Integer; playerID: PAnsiChar): qboolean; cdecl;
  pfnEngSrc_GetTrackerIDForPlayer_t = function(playerSlot: Integer): Integer; cdecl;
  pfnEngSrc_GetPlayerForTrackerID_t = function(trackerID: Integer): Integer; cdecl;
  pfnEngSrc_pfnServerCmdUnreliable_t = function(szCmdString: PAnsiChar): Integer; cdecl;
  pfnEngSrc_GetMousePos_t = procedure(var ppt: POINT_s); cdecl;
  pfnEngSrc_SetMousePos_t = procedure(x, y: Integer); cdecl;
  pfnEngSrc_SetMouseEnable_t = procedure(fEnable: qboolean); cdecl;
  pfnEngSrc_GetFirstCVarPtr_t = function: PCVar; cdecl;
  pfnEngSrc_GetFirstCmdFunctionHandle_t = function: PCmdFunction; cdecl;
  pfnEngSrc_GetNextCmdFunctionHandle_t = function: PCmdFunction; cdecl;
  pfnEngSrc_GetCmdFunctionName_t = function(const cmdhandle: cmd_function_s): PAnsiChar; cdecl;
  pfnEngSrc_GetClientOldTime_t = function: Single; cdecl;
  pfnEngSrc_GetServerGravityValue_t = function: Single; cdecl;
  pfnEngSrc_GetModelByIndex_t = function(index: Integer): PModel; cdecl;
  pfnEngSrc_pfnSetFilterMode_t = procedure(mode: Integer); cdecl;
  pfnEngSrc_pfnSetFilterColor_t = procedure(r, g, b: Single); cdecl;
  pfnEngSrc_pfnSetFilterBrightness_t = procedure(brightness: Single); cdecl;
  pfnEngSrc_pfnSequenceGet_t = function(fileName, entryName: PAnsiChar): PSequenceEntry; cdecl;
  pfnEngSrc_pfnSPR_DrawGeneric_t = procedure(frame, x, y: Integer; const prc: rect_s; src, dest, w, h: Integer); cdecl;
  pfnEngSrc_pfnSequencePickSentence_t = function(sentenceName: PAnsiChar; pickMethod: Integer; var entryPicked: Integer): PSentenceEntry; cdecl;
  // draw a complete string
  pfnEngSrc_pfnDrawString_t = function(x, y: Integer; str: PAnsiChar; r, g, b: Integer): Integer; cdecl;
  pfnEngSrc_pfnDrawStringReverse_t = function(x, y: Integer; str: PAnsiChar; r, g, b: Integer): Integer; cdecl;
  pfnEngSrc_LocalPlayerInfo_ValueForKey_t = function(key: PAnsiChar): PAnsiChar; cdecl;
  pfnEngSrc_pfnVGUI2DrawCharacter_t = function(x, y, ch: Integer; font: Cardinal): Integer; cdecl;
  pfnEngSrc_pfnVGUI2DrawCharacterAdd_t = function(x, y, ch, r, g, b: Integer; font: Cardinal): Integer; cdecl;
  pfnEngSrc_COM_GetApproxWavePlayLength = function(filename: PAnsiChar): Cardinal; cdecl;
  pfnEngSrc_pfnGetCareerUI_t = function: Pointer; cdecl;
  pfnEngSrc_Cvar_Set_t = procedure(cvar: PAnsiChar; value: PAnsiChar); cdecl;
  pfnEngSrc_pfnIsPlayingCareerMatch_t = function: Integer; cdecl;
  pfnEngSrc_GetAbsoluteTime_t = function: Double; cdecl; // Sys_FloatTime
  pfnEngSrc_pfnProcessTutorMessageDecayBuffer_t = procedure(buffer: Pointer; bufferLength: Integer); cdecl;
  pfnEngSrc_pfnConstructTutorMessageDecayBuffer_t = procedure(buffer: Pointer; bufferLength: Integer); cdecl;
  pfnEngSrc_pfnResetTutorMessageDecayData_t = procedure; cdecl;
  pfnEngSrc_pfnFillRGBABlend_t = procedure(x, y, width, height, r, g, b, a: Integer); cdecl;
  pfnEngSrc_pfnGetAppID_t = function: Integer; cdecl;
  pfnEngSrc_pfnGetAliases_t = function: PCmdAlias; cdecl;
  pfnEngSrc_pfnVguiWrap2_GetMouseDelta_t = procedure(var x, y: Integer); cdecl;
  pfnEngSrc_pfnFilteredClientCmd_t = function(pszCmdString: PAnsiChar): Integer; cdecl;

  // client blending
  r_studio_interface_s = record
    version: Integer;
    StudioDrawModel: function(flags: Integer): Integer; cdecl;
    StudioDrawPlayer: function(flags: Integer; const pplayer: entity_state_s): Integer; cdecl;
  end;
  r_studio_interface_t = r_studio_interface_s;

  TRStudioInterface = r_studio_interface_s;
  PRStudioInterface = ^r_studio_interface_s;
  PPRStudioInterface = ^PRStudioInterface;

  // @xref: R_AddToStudioCache
  r_studiocache_t = record
    frame: Single;
    sequence: Integer;
    angles: vec3_t;
    origin: vec3_t;
    size: vec3_t;
    controller: array[0..3] of Byte;
    blending: array[0..1] of Byte;
    pModel: ^model_t;
    nStartHull: Integer;
    nStartPlane: Integer;
    numhulls: Integer;
  end;

  TRStudioCache = r_studiocache_t;
  PRStudioCache = ^r_studiocache_t;
  {$IF SizeOf(TRStudioCache) <> 68} {$MESSAGE WARN 'Structure size mismatch @ TRStudioCache.'} {$DEFINE MSME} {$IFEND}

  alight_s = record
    ambientlight: Integer;	// clip at 128
    shadelight: Integer;		// clip at 192 - ambientlight
    color: vec3_t;
    plightvec: PSingle;
  end;
  alight_t = alight_s;

  TALignt = alight_s;
  PALight = ^alight_s;

const
  STUDIO_INTERFACE_VERSION = 1;

type
  engine_studio_api_s = record
    // Allocate number*size bytes and zero it
    Mem_Calloc: function(number: Integer; size: NativeUInt): Pointer; cdecl;
    // Check to see if pointer is in the cache
    Cache_Check: function(const c: cache_user_s): Pointer; cdecl;
    // Load file into cache ( can be swapped out on demand )
    LoadCacheFile: procedure(path: PAnsiChar; const cu: cache_user_s); cdecl;
    // Retrieve model pointer for the named model
    Mod_ForName: function(name: PAnsiChar; crash_if_missing: Integer): PModel; cdecl;
    // Retrieve pointer to studio model data block from a model
    Mod_Extradata: function(const &mod: model_s): Pointer; cdecl;
    // Retrieve indexed model from client side model precache list
    GetModelByIndex: function(index: Integer): PModel; cdecl;
    // Get entity that is set for rendering
    GetCurrentEntity: function: PCLEntity; cdecl;
    // Get referenced player_info_t
    PlayerInfo: function(index: Integer): PPlayerInfo; cdecl;
    // Get most recently received player state data from network system
    GetPlayerState: function(index: Integer): PEntityState; cdecl;
    // Get viewentity
    GetViewEntity: function: PCLEntity; cdecl;
    // Get current frame count, and last two timestampes on client
    GetTimes: procedure(var framecount: Integer; var current, old: Double); cdecl;
    // Get a pointer to a cvar by name
    GetCvar: function(name: PAnsiChar): PCVar; cdecl;
    // Get current render origin and view vectors ( up, right and vpn )
    GetViewInfo: procedure(var origin, upv, rightv, vpnv: vec3_t); cdecl;
    // Get sprite model used for applying chrome effect
    GetChromeSprite: function: PModel; cdecl;
    // Get model counters so we can incement instrumentation
    GetModelCounters: procedure(var s, a: PInteger); cdecl;
    // Get software scaling coefficients
    GetAliasScale: procedure(var x, y: Single); cdecl;

    // Get bone, light, alias, and rotation matrices
    StudioGetBoneTransform: function: Pointer; cdecl;
    StudioGetLightTransform: function: Pointer; cdecl;
    StudioGetAliasTransform: function: Pointer; cdecl;
    StudioGetRotationMatrix: function: Pointer; cdecl;

    // Set up body part, and get submodel pointers
    StudioSetupModel: procedure(bodypart: Integer; var ppbodypart: Pointer; var ppsubmodel: Pointer); cdecl;
    // Check if entity's bbox is in the view frustum
    StudioCheckBBox: function: qboolean; cdecl;
    // Apply lighting effects to model
    StudioDynamicLight: procedure(const ent: cl_entity_s; var plight: alight_s); cdecl;
    StudioEntityLight: procedure(var plight: alight_s); cdecl;
    StudioSetupLighting: procedure(const plighting: alight_s);

    // Draw mesh vertices
    StudioDrawPoints: procedure; cdecl;

    // Draw hulls around bones
    StudioDrawHulls: procedure; cdecl;
    // Draw bbox around studio models
    StudioDrawAbsBBox: procedure; cdecl;
    // Draws bones
    StudioDrawBones: procedure; cdecl;
    // Loads in appropriate texture for model
    StudioSetupSkin: procedure(ptexturehdr: Pointer; index: Integer); cdecl;
    // Sets up for remapped colors
    StudioSetRemapColors: procedure(top, bottom: Integer); cdecl;
    // Set's player model and returns model pointer
    SetupPlayerModel: function(index: Integer): PModel; cdecl;
    // Fires any events embedded in animation
    StudioClientEvents: procedure; cdecl;
    // Retrieve/set forced render effects flags
    GetForceFaceFlags: function: Integer; cdecl;
    SetForceFaceFlags: procedure(flags: Integer); cdecl;
    // Tell engine the value of the studio model header
    StudioSetHeader: procedure(header: Pointer); cdecl;
    // Tell engine which model_t * is being renderered
    SetRenderModel: procedure(const model: model_s); cdecl;

    // Final state setup and restore for rendering
    SetupRenderer: procedure(rendermode: Integer); cdecl;
    RestoreRenderer: procedure; cdecl;

    // Set render origin for applying chrome effect
    SetChromeOrigin: procedure; cdecl;

    // True if using D3D/OpenGL
    IsHardware: function: Integer;

    // Only called by hardware interface
    GL_StudioDrawShadow: procedure; cdecl;
    GL_SetRenderMode: procedure(mode: Integer); cdecl;

    StudioSetRenderamt: procedure(iRenderamt: Integer); 	//!!!CZERO added for rendering glass on viewmodels
    StudioSetCullState: procedure(iCull: Integer);
    StudioRenderShadow: procedure(iSprite: Integer; const p1, p2, p3, p4: vec3_t); cdecl;
  end;
  engine_studio_api_t = engine_studio_api_s;

  TEngineStudioAPI = engine_studio_api_s;
  PEngineStudioAPI = ^engine_studio_api_s;

  cl_enginefuncs_s = record
    pfnSPR_Load: pfnEngSrc_pfnSPR_Load_t;
    pfnSPR_Frames: pfnEngSrc_pfnSPR_Frames_t;
    pfnSPR_Height: pfnEngSrc_pfnSPR_Height_t;
    pfnSPR_Width: pfnEngSrc_pfnSPR_Width_t;
    pfnSPR_Set: pfnEngSrc_pfnSPR_Set_t;
    pfnSPR_Draw: pfnEngSrc_pfnSPR_Draw_t;
    pfnSPR_DrawHoles: pfnEngSrc_pfnSPR_DrawHoles_t;
    pfnSPR_DrawAdditive: pfnEngSrc_pfnSPR_DrawAdditive_t;
    pfnSPR_EnableScissor: pfnEngSrc_pfnSPR_EnableScissor_t;
    pfnSPR_DisableScissor: pfnEngSrc_pfnSPR_DisableScissor_t;
    pfnSPR_GetList: pfnEngSrc_pfnSPR_GetList_t;
    pfnFillRGBA: pfnEngSrc_pfnFillRGBA_t;
    pfnGetScreenInfo: pfnEngSrc_pfnGetScreenInfo_t;
    pfnSetCrosshair: pfnEngSrc_pfnSetCrosshair_t;
    pfnRegisterVariable: pfnEngSrc_pfnRegisterVariable_t;
    pfnGetCvarFloat: pfnEngSrc_pfnGetCvarFloat_t;
    pfnGetCvarString: pfnEngSrc_pfnGetCvarString_t;
    pfnAddCommand: pfnEngSrc_pfnAddCommand_t;
    pfnHookUserMsg: pfnEngSrc_pfnHookUserMsg_t;
    pfnServerCmd: pfnEngSrc_pfnServerCmd_t;
    pfnClientCmd: pfnEngSrc_pfnClientCmd_t;
    pfnGetPlayerInfo: pfnEngSrc_pfnGetPlayerInfo_t;
    pfnPlaySoundByName: pfnEngSrc_pfnPlaySoundByName_t;
    pfnPlaySoundByIndex: pfnEngSrc_pfnPlaySoundByIndex_t;
    pfnAngleVectors: pfnEngSrc_pfnAngleVectors_t;
    pfnTextMessageGet: pfnEngSrc_pfnTextMessageGet_t;
    pfnDrawCharacter: pfnEngSrc_pfnDrawCharacter_t;
    pfnDrawConsoleString: pfnEngSrc_pfnDrawConsoleString_t;
    pfnDrawSetTextColor: pfnEngSrc_pfnDrawSetTextColor_t;
    pfnDrawConsoleStringLen: pfnEngSrc_pfnDrawConsoleStringLen_t;
    pfnConsolePrint: pfnEngSrc_pfnConsolePrint_t;
    pfnCenterPrint: pfnEngSrc_pfnCenterPrint_t;
    GetWindowCenterX: pfnEngSrc_GetWindowCenterX_t;
    GetWindowCenterY: pfnEngSrc_GetWindowCenterY_t;
    GetViewAngles: pfnEngSrc_GetViewAngles_t;
    SetViewAngles: pfnEngSrc_SetViewAngles_t;
    GetMaxClients: pfnEngSrc_GetMaxClients_t;
    Cvar_SetValue: pfnEngSrc_Cvar_SetValue_t;
    Cmd_Argc: pfnEngSrc_Cmd_Argc_t;
    Cmd_Argv: pfnEngSrc_Cmd_Argv_t;
    Con_Printf: pfnEngSrc_Con_Printf_t;
    Con_DPrintf: pfnEngSrc_Con_DPrintf_t;
    Con_NPrintf: pfnEngSrc_Con_NPrintf_t;
    Con_NXPrintf: pfnEngSrc_Con_NXPrintf_t;
    PhysInfo_ValueForKey: pfnEngSrc_PhysInfo_ValueForKey_t;
    ServerInfo_ValueForKey: pfnEngSrc_ServerInfo_ValueForKey_t;
    GetClientMaxspeed: pfnEngSrc_GetClientMaxspeed_t;
    CheckParm: pfnEngSrc_CheckParm_t;
    Key_Event: pfnEngSrc_Key_Event_t;
    GetMousePosition: pfnEngSrc_GetMousePosition_t;
    IsNoClipping: pfnEngSrc_IsNoClipping_t;
    GetLocalPlayer: pfnEngSrc_GetLocalPlayer_t;
    GetViewModel: pfnEngSrc_GetViewModel_t;
    GetEntityByIndex: pfnEngSrc_GetEntityByIndex_t;
    GetClientTime: pfnEngSrc_GetClientTime_t;
    V_CalcShake: pfnEngSrc_V_CalcShake_t;
    V_ApplyShake: pfnEngSrc_V_ApplyShake_t;
    PM_PointContents: pfnEngSrc_PM_PointContents_t;
    PM_WaterEntity: pfnEngSrc_PM_WaterEntity_t;
    PM_TraceLine: pfnEngSrc_PM_TraceLine_t;
    CL_LoadModel: pfnEngSrc_CL_LoadModel_t;
    CL_CreateVisibleEntity: pfnEngSrc_CL_CreateVisibleEntity_t;
    GetSpritePointer: pfnEngSrc_GetSpritePointer_t;
    pfnPlaySoundByNameAtLocation: pfnEngSrc_pfnPlaySoundByNameAtLocation_t;
    pfnPrecacheEvent: pfnEngSrc_pfnPrecacheEvent_t;
    pfnPlaybackEvent: pfnEngSrc_pfnPlaybackEvent_t;
    pfnWeaponAnim: pfnEngSrc_pfnWeaponAnim_t;
    pfnRandomFloat: pfnEngSrc_pfnRandomFloat_t;
    pfnRandomLong: pfnEngSrc_pfnRandomLong_t;
    pfnHookEvent: pfnEngSrc_pfnHookEvent_t;
    Con_IsVisible: pfnEngSrc_Con_IsVisible_t;
    pfnGetGameDirectory: pfnEngSrc_pfnGetGameDirectory_t;
    pfnGetCvarPointer: pfnEngSrc_pfnGetCvarPointer_t;
    Key_LookupBinding: pfnEngSrc_Key_LookupBinding_t;
    GetLevelName: pfnEngSrc_pfnGetLevelName_t;
    pfnGetScreenFade: pfnEngSrc_pfnGetScreenFade_t;
    pfnSetScreenFade: pfnEngSrc_pfnSetScreenFade_t;
    VGui_GetPanel: pfnEngSrc_VGui_GetPanel_t;
    VGui_ViewportPaintBackground: pfnEngSrc_VGui_ViewportPaintBackground_t;
    COM_LoadFile: pfnEngSrc_COM_LoadFile_t;
    COM_ParseFile: pfnEngSrc_COM_ParseFile_t;
    COM_FreeFile: pfnEngSrc_COM_FreeFile_t;

    pTriAPI: ^triangleapi_s;
    pEfxAPI: ^efx_api_s;
    pEventAPI: ^event_api_s;
    pDemoAPI: ^demo_api_s;
    pNetAPI: ^net_api_s;
    pVoiceTweak: ^IVoiceTweak_s;

    IsSpectateOnly: pfnEngSrc_IsSpectateOnly_t;
    LoadMapSprite: pfnEngSrc_LoadMapSprite_t;
    COM_AddAppDirectoryToSearchPath: pfnEngSrc_COM_AddAppDirectoryToSearchPath_t;
    COM_ExpandFilename: pfnEngSrc_COM_ExpandFilename_t;
    PlayerInfo_ValueForKey: pfnEngSrc_PlayerInfo_ValueForKey_t;
    PlayerInfo_SetValueForKey: pfnEngSrc_PlayerInfo_SetValueForKey_t;
    GetPlayerUniqueID: pfnEngSrc_GetPlayerUniqueID_t;
    GetTrackerIDForPlayer: pfnEngSrc_GetTrackerIDForPlayer_t;
    GetPlayerForTrackerID: pfnEngSrc_GetPlayerForTrackerID_t;
    pfnServerCmdUnreliable: pfnEngSrc_pfnServerCmdUnreliable_t;
    pfnGetMousePos: pfnEngSrc_GetMousePos_t;
    pfnSetMousePos: pfnEngSrc_SetMousePos_t;
    pfnSetMouseEnable: pfnEngSrc_SetMouseEnable_t;
    GetFirstCvarPtr: pfnEngSrc_GetFirstCVarPtr_t;
    GetFirstCmdFunctionHandle: pfnEngSrc_GetFirstCmdFunctionHandle_t;
    GetNextCmdFunctionHandle: pfnEngSrc_GetNextCmdFunctionHandle_t;
    GetCmdFunctionName: pfnEngSrc_GetCmdFunctionName_t;
    hudGetClientOldTime: pfnEngSrc_GetClientOldTime_t;
    hudGetServerGravityValue: pfnEngSrc_GetServerGravityValue_t;
    hudGetModelByIndex: pfnEngSrc_GetModelByIndex_t;
    pfnSetFilterMode: pfnEngSrc_pfnSetFilterMode_t;
    pfnSetFilterColor: pfnEngSrc_pfnSetFilterColor_t;
    pfnSetFilterBrightness: pfnEngSrc_pfnSetFilterBrightness_t;
    pfnSequenceGet: pfnEngSrc_pfnSequenceGet_t;
    pfnSPR_DrawGeneric: pfnEngSrc_pfnSPR_DrawGeneric_t;
    pfnSequencePickSentence: pfnEngSrc_pfnSequencePickSentence_t;
    pfnDrawString: pfnEngSrc_pfnDrawString_t;
    pfnDrawStringReverse: pfnEngSrc_pfnDrawStringReverse_t;
    LocalPlayerInfo_ValueForKey: pfnEngSrc_LocalPlayerInfo_ValueForKey_t;
    pfnVGUI2DrawCharacter: pfnEngSrc_pfnVGUI2DrawCharacter_t;
    pfnVGUI2DrawCharacterAdd: pfnEngSrc_pfnVGUI2DrawCharacterAdd_t;
    COM_GetApproxWavePlayLength: pfnEngSrc_COM_GetApproxWavePlayLength;
    pfnGetCareerUI: pfnEngSrc_pfnGetCareerUI_t;
    Cvar_Set: pfnEngSrc_Cvar_Set_t;
    pfnIsCareerMatch: pfnEngSrc_pfnIsPlayingCareerMatch_t;
    pfnPlaySoundVoiceByName: pfnEngSrc_pfnPlaySoundVoiceByName_t;
    pfnPrimeMusicStream: pfnEngSrc_pfnPrimeMusicStream_t;
    GetAbsoluteTime: pfnEngSrc_GetAbsoluteTime_t;
    pfnProcessTutorMessageDecayBuffer: pfnEngSrc_pfnProcessTutorMessageDecayBuffer_t;
    pfnConstructTutorMessageDecayBuffer: pfnEngSrc_pfnConstructTutorMessageDecayBuffer_t;
    pfnResetTutorMessageDecayData: pfnEngSrc_pfnResetTutorMessageDecayData_t;
    pfnPlaySoundByNameAtPitch: pfnEngSrc_pfnPlaySoundByNameAtPitch_t;
    pfnFillRGBABlend: pfnEngSrc_pfnFillRGBABlend_t;
    pfnGetAppID: pfnEngSrc_pfnGetAppID_t;
    pfnGetAliasList: pfnEngSrc_pfnGetAliases_t;
    pfnVguiWrap2_GetMouseDelta: pfnEngSrc_pfnVguiWrap2_GetMouseDelta_t;
    pfnFilteredClientCmd: pfnEngSrc_pfnFilteredClientCmd_t;
  end;
  cl_enginefunc_t = cl_enginefuncs_s;

  TCLEngineFunc = cl_enginefuncs_s;
  PCLEngineFunc = ^cl_enginefuncs_s;

  // ********************************************************
  // Functions exported by the client .dll
  // ********************************************************

  pfnCallback_AddVisibleEntity_t = function(const pEntity: cl_entity_s): Integer; cdecl;
  pfnCallback_TempEntPlaySound_t = procedure(const pTemp: tempent_s; damp: Single); cdecl;

  // Function type declarations for client exports
  INITIALIZE_FUNC = function(const pEnginefuncs: cl_enginefunc_t; iVersion: Integer): Integer; cdecl;
  HUD_INIT_FUNC = procedure; cdecl;
  HUD_VIDINIT_FUNC = function: Integer; cdecl;
  HUD_REDRAW_FUNC = function(time: Single; intermission: Integer): Integer; cdecl;
  HUD_UPDATECLIENTDATA_FUNC = function(var pcldata: client_data_t): Integer; cdecl;
  HUD_RESET_FUNC = procedure; cdecl;
  HUD_CLIENTMOVE_FUNC = procedure(const ppmove: playermove_s; server: qboolean); cdecl;
  HUD_CLIENTMOVEINIT_FUNC = procedure(const ppmove: playermove_s); cdecl;
  HUD_TEXTURETYPE_FUNC = function(name: PAnsiChar): AnsiChar; cdecl;
  HUD_IN_ACTIVATEMOUSE_FUNC = procedure; cdecl;
  HUD_IN_DEACTIVATEMOUSE_FUNC = procedure; cdecl;
  HUD_IN_MOUSEEVENT_FUNC = procedure(mstate: Integer); cdecl;
  HUD_IN_CLEARSTATES_FUNC = procedure; cdecl;
  HUD_IN_ACCUMULATE_FUNC = procedure; cdecl;
  HUD_CL_CREATEMOVE_FUNC = procedure(frametime: Single; var cmd: usercmd_s; active: Integer); cdecl;
  HUD_CL_ISTHIRDPERSON_FUNC = function: Integer; cdecl;
  HUD_CL_GETCAMERAOFFSETS_FUNC = procedure(var ofs: vec3_t); cdecl;
  HUD_KB_FIND_FUNC = function(name: PAnsiChar): PKButton; cdecl;
  HUD_CAMTHINK_FUNC = procedure; cdecl;
  HUD_CALCREF_FUNC = procedure(const pparams: ref_params_s); cdecl;
  HUD_ADDENTITY_FUNC = function(&type: Integer; var ent: cl_entity_s; modelname: PAnsiChar): Integer; cdecl;
  HUD_CREATEENTITIES_FUNC = procedure; cdecl;
  HUD_DRAWNORMALTRIS_FUNC = procedure; cdecl;
  HUD_DRAWTRANSTRIS_FUNC = procedure; cdecl;
  HUD_STUDIOEVENT_FUNC = procedure(const event: mstudioevent_s; const entity: cl_entity_s); cdecl;
  HUD_POSTRUNCMD_FUNC = procedure(const from: local_state_s; var &to: local_state_s; const cmd: usercmd_s; runfuncs: Integer; time: Double; random_seed: Cardinal); cdecl;
  HUD_SHUTDOWN_FUNC = procedure; cdecl;
  HUD_TXFERLOCALOVERRIDES_FUNC = procedure(var state: entity_state_s; const client: clientdata_s); cdecl;
  HUD_PROCESSPLAYERSTATE_FUNC = procedure(var dst: entity_state_s; const src: entity_state_s); cdecl;
  HUD_TXFERPREDICTIONDATA_FUNC = procedure(var ps: entity_state_s; const pps: entity_state_s; var pcd: clientdata_s; const ppcd: clientdata_s; var wd: weapon_data_s; const pwd: weapon_data_s); cdecl;
  HUD_DEMOREAD_FUNC = procedure(size: Integer; buffer: PByte); cdecl;
  HUD_CONNECTIONLESS_FUNC = function(const net_from_: netadr_s; args: PAnsiChar; response_buffer: PAnsiChar; var response_buffer_size: Integer): Integer; cdecl;
  HUD_GETHULLBOUNDS_FUNC = function(hullnumber: Integer; var mins, maxs: vec3_t): Integer; cdecl;
  HUD_FRAME_FUNC = procedure(time: Double); cdecl;
  HUD_KEY_EVENT_FUNC = function(eventcode, keynum: Integer; pszCurrentBinding: PAnsiChar): Integer; cdecl;
  HUD_TEMPENTUPDATE_FUNC = procedure(frametime, client_time, cl_gravity: Double; ppTempEntFree: PPTempEntity; ppTempEntActive: PPTempEntity; Callback_AddVisibleEntity: pfnCallback_AddVisibleEntity_t; Callback_TempEntPlaySound: pfnCallback_TempEntPlaySound_t); cdecl;
  HUD_GETUSERENTITY_FUNC = function(index: Integer): PCLEntity; cdecl;
  HUD_VOICESTATUS_FUNC = procedure(entindex: Integer; bTalking: qboolean); cdecl;
  HUD_DIRECTORMESSAGE_FUNC = procedure(iSize: Integer; pbuf: Pointer); cdecl;
  HUD_STUDIO_INTERFACE_FUNC = function(version: Integer; var ppinterface: PRStudioInterface; var pstudio: engine_studio_api_s): Integer; cdecl;
  HUD_CHATINPUTPOSITION_FUNC = procedure(x, y: Integer); cdecl;
  HUD_GETPLAYERTEAM = function(iplayer: Integer): Integer; cdecl;
  CLIENTFACTORY = function: Pointer; cdecl; // this should be CreateInterfaceFn but that means including interface.h
                                            // which is a C++ file and some of the client files a C only...
                                            // so we return a void * which we then do a typecast on later.

  // Pointers to the exported client functions themselves
  cldll_func_t = record
    pInitFunc: INITIALIZE_FUNC;
    pHudInitFunc: HUD_INIT_FUNC;
    pHudVidInitFunc: HUD_VIDINIT_FUNC;
    pHudRedrawFunc: HUD_REDRAW_FUNC;
    pHudUpdateClientDataFunc: HUD_UPDATECLIENTDATA_FUNC;
    pHudResetFunc: HUD_RESET_FUNC;
    pClientMove: HUD_CLIENTMOVE_FUNC;
    pClientMoveInit: HUD_CLIENTMOVEINIT_FUNC;
    pClientTextureType: HUD_TEXTURETYPE_FUNC;
    pIN_ActivateMouse: HUD_IN_ACTIVATEMOUSE_FUNC;
    pIN_DeactivateMouse: HUD_IN_DEACTIVATEMOUSE_FUNC;
    pIN_MouseEvent: HUD_IN_MOUSEEVENT_FUNC;
    pIN_ClearStates: HUD_IN_CLEARSTATES_FUNC;
    pIN_Accumulate: HUD_IN_ACCUMULATE_FUNC;
    pCL_CreateMove: HUD_CL_CREATEMOVE_FUNC;
    pCL_IsThirdPerson: HUD_CL_ISTHIRDPERSON_FUNC;
    pCL_GetCameraOffsets: HUD_CL_GETCAMERAOFFSETS_FUNC;
    pFindKey: HUD_KB_FIND_FUNC;
    pCamThink: HUD_CAMTHINK_FUNC;
    pCalcRefdef: HUD_CALCREF_FUNC;
    pAddEntity: HUD_ADDENTITY_FUNC;
    pCreateEntities: HUD_CREATEENTITIES_FUNC;
    pDrawNormalTriangles: HUD_DRAWNORMALTRIS_FUNC;
    pDrawTransparentTriangles: HUD_DRAWTRANSTRIS_FUNC;
    pStudioEvent: HUD_STUDIOEVENT_FUNC;
    pPostRunCmd: HUD_POSTRUNCMD_FUNC;
    pShutdown: HUD_SHUTDOWN_FUNC;
    pTxferLocalOverrides: HUD_TXFERLOCALOVERRIDES_FUNC;
    pProcessPlayerState: HUD_PROCESSPLAYERSTATE_FUNC;
    pTxferPredictionData: HUD_TXFERPREDICTIONDATA_FUNC;
    pReadDemoBuffer: HUD_DEMOREAD_FUNC;
    pConnectionlessPacket: HUD_CONNECTIONLESS_FUNC;
    pGetHullBounds: HUD_GETHULLBOUNDS_FUNC;
    pHudFrame: HUD_FRAME_FUNC;
    pKeyEvent: HUD_KEY_EVENT_FUNC;
    pTempEntUpdate: HUD_TEMPENTUPDATE_FUNC;
    pGetUserEntity: HUD_GETUSERENTITY_FUNC;
    pVoiceStatus: HUD_VOICESTATUS_FUNC;		// Possibly null on old client dlls.
    pDirectorMessage: HUD_DIRECTORMESSAGE_FUNC;	// Possibly null on old client dlls.
    pStudioInterface: HUD_STUDIO_INTERFACE_FUNC;	// Not used by all clients
    pChatInputPosition: HUD_CHATINPUTPOSITION_FUNC;	// Not used by all clients
    pGetPlayerTeam: HUD_GETPLAYERTEAM; // Not used by all clients
    pClientFactory: CLIENTFACTORY;
  end;

  TCLDLLFunc = cldll_func_t;
  PCLDLLFunc = ^cldll_func_t;

  DST_INITIALIZE_FUNC = procedure(var pEnginefuncs: PCLEngineFunc; var iVersion: Integer); cdecl;
  DST_HUD_INIT_FUNC = procedure; cdecl;
  DST_HUD_VIDINIT_FUNC = procedure; cdecl;
  DST_HUD_REDRAW_FUNC = procedure(var time: Single; var intermission: Integer); cdecl;
  DST_HUD_UPDATECLIENTDATA_FUNC = procedure(var pcldata: PClient_Data); cdecl;
  DST_HUD_RESET_FUNC = procedure; cdecl;
  DST_HUD_CLIENTMOVE_FUNC = procedure(var ppmove: PPlayerMove; var server: qboolean); cdecl;
  DST_HUD_CLIENTMOVEINIT_FUNC = procedure(var ppmove: PPlayerMove); cdecl;
  DST_HUD_TEXTURETYPE_FUNC = procedure(var name: PAnsiChar); cdecl;
  DST_HUD_IN_ACTIVATEMOUSE_FUNC = procedure; cdecl;
  DST_HUD_IN_DEACTIVATEMOUSE_FUNC = procedure; cdecl;
  DST_HUD_IN_MOUSEEVENT_FUNC = procedure(var mstate: Integer); cdecl;
  DST_HUD_IN_CLEARSTATES_FUNC = procedure; cdecl;
  DST_HUD_IN_ACCUMULATE_FUNC = procedure; cdecl;
  DST_HUD_CL_CREATEMOVE_FUNC = procedure(var frametime: Single; var cmd: PUserCmd; var active: Integer); cdecl;
  DST_HUD_CL_ISTHIRDPERSON_FUNC = procedure; cdecl;
  DST_HUD_CL_GETCAMERAOFFSETS_FUNC = procedure(var ofs: PVec3); cdecl;
  DST_HUD_KB_FIND_FUNC = procedure(var name: PAnsiChar); cdecl;
  DST_HUD_CAMTHINK_FUNC = procedure; cdecl;
  DST_HUD_CALCREF_FUNC = procedure(var pparams: PRefParms); cdecl;
  DST_HUD_ADDENTITY_FUNC = procedure(var &type: Integer; var ent: PCLEntity; var modelname: PAnsiChar); cdecl;
  DST_HUD_CREATEENTITIES_FUNC = procedure; cdecl;
  DST_HUD_DRAWNORMALTRIS_FUNC = procedure; cdecl;
  DST_HUD_DRAWTRANSTRIS_FUNC = procedure; cdecl;
  DST_HUD_STUDIOEVENT_FUNC = procedure(var event: PMStudioEvent; var entity: PCLEntity); cdecl;
  DST_HUD_POSTRUNCMD_FUNC = procedure(var from: PLocalState; var &to: PLocalState; var cmd: PUserCmd; var runfuncs: Integer; var time: Double; var random_seed: Cardinal); cdecl;
  DST_HUD_SHUTDOWN_FUNC = procedure; cdecl;
  DST_HUD_TXFERLOCALOVERRIDES_FUNC = procedure(var state: PEntityState; var client: PClientData); cdecl;
  DST_HUD_PROCESSPLAYERSTATE_FUNC = procedure(var dst: PEntityState; var src: PEntityState); cdecl;
  DST_HUD_TXFERPREDICTIONDATA_FUNC = procedure(var ps: PEntityState; var pps: PEntityState; var pcd: PClientData; var ppcd: PClientData; var wd: PWeaponData; var pwd: PWeaponData); cdecl;
  DST_HUD_DEMOREAD_FUNC = procedure(var size: Integer; var buffer: PByte); cdecl;
  DST_HUD_CONNECTIONLESS_FUNC = procedure(var net_from_: PNetAdr; var args: PAnsiChar; var response_buffer: PAnsiChar; var response_buffer_size: PInteger); cdecl;
  DST_HUD_GETHULLBOUNDS_FUNC = procedure(var hullnumber: Integer; var mins, maxs: PVec3); cdecl;
  DST_HUD_FRAME_FUNC = procedure(var time: Double); cdecl;
  DST_HUD_KEY_EVENT_FUNC = procedure(var eventcode, keynum: Integer; var pszCurrentBinding: PAnsiChar); cdecl;
  DST_HUD_TEMPENTUPDATE_FUNC = procedure(var frametime, client_time, cl_gravity: Double; var ppTempEntFree: PPTempEntity; var ppTempEntActive: PPTempEntity; var Callback_AddVisibleEntity: pfnCallback_AddVisibleEntity_t; var Callback_TempEntPlaySound: pfnCallback_TempEntPlaySound_t); cdecl;
  DST_HUD_GETUSERENTITY_FUNC = procedure(var index: Integer); cdecl;
  DST_HUD_VOICESTATUS_FUNC = procedure(var entindex: Integer; var bTalking: qboolean); cdecl;
  DST_HUD_DIRECTORMESSAGE_FUNC = procedure(var iSize: Integer; var pbuf: Pointer); cdecl;
  DST_HUD_STUDIO_INTERFACE_FUNC = procedure(var version: Integer; var ppinterface: PPRStudioInterface; var pstudio: PEngineStudioAPI); cdecl;
  DST_HUD_CHATINPUTPOSITION_FUNC = procedure(var x, y: Integer); cdecl;
  DST_HUD_GETPLAYERTEAM = procedure(var iplayer: Integer); cdecl;

  // Pointers to the client destination functions
  cldll_func_dst_t = record
    pInitFunc: INITIALIZE_FUNC;
    pHudInitFunc: DST_HUD_INIT_FUNC;
    pHudVidInitFunc: DST_HUD_VIDINIT_FUNC;
    pHudRedrawFunc: DST_HUD_REDRAW_FUNC;
    pHudUpdateClientDataFunc: DST_HUD_UPDATECLIENTDATA_FUNC;
    pHudResetFunc: DST_HUD_RESET_FUNC;
    pClientMove: DST_HUD_CLIENTMOVE_FUNC;
    pClientMoveInit: DST_HUD_CLIENTMOVEINIT_FUNC;
    pClientTextureType: DST_HUD_TEXTURETYPE_FUNC;
    pIN_ActivateMouse: DST_HUD_IN_ACTIVATEMOUSE_FUNC;
    pIN_DeactivateMouse: DST_HUD_IN_DEACTIVATEMOUSE_FUNC;
    pIN_MouseEvent: DST_HUD_IN_MOUSEEVENT_FUNC;
    pIN_ClearStates: DST_HUD_IN_CLEARSTATES_FUNC;
    pIN_Accumulate: DST_HUD_IN_ACCUMULATE_FUNC;
    pCL_CreateMove: DST_HUD_CL_CREATEMOVE_FUNC;
    pCL_IsThirdPerson: DST_HUD_CL_ISTHIRDPERSON_FUNC;
    pCL_GetCameraOffsets: DST_HUD_CL_GETCAMERAOFFSETS_FUNC;
    pFindKey: DST_HUD_KB_FIND_FUNC;
    pCamThink: DST_HUD_CAMTHINK_FUNC;
    pCalcRefdef: DST_HUD_CALCREF_FUNC;
    pAddEntity: DST_HUD_ADDENTITY_FUNC;
    pCreateEntities: DST_HUD_CREATEENTITIES_FUNC;
    pDrawNormalTriangles: DST_HUD_DRAWNORMALTRIS_FUNC;
    pDrawTransparentTriangles: DST_HUD_DRAWTRANSTRIS_FUNC;
    pStudioEvent: DST_HUD_STUDIOEVENT_FUNC;
    pPostRunCmd: DST_HUD_POSTRUNCMD_FUNC;
    pShutdown: DST_HUD_SHUTDOWN_FUNC;
    pTxferLocalOverrides: DST_HUD_TXFERLOCALOVERRIDES_FUNC;
    pProcessPlayerState: DST_HUD_PROCESSPLAYERSTATE_FUNC;
    pTxferPredictionData: DST_HUD_TXFERPREDICTIONDATA_FUNC;
    pReadDemoBuffer: DST_HUD_DEMOREAD_FUNC;
    pConnectionlessPacket: DST_HUD_CONNECTIONLESS_FUNC;
    pGetHullBounds: DST_HUD_GETHULLBOUNDS_FUNC;
    pHudFrame: DST_HUD_FRAME_FUNC;
    pKeyEvent: DST_HUD_KEY_EVENT_FUNC;
    pTempEntUpdate: DST_HUD_TEMPENTUPDATE_FUNC;
    pGetUserEntity: DST_HUD_GETUSERENTITY_FUNC;
    pVoiceStatus: DST_HUD_VOICESTATUS_FUNC;		// Possibly null on old client dlls.
    pDirectorMessage: DST_HUD_DIRECTORMESSAGE_FUNC;	// Possibly null on old client dlls.
    pStudioInterface: DST_HUD_STUDIO_INTERFACE_FUNC;	// Not used by all clients
    pChatInputPosition: DST_HUD_CHATINPUTPOSITION_FUNC;	// Not used by all clients
    pGetPlayerTeam: DST_HUD_GETPLAYERTEAM; // Not used by all clients
  end;

  TCLDLLFuncDst = cldll_func_dst_t;
  PCLDLLFuncDst = ^cldll_func_dst_t;

  // Functions for ModuleS
  PFN_KICKPLAYER = procedure(nPlayerSlot, nReason: Integer); cdecl;

  modshelpers_s = record
    m_pfnKickPlayer: PFN_KICKPLAYER;

    // reserved for future expansion
    m_nVoid1: Integer;
    m_nVoid2: Integer;
    m_nVoid3: Integer;
    m_nVoid4: Integer;
    m_nVoid5: Integer;
    m_nVoid6: Integer;
    m_nVoid7: Integer;
    m_nVoid8: Integer;
    m_nVoid9: Integer;
  end;
  modshelpers_t = modshelpers_s;

  TModSHelpers = modshelpers_s;
  PModSHelpers = ^modshelpers_s;

  // Functions for moduleC
  modchelpers_s = record
    // reserved for future expansion
    m_nVoid0: Integer;
    m_nVoid1: Integer;
    m_nVoid2: Integer;
    m_nVoid3: Integer;
    m_nVoid4: Integer;
    m_nVoid5: Integer;
    m_nVoid6: Integer;
    m_nVoid7: Integer;
    m_nVoid8: Integer;
    m_nVoid9: Integer;
  end;
  modchelpers_t = modchelpers_s;

  TModCHelpers = modchelpers_s;
  PModCHelpers = ^modchelpers_s;

  // ********************************************************
  // Functions exposed by the security module
  // ********************************************************
  PFN_LOADMOD = procedure(pchModule: PAnsiChar); cdecl;
  PFN_CLOSEMOD = procedure; cdecl;
  PFN_NCALL = function(ijump: Integer; cnArg: Integer): Integer; cdecl varargs;

  PFN_GETCLDSTADDRS = procedure(var pcldstAddrs: cldll_func_dst_t); cdecl;
  PFN_GETENGDSTADDRS = procedure(var pengdstAddrs: cl_enginefunc_dst_t); cdecl;
  PFN_MODULELOADED = procedure; cdecl;

  PFN_PROCESSOUTGOINGNET = procedure(const pchan: netchan_s; const psizebuf: sizebuf_s); cdecl;
  PFN_PROCESSINCOMINGNET = function(const pchan: netchan_s; const psizebuf: sizebuf_s): qboolean; cdecl;

  PFN_TEXTURELOAD = procedure(pszName: PAnsiChar; dxWidth, dyHeight: Integer; pbData: PAnsiChar); cdecl;
  PFN_MODELLOAD = procedure(const pmodel: model_s; pvBuf: Pointer); cdecl;

  PFN_FRAMEBEGIN = procedure; cdecl;
  PFN_FRAMERENDER1 = procedure; cdecl;
  PFN_FRAMERENDER2 = procedure; cdecl;

  PFN_SETMODSHELPERS = procedure(const pmodshelpers: modshelpers_t); cdecl;
  PFN_SETMODCHELPERS = procedure(const pmodchelpers: modchelpers_t); cdecl;
  PFN_SETENGDATA = procedure(const pengdata: Pointer {engdata_t}); cdecl;

  PFN_CONNECTCLIENT = procedure(iPlayer: Integer); cdecl;
  PFN_RECORDIP = procedure(pnIP: Cardinal); cdecl;
  PFN_PLAYERSTATUS = procedure(pbData: PByte; cbData: Integer); cdecl;

  PFN_SETENGINEVERSION = procedure(nVersion: Integer); cdecl;

  PFN_PCMACHINE = function: Integer; cdecl;
  PFN_SETIP = procedure(ijump: Integer); cdecl;
  PFN_EXECUTE = procedure; cdecl;

  modfuncs_s = record
    // Functions for the pcode interpreter
    m_pfnLoadMod: PFN_LOADMOD;
    m_pfnCloseMod: PFN_CLOSEMOD;
    m_pfnNCall: PFN_NCALL;

    // API destination functions
    m_pfnGetClDstAddrs: PFN_GETCLDSTADDRS;
    m_pfnGetEngDstAddrs: PFN_GETENGDSTADDRS;

    // Miscellaneous functions
    m_pfnModuleLoaded: PFN_MODULELOADED;					// Called right after the module is loaded

    // Functions for processing network traffic
    m_pfnProcessOutgoingNet: PFN_PROCESSOUTGOINGNET;		// Every outgoing packet gets run through this
    m_pfnProcessIncomingNet: PFN_PROCESSINCOMINGNET;		// Every incoming packet gets run through this

    // Resource functions
    m_pfnTextureLoad: PFN_TEXTURELOAD;					// Called as each texture is loaded
    m_pfnModelLoad: PFN_MODELLOAD;						// Called as each model is loaded

    // Functions called every frame
    m_pfnFrameBegin: PFN_FRAMEBEGIN;						// Called at the beginning of each frame cycle
    m_pfnFrameRender1: PFN_FRAMERENDER1;					// Called at the beginning of the render loop
    m_pfnFrameRender2: PFN_FRAMERENDER2;					// Called at the end of the render loop

    // Module helper transfer
    m_pfnSetModSHelpers: PFN_SETMODSHELPERS;
    m_pfnSetModCHelpers: PFN_SETMODCHELPERS;
    m_pfnSetEngData: PFN_SETENGDATA;

    // Which version of the module is this?
    m_nVersion: Integer;

    // Miscellaneous game stuff
    m_pfnConnectClient: PFN_CONNECTCLIENT;				// Called whenever a new client connects
    m_pfnRecordIP: PFN_RECORDIP;							// Secure master has reported a new IP for us
    m_pfnPlayerStatus: PFN_PLAYERSTATUS;					// Called whenever we receive a PlayerStatus packet

    // Recent additions
    m_pfnSetEngineVersion: PFN_SETENGINEVERSION;			// 1 = patched engine

    // reserved for future expansion
    m_nVoid2: Integer;
    m_nVoid3: Integer;
    m_nVoid4: Integer;
    m_nVoid5: Integer;
    m_nVoid6: Integer;
    m_nVoid7: Integer;
    m_nVoid8: Integer;
    m_nVoid9: Integer;
  end;
  modfuncs_t = modfuncs_s;

  TModFuncs = modfuncs_s;
  PModFuncs = ^modfuncs_s;

  glwstate_t = record
    hInstance: HINST;
    wndproc: Pointer;
    hinstOpenGL: HINST;
    minidriver: qboolean;
    allowdisplaydepthchange: qboolean;
    mcd_accelerated: qboolean;
    log_fp: FileHandle_t;
  end;
  TGLWState = glwstate_t;
  PGLWState = ^glwstate_t;

  engdata_s = record
    pcl_enginefuncs: ^cl_enginefunc_t;					// functions exported by the engine
    pg_engdstAddrs: ^cl_enginefunc_dst_t;				// destination handlers for engine exports
    pcl_funcs: ^cldll_func_t;							      // client exports
    pg_cldstAddrs: ^cldll_func_dst_t;				  	// client export destination handlers
    pg_modfuncs: ^modfuncs_s;						        // engine's pointer to module functions
    pcmd_functions: ^PCmdFunction;				      // list of all registered commands
    pkeybindings: Pointer;									    // all key bindings (not really a void *, but easier this way)
    pfnConPrintf: procedure(Fmt: PAnsiChar); cdecl varargs; // dump to console
    pcvar_vars: ^PCVar;							            // pointer to head of cvar list
    pglwstate: ^glwstate_t;						          // OpenGl information
    pfnSZ_GetSpace: procedure(const buf: sizebuf_s; length: Integer);	// pointer to SZ_GetSpace
    pmodfuncs: ^modfuncs_s;						          // &g_modfuncs
    pfnGetProcAddress: Pointer;							    // &GetProcAddress
    pfnGetModuleHandle: Pointer;							  // &GetModuleHandle
    psvs: ^server_static_s;					            // &svs
    pcls: ^client_static_s;						          // &cls
    pfnSV_DropClient: procedure(const cl: client_s; crash: qboolean; &string: PAnsiChar); cdecl varargs;	// pointer to SV_DropClient
    pfnNetchan_Transmit: procedure(const chan: netchan_s; length: Integer; data: PByte); cdecl varargs;		// pointer to Netchan_Transmit
    pfnNET_SendPacket: procedure(sock: netsrc_s; length: Integer; data: Pointer; const &to: netadr_t);    // &NET_SendPacket
    pfnCvarFindVar: function(pchName: PAnsiChar): PCVar;	// pointer to Cvar_FindVar
    phinstOpenGlEarly: PInteger;								          // &g_hinstOpenGlEarly

    // Reserved for future expansion
    pVoid0: Pointer;							// reserved for future expan
    pVoid1: Pointer;							// reserved for future expan
    pVoid2: Pointer;							// reserved for future expan
    pVoid3: Pointer;							// reserved for future expan
    pVoid4: Pointer;							// reserved for future expan
    pVoid5: Pointer;							// reserved for future expan
    pVoid6: Pointer;							// reserved for future expan
    pVoid7: Pointer;							// reserved for future expan
    pVoid8: Pointer;							// reserved for future expan
    pVoid9: Pointer;							// reserved for future expan
  end;
  engdata_t = engdata_s;

  TEngData = engdata_s;
  PEngData = ^engdata_s;

  _UserMsg = record
    iMsg: Integer;
    iSize: Integer;
    szName: array[0..15] of AnsiChar;
    next: ^_UserMsg;
    pfn: pfnUserMsgHook;
  end;
  UserMsg = _UserMsg;

  TUserMsg = _UserMsg;
  PUserMsg = ^_UserMsg;

  svc_func_s = record
    opcode: Byte;
    pszname: PAnsiChar;
    pfnParse: Pointer;
  end;
  svc_func_t = svc_func_s;

  TSvcFunc = svc_func_s;
  PSvcFunc = ^svc_func_s;

  // Engine hands this to DLLs for functionality callbacks
  enginefuncs_s = record
    pfnPrecacheModel: function(s: PAnsiChar): Integer; cdecl;
    pfnPrecacheSound: function(s: PAnsiChar): Integer; cdecl;
    pfnSetModel: procedure(const e: edict_t; m: PAnsiChar); cdecl;
    pfnModelIndex: function(m: PAnsiChar): Integer; cdecl;
    pfnModelFrames: function(modelIndex: Integer): Integer; cdecl;
    pfnSetSize: procedure(const e: edict_t; const rgflMin, rgflMax: vec3_t); cdecl;
    pfnChangeLevel: procedure(s1, s2: PAnsiChar); cdecl;
    pfnGetSpawnParms: procedure(const ent: edict_t); cdecl;
    pfnSaveSpawnParms: procedure(const ent: edict_t); cdecl;
    pfnVecToYaw: function(const rgflVector: vec3_t): Single; cdecl;
    pfnVecToAngles: procedure(const rgflVectorIn: vec3_t; var rgflVectorOut: vec3_t); cdecl;
    pfnMoveToOrigin: procedure(const ent: edict_t; const pflGoal: vec3_t; dist: Single; iMoveType: Integer); cdecl;
    pfnChangeYaw: procedure(const ent: edict_t); cdecl;
    pfnChangePitch: procedure(const ent: edict_t); cdecl;
    pfnFindEntityByString: function(const pEdictStartSearchAfter: edict_t; pszField: PAnsiChar; pszValue: PAnsiChar): PEdict; cdecl;
    pfnGetEntityIllum: function(const pEnt: edict_t): Integer; cdecl;
    pfnFindEntityInSphere: function(const pEdictStartSearchAfter: edict_t; const org: vec3_t; rad: Single): PEdict; cdecl;
    pfnFindClientInPVS: function(const pEdict: edict_t): PEdict; cdecl;
    pfnEntitiesInPVS: function(const pplayer: edict_t): PEdict; cdecl;
    pfnMakeVectors: procedure(const rgflVector: vec3_t); cdecl;
    pfnAngleVectors: procedure(const rgflVector: vec3_t; var &forward, right, up: vec3_t); cdecl;
    pfnCreateEntity: function: PEdict; cdecl;
    pfnRemoveEntity: procedure(const e: edict_t); cdecl;
    pfnCreateNamedEntity: function(className: Integer): PEdict; cdecl;
    pfnMakeStatic: procedure(const ent: edict_t); cdecl;
    pfnEntIsOnFloor: function(const e: edict_t): Integer; cdecl;
    pfnDropToFloor: function(const e: edict_t): Integer; cdecl;
    pfnWalkMove: function(const ent: edict_t; yaw, dist: Single; iMode: Integer): Integer; cdecl;
    pfnSetOrigin: procedure(const e: edict_t; const rgflOrigin: vec3_t); cdecl;
    pfnEmitSound: procedure(const entity: edict_t; channel: Integer; sample: PAnsiChar; volume: Single; attenuation: Single; fFlags: Integer; pitch: Integer); cdecl;
    pfnEmitAmbientSound: procedure(const entity: edict_t; const pos: vec3_t; samp: PAnsiChar; vol: Single; attenuation: Single; fFlags: Integer; pitch: Integer); cdecl;
    pfnTraceLine: procedure(const v1: vec3_t; const v2: vec3_t; fNoMonsters: Integer; const pentToSkip: edict_t; var ptr: TraceResult); cdecl;
    pfnTraceToss: procedure(const pent, pentToIgnore: edict_t; var ptr: TraceResult); cdecl;
    pfnTraceMonsterHull: function(const pEdict: edict_t; const v1, v2: vec3_t; fNoMonsters: Integer; const pentToSkip: edict_t; var ptr: TraceResult): Integer; cdecl;
    pfnTraceHull: procedure(const v1, v2: vec3_t; fNoMonsters, hullNumber: Integer; const pentToSkip: edict_t; var ptr: TraceResult); cdecl;
    pfnTraceModel: procedure(const v1, v2: vec3_t; hullNumber: Integer; const pent: edict_t; var ptr: TraceResult); cdecl;
    pfnTraceTexture: function(const pTextureEntity: edict_t; const v1, v2: vec3_t): PAnsiChar; cdecl;
    pfnTraceSphere: procedure(const v1, v2: vec3_t; fNoMonsters: Integer; radius: Single; const pentToSkip: edict_t; var ptr: TraceResult); cdecl;
    pfnGetAimVector: procedure(const ent: edict_t; speed: Single; const rgflReturn: vec3_t); cdecl;
    pfnServerCommand: procedure(str: PAnsiChar); cdecl;
    pfnServerExecute: procedure; cdecl;
    pfnClientCommand: procedure(const pEdict: edict_t; szFmt: PAnsiChar); cdecl varargs;
    pfnParticleEffect: procedure(const org, dir: vec3_t; color: Single; count: Single); cdecl;
    pfnLightStyle: procedure(style: Integer; val: PAnsiChar); cdecl;
    pfnDecalIndex: function(name: PAnsiChar): Integer; cdecl;
    pfnPointContents: function(const rgflVector: vec3_t): PLink; cdecl;
    pfnMessageBegin: procedure(msg_dest, msg_type: Integer; const pOrigin: vec3_t; const ed: edict_t); cdecl;
    pfnMessageEnd: procedure; cdecl;
    pfnWriteByte: procedure(iValue: Integer); cdecl;
    pfnWriteChar: procedure(iValue: Integer); cdecl;
    pfnWriteShort: procedure(iValue: Integer); cdecl;
    pfnWriteLong: procedure(iValue: Integer); cdecl;
    pfnWriteAngle: procedure(flValue: Single); cdecl;
    pfnWriteCoord: procedure(flValue: Single); cdecl;
    pfnWriteString: procedure(sz: PAnsiChar); cdecl;
    pfnWriteEntity: procedure(iValue: Integer); cdecl;
    pfnCVarRegister: procedure(const pCvar: cvar_t); cdecl;
    pfnCVarGetFloat: procedure(szVarName: PAnsiChar); cdecl;
    pfnCVarGetString: function(szVarName: PAnsiChar): PAnsiChar; cdecl;
    pfnCVarSetFloat: procedure(szVarName: PAnsiChar; flValue: Single); cdecl;
    pfnCVarSetString: procedure(szVarName, szValue: PAnsiChar); cdecl;
    pfnAlertMessage: procedure(atype: ALERT_TYPE; szFmt: PAnsiChar); cdecl varargs;
    pfnEngineFprintf: procedure(pfile: Pointer; szFmt: PAnsiChar); cdecl varargs;
    pfnPvAllocEntPrivateData: procedure(const pEdict: edict_t; cb: Longint); cdecl;
    pfnPvEntPrivateData: procedure(const pEdict: edict_t); cdecl;
    pfnFreeEntPrivateData: procedure(const pEdict: edict_t); cdecl;
    pfnSzFromIndex: function(iString: Integer): PAnsiChar; cdecl;
    pfnAllocString: function(szValue: PAnsiChar): Integer; cdecl;
    pfnGetVarsOfEnt: function(const pEdict: edict_t): Integer; cdecl;
    pfnPEntityOfEntOffset: function(iEntOffset: Integer): PEdict; cdecl;
    pfnEntOffsetOfPEntity: function(const pEdict: edict_t): Integer; cdecl;
    pfnIndexOfEdict: function(const pEdict: edict_t): Integer; cdecl;
    pfnPEntityOfEntIndex: function(iEntIndex: Integer): PEdict; cdecl;
    pfnFindEntityByVars: function(const pvars: entvars_s): PEdict; cdecl;
    pfnGetModelPtr: function(const pEdict: edict_t): Pointer; cdecl;
    pfnRegUserMsg: function(pszName: PAnsiChar; iSize: Integer): Integer; cdecl;
    pfnAnimationAutomove: procedure(const pEdict: edict_t; flTime: Single); cdecl;
    pfnGetBonePosition: procedure(const pEdict: edict_t; iBone: Integer; var rgflOrigin: vec3_t; var rgflAngles: vec3_t);
    pfnFunctionFromName: function(pName: PAnsiChar): LongWord; cdecl;
    pfnNameForFunction: function(&function: Cardinal): PAnsiChar; cdecl;
    pfnClientPrintf: procedure(const pEdict: edict_t; ptype: PRINT_TYPE; szMsg: PAnsiChar); // JOHN: engine callbacks so game DLL can print messages to individual clients
    pfnServerPrint: procedure(szMsg: PAnsiChar); cdecl;
    pfnCmd_Args: function: PAnsiChar;		// these 3 added
    pfnCmd_Argv: function(argc: Integer): PAnsiChar; cdecl;	// so game DLL can easily
    pfnCmd_Argc: function: Integer;	cdecl;	// access client 'cmd' strings
    pfnGetAttachment: procedure(const pEdict: edict_t; iAttachment: Integer; var rgflOrigin, rgflAngles: vec3_t); cdecl;
    pfnCRC32_Init: procedure(var pulCRC: CRC32_t); cdecl;
    pfnCRC32_ProcessBuffer: procedure(var pulCRC: CRC32_t; p: Pointer; len: Integer); cdecl;
    pfnCRC32_ProcessByte: procedure(var pulCRC: CRC32_t; ch: Byte); cdecl;
    pfnCRC32_Final: function(pulCRC: CRC32_t): Cardinal; cdecl;
    pfnRandomLong: function(lLow, lHigh: Longint): Longint; cdecl;
    pfnRandomFloat: function(flLow, flHigh: Single): Single; cdecl;
    pfnSetView: procedure(const pClient: edict_t; const pViewent: edict_t); cdecl;
    pfnTime: function: Single; cdecl;
    pfnCrosshairAngle: procedure(const pClient: edict_t; pitch, yaw: Single); cdecl;
    pfnLoadFileForMe: function(filename: PAnsiChar; var pLength: Integer): PByte; cdecl;
    pfnFreeFile: procedure(buffer: Pointer); cdecl;
    pfnEndSection: procedure(pszSectionName: PAnsiChar); // trigger_endsection
    pfnCompareFileTime: function(filename1, filename2: PAnsiChar; var iCompare: Integer): Integer; cdecl;
    pfnGetGameDir: procedure(szGetGameDir: PAnsiChar); cdecl;
    pfnCvar_RegisterVariable: procedure(const variable: cvar_t); cdecl;
    pfnFadeClientVolume: procedure(const pEdict: edict_t; fadePercent, fadeOutSeconds, holdTime, fadeInSeconds: Integer); cdecl;
    pfnSetClientMaxspeed: procedure(const pEdict: edict_t; fNewMaxspeed: Single); cdecl;
    pfnCreateFakeClient: function(netname: PAnsiChar): PEdict; cdecl;	// returns NULL if fake client can't be created
    pfnRunPlayerMove: procedure(const fakeclient: edict_t; const viewangles: vec3_t; forwardmove, sidemove, upmove: Single; buttons: Word; impulse: Byte; msec: Byte); cdecl;
    pfnNumberOfEntities: function: Integer; cdecl;
    pfnGetInfoKeyBuffer: function(const e: edict_t): PAnsiChar; cdecl;	// passing in NULL gets the serverinfo
    pfnInfoKeyValue: function(infobuffer: PAnsiChar; key: PAnsiChar): PAnsiChar; cdecl;
    pfnSetKeyValue: procedure(infobuffer: PAnsiChar; key: PAnsiChar; value: PAnsiChar); cdecl;
    pfnSetClientKeyValue: procedure(clientIndex: Integer; infobuffer, key, value: PAnsiChar); cdecl;
    pfnIsMapValid: function(filename: PAnsiChar): Integer; cdecl;
    pfnStaticDecal: procedure(const origin: vec3_t; decalIndex, entityIndex, modelIndex: Integer); cdecl;
    pfnPrecacheGeneric: procedure(s: PAnsiChar); cdecl;
    pfnGetPlayerUserId: procedure(const e: edict_t); cdecl; // returns the server assigned userid for this player.  useful for logging frags, etc.  returns -1 if the edict couldn't be found in the list of clients
    pfnBuildSoundMsg: procedure(const entity: edict_t; channel: Integer; sample: PAnsiChar; volume, attenuation: Single; fFlags, pitch, msg_dest, msg_type: Integer; const pOrigin: vec3_t; const ed: edict_t);
    pfnIsDedicatedServer: function: Integer; cdecl; // is this a dedicated server?
    pfnCVarGetPointer: function(szVarName: PAnsiChar): PCVar; cdecl;
    pfnGetPlayerWONId: function(const e: edict_t): Integer; cdecl; // returns the server assigned WONid for this player.  useful for logging frags, etc.  returns -1 if the edict couldn't be found in the list of clients

    // YWB 8/1/99 TFF Physics additions
    pfnInfo_RemoveKey: procedure(s, key: PAnsiChar); cdecl;
    pfnGetPhysicsKeyValue: function(const pClient: edict_t; key: PAnsiChar): PAnsiChar; cdecl;
    pfnSetPhysicsKeyValue: procedure(const pClient: edict_t; key, value: PAnsiChar); cdecl;
    pfnGetPhysicsInfoString: function(const pClient: edict_t): PAnsiChar; cdecl;
    pfnPrecacheEvent: function(&type: Integer; psz: PAnsiChar): Word; cdecl;
    pfnPlaybackEvent: procedure(flags: Integer; const pInvoker: edict_t; eventindex: Word; delay: Single; const origin: vec3_t; const angles: vec3_t; fparam1, fparam2: Single; iparam1, iparam2: Integer; bparam1, bparam2: Integer); cdecl;

    pfnSetFatPVS: function(const org: vec3_t): PByte; cdecl;
    pfnSetFatPAS: function(const org: vec3_t): PByte; cdecl;

    pfnCheckVisibility: function(const entity: edict_t; pset: PByte): Integer; cdecl;

    pfnDeltaSetField: procedure(const pFields: delta_s; fieldname: PAnsiChar); cdecl;
    pfnDeltaUnsetField: procedure(const pFields: delta_s; fieldname: PAnsiChar); cdecl;
    pfnDeltaAddEncoder: procedure(name: PAnsiChar; conditionalencode: encoder_t); cdecl;
    pfnGetCurrentPlayer: function: Integer; cdecl;
    pfnCanSkipPlayer: function(const player: edict_t): Integer; cdecl;
    pfnDeltaFindField: function(const pFields: delta_s; fieldname: PAnsiChar): Integer; cdecl;
    pfnDeltaSetFieldByIndex: procedure(const pFields: delta_s; fieldNumber: Integer); cdecl;
    pfnDeltaUnsetFieldByIndex: procedure(const pFields: delta_s; fieldNumber: Integer); cdecl;

    pfnSetGroupMask: procedure(mask, op: Integer); cdecl;

    pfnCreateInstancedBaseline: function(classname: Integer; const baseline: entity_state_s): Integer; cdecl;
    pfnCvar_DirectSet: procedure(const &var: cvar_s; value: PAnsiChar); cdecl;

    // Forces the client and server to be running with the same version of the specified file
    //  ( e.g., a player model ).
    // Calling this has no effect in single player
    pfnForceUnmodified: procedure(&type: FORCE_TYPE; const mins, maxs: vec3_t; filename: PAnsiChar); cdecl;

    pfnGetPlayerStats: procedure(const pClient: edict_t; var ping, packet_loss: Integer); cdecl;

    pfnAddServerCommand: procedure(cmd_name: PAnsiChar; &function: xcommand_t); cdecl;

    // For voice communications, set which clients hear eachother.
    // NOTE: these functions take player entity indices (starting at 1).
    pfnVoice_GetClientListening: function(iReceiver, iSender: Integer): qboolean; cdecl;
    pfnVoice_SetClientListening: function(iReceiver, iSender: Integer; bListen: qboolean): qboolean; cdecl;

    pfnGetPlayerAuthId: function(const e: edict_t): PAnsiChar; cdecl;

    // PSV: Added for CZ training map
    //	const char *(*pfnKeyNameForBinding)					( const char* pBinding );

    pfnSequenceGet: function(fileName, entryName: PAnsiChar): PSequenceEntry; cdecl;
    pfnSequencePickSentence: function(groupName: PAnsiChar; pickMethod: Integer; var picked: Integer): PSequenceEntry; cdecl;

    // LH: Give access to filesize via filesystem
    pfnGetFileSize: function(filename: PAnsiChar): Integer; cdecl;

    pfnGetApproxWavePlayLen: function(filepath: PAnsiChar): Cardinal; cdecl;
    // MDC: Added for CZ career-mode
    pfnIsCareerMatch: function: Integer; cdecl;

    // BGC: return the number of characters of the localized string referenced by using "label"
    pfnGetLocalizedStringLength: function(&label: PAnsiChar): Integer; cdecl;

    // BGC: added to facilitate persistent storage of tutor message decay values for
    // different career game profiles.  Also needs to persist regardless of mp.dll being
    // destroyed and recreated.
    pfnRegisterTutorMessageShown: procedure(mid: Integer); cdecl;
    pfnGetTimesTutorMessageShown: function(mid: Integer): Integer; cdecl;
    pfnProcessTutorMessageDecayBuffer: procedure(buffer: PInteger; bufferLength: Integer); cdecl;
    pfnConstructTutorMessageDecayBuffer: procedure(buffer: PInteger; bufferLength: Integer); cdecl;
    pfnResetTutorMessageDecayData: procedure; cdecl;

    // Added 2005/08/11 (no SDK update):
    pfnQueryClientCvarValue: procedure(const player: edict_t; cvarName: PAnsiChar); cdecl;

    // Added 2005/11/21 (no SDK update):
    pfnQueryClientCvarValue2: procedure(const player: edict_t; cvarName: PAnsiChar; requestID: Integer); cdecl;

    // Added 2009/06/19 (no SDK update):
    pfnEngCheckParm: procedure(pchCmdLineToken: PAnsiChar; var ppnext: PAnsiChar); cdecl;
  end;
  enginefuncs_t = enginefuncs_s;

  TEngineFuncs = enginefuncs_s;
  PEngineFuncs = ^enginefuncs_s;

  auxvert_t = record
    fv: array[0..2] of Single;
  end;

  TAuxVert = auxvert_t;
  PAuxVert = ^auxvert_t;

  // bones
  mstudiobone_t = record
    name: array[0..31] of AnsiChar;	// bone name for symbolic links
    parent: Integer;		// parent bone
    flags: Integer;		  // ??
    bonecontroller: array[0..5] of Integer;	// bone controller index, -1 == none
    value: array[0..5] of Single;	          // default DoF values
    scale: array[0..5] of Single;           // scale for delta DoF values
  end;

  TMStudioBone = mstudiobone_t;
  PMStudioBone = ^mstudiobone_t;

  // bone controllers
  mstudiobonecontroller_t = record
    bone: Integer;	// -1 == 0
    &type: Integer;	// X, Y, Z, XR, YR, ZR, M
    start: Single;
    &end: Single;
    rest: Integer;	// byte index value at rest
    index: Integer;	// 0-3 user set controller, 4 mouth
  end;

  TMStudioBoneController = mstudiobonecontroller_t;
  PMStudioBoneController = ^mstudiobonecontroller_t;

// intersection boxes
  mstudiobbox_t = record
    bone: Integer;
    group: Integer;			// intersection group
    bbmin: vec3_t;		// bounding box
    bbmax: vec3_t;
  end;

  // demand loaded sequence groups
  mstudioseqgroup_t = record
    &label: array[0..31] of AnsiChar;	// textual name
    name: array[0..63] of AnsiChar;	// file name
    unused1: Longint;    // was "cache"  - index pointer
    unused2: Integer;    // was "data" -  hack for group 0
  end;

  TMStudioSeqGroup = mstudioseqgroup_t;
  PMStudioSeqGroup = ^mstudioseqgroup_t;

  // sequence descriptions
  mstudioseqdesc_t = record
    &label: array[0..31] of AnsiChar;	// sequence label

    fps: Single;		// frames per second
    flags: Integer;		// looping/non-looping flags

    activity: Integer;
    actweight: Integer;

    numevents: Integer;
    eventindex: Integer;

    numframes: Integer;	// number of frames per sequence

    numpivots: Integer;	// number of foot pivots
    pivotindex: Integer;

    motiontype: Integer;
    motionbone: Integer;
    linearmovement: vec3_t;
    automoveposindex: Integer;
    automoveangleindex: Integer;

    bbmin: vec3_t;		// per sequence bounding box
    bbmax: vec3_t;

    numblends: Integer;
    animindex: Integer;		// mstudioanim_t pointer relative to start of sequence group data
                          // [blend][bone][X, Y, Z, XR, YR, ZR]

    blendtype: array[0..1] of Integer;	// X, Y, Z, XR, YR, ZR
    blendstart: array[0..1] of Single;	// starting value
    blendend: array[0..1] of Single;	// ending value
    blendparent: Integer;

    seqgroup: Integer;		// sequence group for demand loading

    entrynode: Integer;		// transition node at entry
    exitnode: Integer;		// transition node at exit
    nodeflags: Integer;		// transition rules

    nextseq: Integer;		// auto advancing sequences
  end;

  TMStudioSeqDesc = mstudioseqdesc_t;
  PMStudioSeqDesc = ^mstudioseqdesc_t;

  // attachment
  mstudioattachment_t = record
    name: array[0..31] of AnsiChar;
    &type: Integer;
    bone: Integer;
    org: vec3_t;	// attachment point
    vectors: array[0..2] of vec3_t;
  end;

  TMStudioAttachment = mstudioattachment_t;
  PMStudioAttachment = ^mstudioattachment_t;

  mstudioanim_t = record
    offset: array[0..5] of Word;
  end;

  TMStudioAnim = mstudioanim_t;
  PMStudioAnim = ^mstudioanim_t;

  // animation frames
  mstudioanimvalue_t = record
  strict private type
    mstudioanimvaluevariant_t = record // $4B71F77495E54035F264478FCA4CB9A3
      case num: Byte of
        0: (valid: Byte);
        1: (total: Byte);
    end;
  public
    num: mstudioanimvaluevariant_t;
    value: Word;
  end;

  TMStudioAnimValue = mstudioanimvalue_t;
  PMStudioAnimValue = ^mstudioanimvalue_t;

  // body part index
  mstudiobodyparts_t = record
    name: array[0..63] of AnsiChar;
    nummodels: Integer;
    base: Integer;
    modelindex: Integer; // index into models array
  end;

  TMStudioBodyParts = mstudiobodyparts_t;
  PMStudioBodyParts = ^mstudiobodyparts_t;

  // studio models
  mstudiomodel_t = record
    name: array[0..63] of AnsiChar;

    &type: Integer;

    boundingradius: Single;

    nummesh: Integer;
    meshindex: Integer;

    numverts: Integer;		// number of unique vertices
    vertinfoindex: Integer;	// vertex bone info
    vertindex: Integer;		// vertex vec3_t
    numnorms: Integer;		// number of unique surface normals
    norminfoindex: Integer;	// normal bone info
    normindex: Integer;		// normal vec3_t

    numgroups: Integer;		// deformation groups
    groupindex: Integer;
  end;

  TMStudioModel = mstudiomodel_t;
  PMStudioModel = ^mstudiomodel_t;

  // meshes
  mstudiomesh_t = record
    numtris: Integer;
    triindex: Integer;
    skinref: Integer;
    numnorms: Integer;		// per mesh normals
    normindex: Integer;		// normal vec3_t
  end;

  TMStudioMesh = mstudiomesh_t;
  PMStudioMesh = ^mstudiomesh_t;

  // @xref: Mod_LoadStudioModel
  studiohdr_t = record
    id: Integer;
    version: Integer;

    name: array[0..63] of AnsiChar;
    length: Integer;

    eyeposition: vec3_t; // ideal eye position
    min: vec3_t; // ideal movement hull size
    max: vec3_t;

    bbmin: vec3_t; // clipping bounding box
    bbmax: vec3_t;

    flags: Integer;

    numbones: Integer; // bones
    boneindex: Integer;

    numbonecontrollers: Integer; // bone controllers
    bonecontrollerindex: Integer;

    numhitboxes: Integer; // complex bounding boxes
    hitboxindex: Integer;

    numseq: Integer; // animation sequences
    seqindex: Integer;

    numseqgroups: Integer; // demand loaded sequences
    seqgroupindex: Integer;

    numtextures: Integer; // raw textures
    textureindex: Integer;
    texturedataindex: Integer;

    numskinref: Integer; // replaceable textures
    numskinfamilies: Integer;
    skinindex: Integer;

    numbodyparts: Integer;
    bodypartindex: Integer;

    numattachments: Integer; // queryable attachable points
    attachmentindex: Integer;

    soundtable: Integer;
    soundindex: Integer;
    soundgroups: Integer;
    soundgroupindex: Integer;

    numtransitions: Integer; // animation node to animation node transition graph
    transitionindex: Integer;
  end;

  TStudioHdr = studiohdr_t;
  PStudioHdr = ^studiohdr_t;
  {$IF SizeOf(TStudioHdr) <> 244} {$MESSAGE WARN 'Structure size mismatch @ TStudioHdr.'} {$DEFINE MSME} {$IFEND}

  // skin info
  mstudiotexture_t = record
    name: array[0..63] of AnsiChar;
    flags: Integer;
    width: Integer;
    height: Integer;
    index: Integer;
  end;

  player_model_t = record
    name, modelname: array[0..259] of AnsiChar;
    model: ^model_s;
  end;

  TPlayerModel = player_model_t;
  PPlayerModel = ^player_model_t;

  skin_t = record
    keynum: Integer;
    topcolor: Integer;
    bottomcolor: Integer;
    model: ^model_s;
    name: array[0..259] of AnsiChar;
    index: Integer;
    source: Integer;
    width: Integer;
    height: Integer;
    gl_index: Integer;
  end;

  TSkin = skin_t;
  PSkin = ^skin_t;

  Dl_info = record
    dli_fname: PAnsiChar;
    dli_fbase: Pointer;
    dli_sname: PAnsiChar;
    dli_saddr: Pointer;
  end;

  TDLInfo = Dl_info;
  PDLInfo = ^Dl_info;

  vmode_s = record
    width: Integer;
    height: Integer;
    bpp: Integer;
  end;
  vmode_t = vmode_s;

  TVMode = vmode_s;
  PVMode = ^vmode_s;

  sv_delta_t =
  (
    sv_packet_nodelta = $0,
    sv_packet_delta = $1
  );

  ipfilter_t = record
    mask: Cardinal;
    compare: Cardinal;
    banEndTime: Single;
    banTime: Single;
  end;

  TIPFilter = ipfilter_t;
  PIPFilter = ^ipfilter_t;

  userfilter_t = record
    userid: USERID_t;
    banEndTime: Single;
    banTime: Single;
  end;

  TUserFilter = userfilter_t;
  PUserFilter = ^userfilter_t;

  full_packet_entities_s = record
    num_entities: Integer;
    entities: array[0..MAX_PACKET_ENTITIES - 1] of entity_state_t;
  end;
  full_packet_entities_t = full_packet_entities_s;

  TFullPacketEntities = full_packet_entities_s;
  PFullPacketEntities = ^full_packet_entities_s;

  delta_info_s = record
    next: ^delta_info_s;
    name: PAnsiChar;
    loadfile: PAnsiChar;
    delta: ^delta_t;
  end;
  delta_info_t = ^delta_info_s;

  PDeltaInfo = delta_info_s;
  TDeltaInfo = ^delta_info_s;

  challenge_t = record
    adr: netadr_t;
    challenge: Integer;
    time: Integer;
  end;

  TChallenge = challenge_t;
  PChallenge = ^challenge_t;

  entcount_t = record
    entdata, playerdata: Integer;
  end;

  rcon_failure_t = record
    active: qboolean;
    shouldreject: qboolean;
    adr: netadr_t;
    num_failures: Integer;
    last_update: Single;
    failure_times: array[0..19] of Single;
  end;

  TRConFailure = rcon_failure_t;
  PRConFailure = ^rcon_failure_t;

  deltacallback_t = record
    numbase: PInteger;
    num: Integer;
    remove: qboolean;
    custom: qboolean;
    newbl: qboolean;
    newblindex: Integer;
    full: qboolean;
    offset: Integer;
  end;

  TDeltaCallback = deltacallback_t;
  PDeltaCallback = ^deltacallback_t;

  GameToAppIDMapItem_t = record
    iAppID: Cardinal;
    pGameDir: PAnsiChar;
  end;

  TGameToAppIDMapItem = GameToAppIDMapItem_t;
  PGameToAppIDMapItem = ^GameToAppIDMapItem_t;

  areanode_s = record
    axis: Integer;
    dist: Single;
    children: array[0..1] of ^areanode_s;
    trigger_edicts: link_t;
    solid_edicts: link_t;
  end;
  areanode_t = areanode_s;

  TAreaNode = areanode_s;
  PAreaNode = ^areanode_s;

  command_t = record
    command: PAnsiChar;
  end;
  TCommand = command_t;
  PCommand = ^command_t;

  sv_adjusted_positions_s = record
    active: Integer;
    needrelink: Integer;
    neworg: vec3_t;
    oldorg: vec3_t;
    initial_correction_org: vec3_t;
    oldabsmin: vec3_t;
    oldabsmax: vec3_t;
    deadflag: Integer;
    temp_org: vec3_t;
    temp_org_setflag: Integer;
  end;
  sv_adjusted_positions_t = sv_adjusted_positions_s;

  TSvAdjustedPositions = sv_adjusted_positions_s;
  PSvAdjustedPositions = ^sv_adjusted_positions_s;

  clc_func_s = record
    opcode: Byte;
    pszname: PAnsiChar;
    pfnParse: procedure(const Client: client_s); cdecl;
  end;
  clc_func_t = clc_func_s;

  TClcFunc = clc_func_s;
  PClcFunc = ^clc_func_s;

  texlumpinfo_t = record
    lump: lumpinfo_t;
    iTexFile: Integer;
  end;

  TTexLumpInfo = texlumpinfo_t;
  PTexLumpInfo = ^texlumpinfo_t;

  qpic_s = record
    width: Integer;
    height: Integer;
    data: array[0..3] of Byte;
  end;
  qpic_t = qpic_s;

  TQPic = qpic_s;
  PQPic = ^qpic_s;

  wadlist_t = record
    loaded: qboolean;
    wadname: array[0..31] of AnsiChar;
    wad_numlumps: Integer;
    wad_lumps: ^lumpinfo_s;
    wad_base: PByte;
  end;

  TWadList = wadlist_t;
  PWadList = ^wadlist_t;

  moveclip_t = record
    boxmins: vec3_t;
    boxmaxs: vec3_t;
    mins: PVec;
    maxs: PVec;
    mins2: vec3_t;
    maxs2: vec3_t;
    start: PVec;
    &end: PVec;
    trace: trace_t;
    &type: Word;
    ignoretrans: Word;
    passedict: ^edict_s;
    monsterClipBrush: qboolean;
  end;

  TMoveClip = moveclip_t;
  PMoveClip = ^moveclip_t;

  memblock_s = record
    size: Integer;
    tag: Integer;
    id: Integer;
    next: ^memblock_s;
    prev: ^memblock_s;
    pad: Integer;
  end;
  memblock_t = memblock_s;

  TMemBlock = memblock_s;
  PMemBlock = ^memblock_s;

  memzone_t = record
    size: Integer;
    blocklist: memblock_t;
    rover: ^memblock_t;
  end;

  TMemZone = memzone_t;
  PMemZone = ^memzone_t;

  hunk_t = record
    sentinal: Integer;
    size: Integer;
    name: array[0..63] of AnsiChar;
  end;

  THunk = hunk_t;
  PHunk = ^hunk_t;

  cache_system_s = record
    size: Integer;
    user: ^cache_user_t;
    name: array[0..63] of AnsiChar;
    prev: ^cache_system_s;
    next: ^cache_system_s;
    lru_prev: ^cache_system_s;
    lru_next: ^cache_system_s;
  end;
  cache_system_t = cache_system_s;

  TCacheSystem = cache_system_s;
  PCacheSystem = ^cache_system_s;

  __fd_mask = Integer;
  TFdMask = __fd_mask;

  fd_set = record
    __fds_bits: array[0..31] of __fd_mask;
  end;

  TFdSet = fd_set;
  PFdSet = ^fd_set;

  VidTypes =
  (
    VT_None = 0,
    VT_Software = 1,
    VT_OpenGL = 2,
    VT_Direct3D = 3
  );

  TVidTypes = VidTypes;
  PVidTypes = ^VidTypes;

  pixel_t = Byte;
  TPixel = pixel_t;
  PPixel = ^pixel_t;

  viddef_s = record
    buffer: ^pixel_t;
    colormap: ^pixel_t;
    colormap16: Smallint;
    fullbright: Integer;
    bits: Integer;
    is15bit: Integer;
    rowbytes: Cardinal;
    width: Cardinal;
    height: Cardinal;
    aspect: Single;
    numpages: Integer;
    recalc_refdef: Integer;
    conbuffer: ^pixel_t;
    conrowbytes: Integer;
    conwidth: Cardinal;
    conheight: Cardinal;
    maxwarpwidth: Cardinal;
    maxwarpheight: Cardinal;
    direct: ^pixel_t;
    vidtype: VidTypes;
  end;
  viddef_t = viddef_s;

  TVidDef = viddef_s;
  PVidDef = ^viddef_s;

  loopmsg_t = record
    data: array[0..4036] of Byte;
    datalen: Integer;
  end;

  TLoopMsg = loopmsg_t;
  PLoopMsg = ^loopmsg_t;

  loopback_t = record
    msgs: array[0..3] of loopmsg_t;
    get: Integer;
    send: Integer;
  end;

  TLoopback = loopback_t;
  PLoopback = ^loopback_t;

  packetlag_s = record
    pPacketData: PByte;
    nSize: Integer;
    net_from: netadr_t;
    receivedTime: Single;
    pNext: ^packetlag_s;
    pPrev: ^packetlag_s;
  end;
  packetlag_t = packetlag_s;

  TPacketLag = packetlag_s;
  PPacketLag = ^packetlag_s;

  LONGPACKET = record
    currentSequence: Integer;
    splitCount: Integer;
    totalSize: Integer;
    buffer: array[0..4009] of AnsiChar;
  end;

  TLongPacket = LONGPACKET;
  PLongPacket = ^LONGPACKET;

  SPLITPACKET = packed record
    netID: Integer;
    sequenceNumber: Integer;
    packetID: Byte;
  end;

  TSplitPacket = SPLITPACKET;
  PSplitPacket = ^SPLITPACKET;

  net_messages_s = record
    next: ^net_messages_s;
    preallocated: qboolean;
    buffer: PByte;
    from: netadr_t;
    buffersize: Integer;
  end;
  net_messages_t = net_messages_s;

  TNetMessage = net_messages_s;
  PNetMessage = ^net_messages_s;

  netbandwidthgraph_t = record
    client: Word;
    players: Word;
    entities: Word;
    tentities: Word;
    sound: Word;
    event: Word;
    usr: Word;
    msgbytes: Word;
    voicebytes: Word;
  end;

  TNetBadwidthGraph = netbandwidthgraph_t;
  PNetBadwidthGraph = ^netbandwidthgraph_t;

  packet_latency_t = record
    latency: Integer;
    choked: Integer;
  end;

  TPacketLatency = packet_latency_t;
  PPacketLatency = ^packet_latency_t;

  netcolor_t = record
    color: array[0..2] of Byte;
    alpha: Byte;
  end;

  TNetColor = netcolor_t;
  PNetColor = ^netcolor_t;

  cmdinfo_t = record
    cmd_lerp: Single;
    size: Integer;
    sent: qboolean;
  end;

  TCmdInfo = cmdinfo_t;
  PCmdInfo = ^cmdinfo_t;

  // @xref: CL_SetUpPlayerPrediction
  predicted_player = record
    movetype: Integer;
    solid: Integer;
    usehull: Integer;
    active: qboolean;
    origin: vec3_t;
    angles: vec3_t;
  end;

  TPredictedPlayer = predicted_player;
  PPredictedPlayer = ^predicted_player;
  {$IF SizeOf(TPredictedPlayer) <> 40} {$MESSAGE WARN 'Structure size mismatch @ TPredictedPlayer.'} {$DEFINE MSME} {$IFEND}

  spritelist_s = record
    pSprite: ^model_t;
    pName: PAnsiChar;
    frameCount: Integer;
  end;
  SPRITELIST = spritelist_s;

  TSpriteList = spritelist_s;
  PSpriteList = ^spritelist_s;

  lightstyle_t = record
    length: Integer;
    map: array[0..63] of AnsiChar;
  end;

  TLightStyle = lightstyle_t;
  PLightStyle = ^lightstyle_t;

  event_hook_s = record
    next: ^event_hook_s;
    name: PAnsiChar;
    pfnEvent: procedure(const args: event_args_s); cdecl;
  end;
  event_hook_t = event_hook_s;

  TEventHook = event_hook_s;
  PEventHook = ^event_hook_s;

  vrect_s = record
    x: Integer;
    y: Integer;
    width: Integer;
    height: Integer;
    pnext: ^vrect_s;
  end;
  vrect_t = vrect_s;

  TVRect = vrect_s;
  PVRect = ^vrect_s;

  refdef_t = record
    vrect: vrect_s;
    aliasvrect: vrect_s;
    vrectright: Integer;
    vrectbottom: Integer;
    aliasvrectright: Integer;
    aliasvrectbottom: Integer;
    vrectrightedge: Single;
    fvrectx: Single;
    fvrecty: Single;
    fvrectx_adj: Single;
    fvrecty_adj: Single;
    vrect_x_adj_shift20: Integer;
    vrectright_adj_shift20: Integer;
    fvrectright_adj: Single;
    fvrectbottom_adj: Single;
    fvrectright: Single;
    fvrectbottom: Single;
    horizontalFieldOfView: Single;
    xOrigin: Single;
    yOrigin: Single;
    vieworg: vec3_t;
    viewangles: vec3_t;
    ambientlight: color24;
    onlyClientDraws: qboolean;
  end;

  TRefDef = refdef_t;
  PRefDef = ^refdef_t;

  ScreenFade = record
    duration: Word;
    holdTime: Word;
    fadeFlags: Smallint;
    r, g, b, a: Byte;
  end;

  demoheader_s = record
    szFileStamp: array[0..5] of AnsiChar;
    nDemoProtocol: Integer;
    nNetProtocolVersion: Integer;
    szMapName: array[0..259] of AnsiChar;
    szDllDir: array[0..259] of AnsiChar;
    mapCRC: CRC32_t;
    nDirectoryOffset: Integer;
  end;
  demoheader_t = demoheader_s;

  TDemoHeader = demoheader_s;
  PDemoHeader = ^demoheader_s;

  demoentry_s = record
    nEntryType: Integer;
    szDescription: array[0..63] of AnsiChar;
    nFlags: Integer;
    nCDTrack: Integer;
    fTrackTime: Single;
    nFrames: Integer;
    nOffset: Integer;
    nFileLength: Integer;
  end;
  demoentry_t = demoentry_s;

  TDemoEntry = demoentry_s;
  PDemoEntry = ^demoentry_s;

  demo_info_s = record
    timestamp: Single;
    rp: ref_params_t;
    cmd: usercmd_t;
    movevars: movevars_t;
    view: vec3_t;
    viewmodel: Integer;
  end;
  demo_info_t = demo_info_s;

  TDemoInfo = demo_info_s;
  PDemoInfo = ^demo_info_s;

  demodirectory_s = record
    nEntries: Integer;
    p_rgEntries: ^demoentry_t;
  end;
  demodirectory_t = demodirectory_s;

  TDemoDirectory = demodirectory_s;
  PDemoDirectory = ^demodirectory_s;

  sequence_info_s = record
    incoming_sequence: Integer;
    incoming_acknowledged: Integer;
    incoming_reliable_acknowledged: Integer;
    incoming_reliable_sequence: Integer;
    outgoing_sequence: Integer;
    reliable_sequence: Integer;
    last_reliable_sequence: Integer;
    length: Integer;
  end;
  sequence_info_t = sequence_info_s;

  TSequenceInfo = sequence_info_s;
  PSequenceInfo = ^sequence_info_s;

  demo_command_s = packed object
  public
    cmd: Byte;
    time: Single;
    frame: Integer;
  end;
  demo_command_t = demo_command_s;

  TDemoCommand = demo_command_s;
  PDemoCommand = ^demo_command_s;

  hud_command_s = packed object(demo_command_s)
  public
    szNameBuf: array[0..63] of AnsiChar;
  end;
  hud_command_t = hud_command_s;

  THudCommand = hud_command_s;
  PHudCommand = ^hud_command_s;

  cl_demo_data_s = packed object(demo_command_s)
  public
    origin: vec3_t;
    viewangles: vec3_t;
    iWeaponBits: Integer;
    fov: Single;
  end;
  cl_demo_data_t = cl_demo_data_s;

  TClDemoData = cl_demo_data_s;
  PClDemoData = ^cl_demo_data_s;

  demo_anim_s = packed object(demo_command_s)
  public
    anim: Integer;
    body: Integer;
  end;
  demo_anim_t = demo_anim_s;

  TDemoAnim = demo_anim_s;
  PDemoAnim = ^demo_anim_s;

  demo_event_s = packed object(demo_command_s)
  public
    flags: Integer;
    idx: Integer;
    delay: Single;
  end;
  demo_event_t = demo_event_s;

  TDemoEvent = demo_event_s;
  PDemoEvent = ^demo_event_s;

  demo_sound1_s = packed object(demo_command_s)
  public
    channel: Integer;
    length: Integer;
  end;

  TDemoSound1 = demo_sound1_s;
  PDemoSound1 = ^demo_sound1_s;

  // do not inherited from demo_command_s
  demo_sound2_s = packed record
    volume: Single;
    attenuation: Single;
    flags: Integer;
    pitch: Integer;
  end;

  TDemoSound2 = demo_sound2_s;
  PDemoSound2 = ^demo_sound2_s;

  server_cache_t = record
    inuse: Integer;
    adr: netadr_t;
    info: array[0..2047] of AnsiChar;
  end;

  TServerCache = server_cache_t;
  PServerCache = ^server_cache_t;

  startup_timing_t = record
    name: PAnsiChar;
    time: Single;
  end;

  TStartupTiming = startup_timing_t;
  PStartupTiming = ^startup_timing_t;

  oldcmd_t = record
    command: Integer;
    starting_offset: Integer;
    frame_number: Integer;
  end;

  TOldCmd = oldcmd_t;
  POldCmd = ^oldcmd_t;

  gltexture_t = record
    texnum: Integer;
    servercount: Smallint;
    paletteIndex: Smallint;
    width: Integer;
    height: Integer;
    mipmap: qboolean;
    identifier: array[0..63] of AnsiChar;
  end;

  TGLTexture = gltexture_t;
  PGLTexture = ^gltexture_t;

  GL_PALETTE = record
    tag: Integer;
    referenceCount: Integer;
    colors: array[0..767] of Byte;
  end;

  TGLPalette = GL_PALETTE;
  PGLPalette = ^GL_PALETTE;

  cachepic_s = record
    name: array[0..63] of AnsiChar;
    pic: qpic_t;
    padding: array[0..31] of Byte;
  end;
  cachepic_t = cachepic_s;

  TCachePic = cachepic_s;
  PCachePic = ^cachepic_s;

  quake_mode_t = record
    name: PAnsiChar;
    minimize: Integer;
    maximize: Integer;
  end;

  TQuakeMode = quake_mode_t;
  PQuakeMode = ^quake_mode_t;

  dmiptexlump_t = record
    nummiptex: Integer;
    dataofs: array[0..3] of Integer;
  end;

  TDMipTexLump = dmiptexlump_t;
  PDMipTexLump = ^dmiptexlump_t;

  dvertex_t = record
    point: array[0..2] of Single;
  end;

  TDVertex = dvertex_t;
  PDVertex = ^dvertex_t;

  dplane_t = record
    normal: array[0..2] of Single;
    dist: Single;
    &type: Integer;
  end;

  TDPlane = dplane_t;
  PDPlane = ^dplane_t;

  dnode_t = record
    planenum: Integer;
    children: array[0..1] of Smallint;
    mins: array[0..2] of Smallint;
    maxs: array[0..2] of Smallint;
    firstface: Word;
    numfaces: Word;
  end;

  TDNode = dnode_t;
  PDNode = ^dnode_t;

  texinfo_s = record
    vecs: array[0..1] of array[0..3] of Single;
    miptex: Integer;
    flags: Integer;
  end;
  texinfo_t = texinfo_s;

  TTexInfo = texinfo_s;
  PTexInfo = ^texinfo_s;

  dedge_t = record
    v: array[0..1] of Word;
  end;

  TDEdge = dedge_t;
  PDEdge = ^dedge_t;

  dface_t = record
    planenum: Smallint;
    side: Smallint;
    firstedge: Integer;
    numedges: Smallint;
    texinfo: Smallint;
    styles: array[0..3] of Byte;
    lightofs: Integer;
  end;

  TDFace = dface_t;
  PDFace = ^dface_t;

  dleaf_t = record
    contents: Integer;
    visofs: Integer;
    mins: array[0..2] of Smallint;
    maxs: array[0..2] of Smallint;
    firstmarksurface: Word;
    nummarksurfaces: Word;
    ambient_level: array[0..3] of Byte;
  end;

  TDLeaf = dleaf_t;
  PDLeaf = ^dleaf_t;

  aliasskintype_t =
  (
    ALIAS_SKIN_SINGLE = 0,
    ALIAS_SKIN_GROUP = 1
  );

  TAliasSkinType = aliasskintype_t;
  PAliasSkinType = ^aliasskintype_t;

  mdl_t = record
    ident: Integer;
    version: Integer;
    scale: vec3_t;
    scale_origin: vec3_t;
    boundingradius: Single;
    eyeposition: vec3_t;
    numskins: Integer;
    skinwidth: Integer;
    skinheight: Integer;
    numverts: Integer;
    numtris: Integer;
    numframes: Integer;
    synctype: synctype_t;
    flags: Integer;
    size: Single;
  end;

  TMdl = mdl_t;
  PMdl = ^mdl_t;

  stvert_t = record
    onseam: Integer;
    s: Integer;
    t: Integer;
  end;

  dtriangle_s = record
    facesfront: Integer;
    vertindex: array[0..2] of Integer;
  end;
  dtriangle_t = dtriangle_s;

  TDTriangle = dtriangle_s;
  PDTriangle = ^dtriangle_s;

  trivertx_s = record
    v: array[0..2] of Byte;
    lightnormalindex: Byte;
  end;
  trivertx_t = trivertx_s;

  TTriVertx = trivertx_s;
  PTriVertx = ^trivertx_s;

  daliasframe_t = record
    bboxmin, bboxmax: trivertx_t;
    name: array[0..15] of AnsiChar;
  end;

  TDAliasFrame = daliasframe_t;
  PDAliasFrame = ^daliasframe_t;

  daliasgroup_t = record
    numframes: Integer;
    bboxmin: trivertx_t;
    bboxmax: trivertx_t;
  end;

  TDAliasGroup = daliasgroup_t;
  PDAliasGroup = ^daliasgroup_t;

  daliasinterval_t = record
    interval: Single;
  end;

  TDAliasInterval = daliasinterval_t;
  PDAliasInterval = ^daliasinterval_t;

  daliasframetype_t = record
    &type: aliasframetype_t;
  end;

  TDAliasFrameType = daliasframetype_t;
  PDAliasFrameType = ^daliasframetype_t;

  daliasskintype_t = record
    &type: aliasskintype_t;
  end;

  TDAliasSkinType = daliasskintype_t;
  PDAliasSkinType = ^daliasskintype_t;

  dsprite_t = record
    ident: Integer;
    version: Integer;
    &type: Integer;
    texFormat: Integer;
    boundingradius: Single;
    width: Integer;
    height: Integer;
    numframes: Integer;
    beamlength: Single;
    synctype: synctype_t;
  end;

  TDSprite = dsprite_t;
  PDSprite = ^dsprite_t;

  dspriteframe_t = record
    origin: array[0..1] of Integer;
    width: Integer;
    height: Integer;
  end;

  TDSpriteFrame = dspriteframe_t;
  PDSpriteFrame = ^dspriteframe_t;

  dspritegroup_t = record
    numframes: Integer;
  end;

  TDSpriteGroup = dspritegroup_t;
  PDSpriteGroup = ^dspritegroup_t;

  dspriteinterval_t = record
    interval: Single;
  end;

  TDSpriteInterval = dspriteinterval_t;
  PDSpriteInterval = ^dspriteinterval_t;

  dspriteframetype_t = record
    &type: spriteframetype_t;
  end;

  TDSpriteFrameType = dspriteframetype_t;
  PDSpriteFrameType = ^dspriteframetype_t;

  mspritegroup_t = record
    numframes: Integer;
    intervals: PSingle;
    frames: array[0..0] of ^mspriteframe_t;
  end;

  TMSpriteGroup = mspritegroup_t;
  PMSpriteGroup = ^mspritegroup_t;

  mtriangle_s = record
    facesfront: Integer;
    vertindex: array[0..2] of Integer;
  end;
  mtriangle_t = mtriangle_s;

  TMTriangle = mtriangle_s;
  PMTriangle = ^mtriangle_s;

  mod_known_info_t = record
    shouldCRC: qboolean;
    firstCRCDone: qboolean;
    initialCRC: CRC32_t;
  end;

  TModKnownInfo = mod_known_info_t;
  PModKnownInfo = ^mod_known_info_t;

  floodfill_t = record
    x, y: Smallint;
  end;

  TCoordRect = record
    s0, t0, s1, t1: Single;
  end;
  PCoordRect = ^TCoordRect;

  VertexBuffer_t = record
    texcoords: array[0..1] of Single;
    vertex: array[0..1] of Single;
  end;

  TVertexBuffer = VertexBuffer_t;
  PVertexBuffer = ^VertexBuffer_t;

  cshift_t = record
    destcolor: array[0..2] of Integer;
    percent: Integer;
  end;

  TCShift = cshift_t;
  PCShift = ^cshift_t;

  glRect_t = record
    l, t, w, h: Integer;
  end;

  TGLRect = glRect_t;
  PGLRect = ^glRect_t;

  decalcache_t = record
    decalIndex: Integer;
    decalVert: array[0..3] of array[0..6] of Single;
  end;

  TDecalCache = decalcache_t;
  PDecalCache = ^decalcache_t;

  Color = record
    _color: array[0..3] of Byte;
  end;

  TColor = Color;
  PColor = ^Color;

  da_notify_t = record
    szNotify: array[0..79] of AnsiChar;
    expire: Single;
    color: array[0..2] of Single;
  end;

  TDANotify = da_notify_t;
  PDANotify = ^da_notify_t;

  portable_samplepair_t = record
    left, right: Integer;
  end;

  sfxcache_s = record
    length: Integer;
    loopstart: Integer;
    speed: Integer;
    width: Integer;
    stereo: Integer;
    data: array[0..0] of Byte;
  end;
  sfxcache_t = sfxcache_s;

  TSfxCache = sfxcache_s;
  PSfxCache = ^sfxcache_s;

  // @xref: S_Init
  dma_t = record
    gamealive: qboolean;
    soundalive: qboolean;
    splitbuffer: qboolean;
    channels: Integer;
    samples: Integer;
    submission_chunk: Integer;
    samplepos: Integer;
    samplebits: Integer;
    speed: Integer;
    dmaspeed: Integer;
    buffer: PByte;
  end;

  TDMA = dma_t;
  PDMA = ^dma_t;
  {$IF SizeOf(TDMA) <> 44} {$MESSAGE WARN 'Structure size mismatch @ TDMA.'} {$DEFINE MSME} {$IFEND}

  // @xref: S_PrintStats
  channel_t = record
    sfx: ^sfx_t;
    leftvol: Integer;
    rightvol: Integer;
    &end: Integer;
    pos: Integer;
    looping: Integer;
    entnum: Integer;
    entchannel: Integer;
    origin: vec3_t;
    dist_mult: vec_t;
    master_vol: Integer;
    isentence: Integer;
    iword: Integer;
    pitch: Integer;
  end;

  TChannel = channel_t;
  PChannel = ^channel_t;
  {$IF SizeOf(TChannel) <> 64} {$MESSAGE WARN 'Structure size mismatch @ TChannel.'} {$DEFINE MSME} {$IFEND}

  // @xref: GetWavinfo
  wavinfo_t = record
    rate: Integer;
    width: Integer;
    channels: Integer;
    loopstart: Integer;
    samples: Integer;
    dataofs: Integer;
  end;

  TWavInfo = wavinfo_t;
  PWavInfo = ^wavinfo_t;
  {$IF SizeOf(TWavInfo) <> 24} {$MESSAGE WARN 'Structure size mismatch @ TWavInfo.'} {$DEFINE MSME} {$IFEND}

  // @xref: Wavstream_Init
  wavstream_s = record
    csamplesplayed: Integer;
    csamplesinmem: Integer;
    hFile: FileHandle_t;
    info: wavinfo_t;
    lastposloaded: Integer;
  end;
  wavstream_t = wavstream_s;

  TWavStream = wavstream_s;
  PWavStream = ^wavstream_s;
  {$IF SizeOf(TWavStream) <> 40} {$MESSAGE WARN 'Structure size mismatch @ TWavStream.'} {$DEFINE MSME} {$IFEND}

  GetSoundDataFn = function(const pCache: sfxcache_s; pCopyBuf: PAnsiChar; maxOutDataSize, samplePos, sampleCount: Integer): Integer; cdecl;
  TGetSoundData = GetSoundDataFn;

  // @xref: VOX_LoadSound
  voxword = record
    volume: Integer;
    pitch: Integer;
    start: Integer;
    &end: Integer;
    cbtrim: Integer;
    fKeepCached: Integer;
    samplefrac: Integer;
    timecompress: Integer;
    sfx: ^sfx_t;
  end;
  voxword_t = voxword;

  TVoxWord = voxword;
  PVoxWord = ^voxword;
  {$IF SizeOf(TVoxWord) <> 36} {$MESSAGE WARN 'Structure size mismatch @ TVoxWord.'} {$DEFINE MSME} {$IFEND}

  sample_t = Smallint;

  // @xref: SX_Init
  dlyline_s = record
    cdelaysamplesmax: Integer;
    lp: Integer;
    idelayinput: Integer;
    idelayoutput: Integer;
    idelayoutputxf: Integer;
    xfade: Integer;
    delaysamples: Integer;
    delayfeed: Integer;
    lp0: Integer;
    lp1: Integer;
    lp2: Integer;
    &mod: Integer;
    modcur: Integer;
    hdelayline: THandle;
    lpdelayline: ^sample_t;
  end;
  dlyline_t = dlyline_s;

  TDLYLine = dlyline_s;
  PDLYLine = ^dlyline_s;
  {$IF SizeOf(TDLYLine) <> 60} {$MESSAGE WARN 'Structure size mismatch @ TDLYLine.'} {$DEFINE MSME} {$IFEND}

  HPSTR = PAnsiChar;

  sx_preset_s = record
    room_lp: Single;
    room_mod: Single;
    room_size: Single;
    room_refl: Single;
    room_rvblp: Single;
    room_delay: Single;
    room_feedback: Single;
    room_dlylp: Single;
    room_left: Single;
  end;
  sx_preset_t = sx_preset_s;

  TSXPreset = sx_preset_s;
  PSXPreset = ^sx_preset_s;

  CCircularBuffer = record
    m_nCount: Integer;
    m_nRead: Integer;
    m_nWrite: Integer;
    m_nSize: Integer;
    m_chData: array[0..0] of AnsiChar;
  end;

  CAutoGain = record
  strict private type
    AGFixed = Longint;
  public
    m_BlockSize: Integer;
    m_MaxGain: Single;
    m_AvgToMaxVal: Single;
    m_CurBlockOffset: Integer;
    m_CurTotal: Integer;
    m_CurMax: Integer;
    m_Scale: Single;
    m_CurrentGain: Single;
    m_NextGain: Single;
    m_FixedCurrentGain: AGFixed;
    m_GainMultiplier: AGFixed;
  end;

  keyname_t = record
    name: PAnsiChar;
    keynum: Integer;
  end;

  TKeyName = keyname_t;
  PKeyName = ^keyname_t;

  // @xref: VoiceSE_Init
  VoiceSE_SFX = record
    m_SFX: sfx_s;
    m_SFXCache: sfxcache_s;
    m_PrevUpsampleValue: Smallint;
  end;

  TVoiceSESFX = VoiceSE_SFX;
  PVoiceSESFX = ^VoiceSE_SFX;
  {$IF SizeOf(TVoiceSESFX) <> 100} {$MESSAGE WARN 'Structure size mismatch @ TVoiceSESFX.'} {$DEFINE MSME} {$IFEND}

  svc_commands_e =
  (
    svc_bad = 0,
    svc_nop,
    svc_disconnect,
    svc_event,
    svc_version,
    svc_setview,
    svc_sound,
    svc_time,
    svc_print,
    svc_stufftext,
    svc_setangle,
    svc_serverinfo,
    svc_lightstyle,
    svc_updateuserinfo,
    svc_deltadescription,
    svc_clientdata,
    svc_stopsound,
    svc_pings,
    svc_particle,
    svc_damage,
    svc_spawnstatic,
    svc_event_reliable,
    svc_spawnbaseline,
    svc_temp_entity,
    svc_setpause,
    svc_signonnum,
    svc_centerprint,
    svc_killedmonster,
    svc_foundsecret,
    svc_spawnstaticsound,
    svc_intermission,
    svc_finale,
    svc_cdtrack,
    svc_restore,
    svc_cutscene,
    svc_weaponanim,
    svc_decalname,
    svc_roomtype,
    svc_addangle,
    svc_newusermsg,
    svc_packetentities,
    svc_deltapacketentities,
    svc_choke,
    svc_resourcelist,
    svc_newmovevars,
    svc_resourcerequest,
    svc_customization,
    svc_crosshairangle,
    svc_soundfade,
    svc_filetxferfailed,
    svc_hltv,
    svc_director,
    svc_voiceinit,
    svc_voicedata,
    svc_sendextrainfo,
    svc_timescale,
    svc_resourcelocation,
    svc_sendcvarvalue,
    svc_sendcvarvalue2,
    svc_exec,
    svc_endoflist = 255
  );
  svc_commands_t = svc_commands_e;

  TSvcCommands = svc_commands_e;
  PSvcCommands = ^svc_commands_e;

  clc_commands_e =
  (
    clc_bad = 0,
    clc_nop,
    clc_move,
    clc_stringcmd,
    clc_delta,
    clc_resourcelist,
    clc_tmove,
    clc_fileconsistency,
    clc_voicedata,
    clc_hltv,
    clc_cvarvalue,
    clc_cvarvalue2,
    clc_endoflist = 255
  );
  clc_commands_t = clc_commands_e;

  TClcCommands = clc_commands_e;
  PClcCommands = ^clc_commands_e;

{$IFDEF MSME}
 {$MESSAGE WARN 'One of the engine structures failed to pass validation check.'}
 {$MESSAGE WARN 'This could usually mean that there was a change in one of these structures,'}
 {$MESSAGE WARN 'or the compiler incorrectly assembles the type definitions.'}

 {.$MESSAGE FATAL 'The compilation process was stopped.'}
{$ENDIF}

implementation

end.
