#include "SDL/SDL.bi"
#include "SDL/SDL_mixer.bi"

dim shared music as Mix_Music ptr
music = NULL

dim audio_rate as integer
dim audio_format as Uint16
dim audio_channels as integer
dim audio_buffers as integer

audio_rate = 44100
audio_format = AUDIO_S16
audio_channels = 2
audio_buffers = 4096

SDL_Init(SDL_INIT_AUDIO)

if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers)) then
	print "Unable to open audio!"
	
	cleaning
	end 1
end if
Mix_QuerySpec(@audio_rate, @audio_format, @audio_channels)

declare sub loadMusic(MusicFile as string)
declare sub playSong

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

        ' Unload the music from memory, since we don't need it
        ' anymore
        Mix_FreeMusic(music)

        music = NULL
    end if

	' Actually loads up the music, if file exists
	if FileExists(MusicFile + ".ogg") then
	    music = Mix_LoadMUS(MusicFile + ".ogg")
		playSong
    end if
end sub
