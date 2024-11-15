enum SoundFX
	SFX_BEAM = 0
	SFX_TORP
	SFX_FIGHTER
	SFX_EXPLODE
	SFX_MAX
end enum

#include "SDL/SDL.bi"
#include "SDL/SDL_mixer.bi"

const clipCount = SFX_MAX - 1
dim shared as Mix_Chunk ptr clip(clipCount)
dim shared as integer clipChannel(clipCount)
dim shared music as Mix_Music ptr

dim as string SFXNames(clipCount)
for CID as ubyte = 0 to clipCount
	clip(CID) = NULL
	clipChannel(CID) = -1
next CID

dim audio_rate as integer
dim audio_format as Uint16
dim audio_channels as integer
dim audio_buffers as integer

audio_rate = 44100
audio_format = AUDIO_S16
audio_channels = 2
audio_buffers = 4096

SDL_Init(SDL_INIT_AUDIO)

SFXNames(SFX_BEAM) = "beam"
SFXNames(SFX_TORP) = "torp"
SFXNames(SFX_FIGHTER) = "fighter"
SFXNames(SFX_EXPLODE) = "explode"

if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers)) then
	print "Unable to open audio!"
	
	cleaning
	end 1
end if
Mix_QuerySpec(@audio_rate, @audio_format, @audio_channels)

for PID as short = 0 to clipCount
	clip(PID) = Mix_LoadWAV("sfx/"+SFXNames(PID)+".wav")
next PID
music = NULL

dim shared as byte SkipSounds = 0
declare sub loadMusic(MusicFile as string)
declare sub playSong

sub playClip(ID as byte)
	if SkipSounds = 0 AND ID >= 0 then
		clipChannel(ID) = Mix_PlayChannel(-1, clip(ID), 0)
	end if
end sub

sub cycleMusic cdecl ()
	dim as short ActualNum, TurnRef
	TurnRef = TurnNum - 1
	if TurnWIP then
		if QueueNextSong = 0 then
			QueueNextSong = 1
		end if
	elseif GameID = 0 OR FileExists("Ambient 1.ogg") = 0 then
		loadMusic("Menu")
	else
		for Cap as byte = 10 to 1 step -1
			ActualNum = remainder(TurnRef,Cap) + 1
			if FileExists("Ambient "+str(ActualNum)+".ogg") then
				loadMusic("Ambient "+str(ActualNum))
				exit for
			end if
		next Cap
	end if
end sub

sub playSong
	' This begins playing the music
	Mix_PlayMusic(music, 0)

	/'
	 ' We want to know when our music has stopped playing so we
	 ' can cycle it.
	 '/
	Mix_HookMusicFinished(@cycleMusic)
end sub

sub loadMusic(MusicFile as string)
	if (music) then
		' Stop the music from playing
		Mix_HaltMusic
		
		/'
		 ' Unload the music from memory, since we don't need it
		 ' anymore
		 '/
		Mix_FreeMusic(music)
		
		music = NULL
	end if

	' Loads up the music, if file exists
	if FileExists(MusicFile + ".ogg") then
		music = Mix_LoadMUS(MusicFile + ".ogg")
		playSong
	end if
end sub
