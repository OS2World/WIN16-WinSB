Whenever you start a Win-OS/2 session, which has Sound Blaster drivers
installed, and that the Sound Blaster is not made available to this
session, the drivers gives you 3-4 system modal error messages you have
to click before continuing loading your application.  Not only is it
annoying, but it considerably augment the time for loading the Win-OS/2
sessions that do not need any sound.  I also found out that these Windows
sound driver can corrupt the sound of another session if they do not load
(ie.: if they display the error messages).  On the other hand, if you let
the session load with sound, it will aquire the sound card for no useful
purpose.

Because of that, people found ways to overcome this, and they found out
that removing AUDIOVDD.SYS would allow sound card sharing between all
sessions.  However, this makes the system very unstable, since the sound
driver can crash if two requests are made at the same time by two different
sessions.

The best solution would have been a universal Windows driver that would
have used OS/2 specific calls to any OS/2 sound card driver supporting
these calls (like seamless audio!), but try to ask that to IBM.  Oh BTW,
The Manley UltraSound driver supports this.  I have heard some MWave and
ESS AudioDrive can do it also, but these are all proprietary technologies.
So, here is my solution for the Sound Blaster (the idea can be applied to
other sound cards if needed however).

Win-OS/2 Sound Blaster error message removal  
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                    (c) 1997 Samuel Audet <guardia@cam.org>

The principle is pretty simple: it is a little program that detects if the
DOS session has access to the Sound Blaster and then modifies SYSTEM.INI,
remming or unremming the drivers, based on the detection. The latter should
work proprely on any Sound Blaster of the family. WINSB has been written in
Pascal and compiled with Turbo Pascal 7.0.

You will need to make sure your current Win-OS/2 session have the drivers
installed and working.  Then, you can add WINSB.EXE in your OS/2
AUTOEXEC.BAT anywhere, but preferably after 'SET WIN3DIR' if such a line
exists.  To avoid confusing, just add it at the end of your AUTOEXEC.BAT.
WinSB.EXE has three _optional_ parameters.

WinSB.EXE [/D <Win-OS/2 directory>] [/V] [/?]

   /D to specify Win-OS/2 directory. The default is the one found in 'WIN3DIR'
      environment, which is normally set up by OS/2 in AUTOEXEC.BAT.

   /V is for Verbose, gives information.

   /? This help screen.

ex.:  f:\winsb /d f:\os2\mdos\winos2 /v

Tadam!! sound in Win-OS/2 when you want, and no errors when you don't. :)

Notes
~~~~~
This change affects all DOS session running AUTOEXEC.BAT (or whichever
batch file you are using by default), but this is not a big problem except
when the your sound card is used and a DOS session opens with
AUDIO_ADAPTER_SHARING set to Required; OS/2 will generate an error.  Set
this setting to Optional if this session doesn't always require the sound
card anyway.

WINSB will make a backup of SYSTEM.INI to SYSTEM.BAK.  If for any reasons,
WINSB fails and destroys SYSTEM.INI, copy SYSTEM.BAK back to SYSTEM.INI as
soon as possible, or on the next execution, it will be lost.  A permanent
backup of SYSTEM.INI should also be done manually just in case.

Also, beware that old revisions of OS/2 Warp 3 has a bug which makes DOS
session grab the sound card for its whole session even if it uses it only
for a second.  Please install the latest FixPak.

Does this problem affects other sound cards??  Let me know.

Thanks to Tony Sanders <ynotme@sans.vuw.ac.nz> for letting me know that
the Windows Sound Blaster driver could function without the BLASTER
environment.  This is why WINSB now looks in SYSTEM.INI for Sound Blaster
settings.
