(* Win-OS/2 Sound Blaster driver error message removal          *)
(* (c) 1997 Samuel Audet <guardia@cam.org>  distribute freely!  *)

program winsb;

uses dos;

var line,windir   : string;
    newini,oldini : text;
    detected,verbose : boolean;
    mode    : byte;
    SBFMPort,code : integer;

(* Strips leading and trailing spaces from strings *)

function strip(str : string) : string;
begin
   while pos(' ',str) = 1 do
      delete(str, pos(' ',str), 1);
   while copy(str, length(str), 1) = ' ' do
      delete(str, length(str), 1);
   strip := str;
end;

(* adds semi-colon before a string *)

procedure addsemi(var str : string);
begin
   str := strip(str);
   if str <> '' then
      if pos(';',str) <> 1 then
         insert(';',str,1);
end;

(* removes any semi-colon before a string *)

procedure remsemi(var str : string);
begin
   str := strip(str);
   while pos(';',str) = 1 do begin
      delete(str,1,1);
      strip(str);
   end;
end;

(* translates string into uppercase *)

function translate(str : string) : string;

var i : byte;

begin
if str <> '' then
  for i := 1 to Length(str) do
    str[i] := UpCase(str[i]);
translate := str
end;

(* Routine to detect SB I/O port, thanks to...

Sound Blaster Programmers' Library, Public Domain
Programming Notes -- i.e. stuff I found out the hard way

Created by Danny Melton, a.k.a. AsmFiend
asmfiend@aol.com

...for this already made code. I don't know assembler. *)

function DetectSB : boolean;
  begin
    asm
      (* prep DSP for a reset *)
      mov al,1
      mov dx,[SBFMPort]
      add dx,6
      out dx,al
      (* delay for command to get through *)
      in al,dx
      db 0EBh,000h
      in al,dx
      db 0EBh,000h
      in al,dx
      db 0EBh,000h
      in al,dx
      db 0EBh,000h
      (* reset DSP *)
      xor al,al
      out dx,al
      add dx,8
      (* maximum number of tries to reset DSP *)
      mov cx,0100h
@@WaitForDSP: (* wait for data available from DSP to be set *)
      in al,dx
      dec cx
      (* if we've tried the maximum number of tries, then we've failed *)
      jcxz @@ResetFailed
      or al,al
      (* if data not available from DSP, keep waiting *)
      jns @@WaitForDSP
      sub dx,4
      (* read value from DSP, it should be 0AAh, but if not, try CX time *)
      mov cx,0100h
@@WaitForResponse: (* wait for correct response from DSP *)
      in al,dx
      cmp al,0AAh
      (* if match, then we're done *)
      je @@DSPisReset
      (* while we haven't exceed the maximum number of tries, try again *)
      loop @@WaitForResponse
@@ResetFailed: (* reset attempt failed *)
      mov al,false
      jmp @@GetOut
@@DSPisReset: (* reset attempt worked *)
      mov al,true
@@GetOut:
      mov [@result],al
    end;
  end;

begin
   verbose := false;
   windir := getenv('WIN3DIR');
   for mode := 1 to ParamCount do
      if translate(ParamStr(mode)) = '/V' then verbose := true
         else if translate(ParamStr(mode)) = '/D' then windir := paramstr(mode + 1)
            else if translate(ParamStr(mode)) = '/?' then begin
               Writeln('Win-OS/2 Sound Blaster driver error message removal');
               Writeln('(c) 1997 Samuel Audet <guardia@cam.org>');
               Writeln;
               Writeln('WinSB.EXE [/D <Win-OS/2 directory>] [/V] [/?]');
               Writeln;
               Writeln('   /D to specify Win-OS/2 directory. The default is the one found in ''WIN3DIR''');
               Writeln('      environment, which is normally set up by OS/2 in AUTOEXEC.BAT.');
               Writeln;
               Writeln('   /V is for Verbose, gives information.');
               Writeln;
               Writeln('   /? This help screen.');
               Writeln;
               Writeln('ex.:  f:\winsb /d f:\os2\mdos\winos2 /v');
               halt(0);
            end;

   if verbose then begin
      writeln('Executing Win-OS/2 Sound Blaster driver error message removal');
      Writeln('(c) 1997 Samuel Audet <guardia@cam.org>');
   end;

   (* remove leading slash *)

   if copy(windir,length(windir),1) = '\' then delete(windir,length(windir),1);

   (* Gets SB I/O port from SYSTEM.INI and detects the SB *)

   if verbose then writeln('Getting Sound Blaster I/O port from SYSTEM.INI and testing');

   mode := 0;
   assign(oldini,windir + '\system.ini');
   {$I-} reset(oldini); {$I+}
   case ioresult of
      2: begin writeln('Error: SYSTEM.INI was not found in ' + windir); halt(2); end;
      3: begin writeln('Error: directory ' + windir + ' does not exist'); halt(3); end;
   end;
   while not eof(oldini) do begin
      readln(oldini, line);
      if mode = 1 then begin repeat
         if pos('PORT=',translate(strip(line))) = 1 then begin
            val('$' + copy(strip(line),6,3),sbfmport,code);
            if code <> 0 then begin
               Writeln('Sound Blaster settings are garbage');
               halt(255);
            end;
            detected := detectsb;
            if verbose then begin
               if detected then writeln('Sound Blaster detected, will unrem Windows driver')
               else writeln('Sound Blaster not detected, will rem out Windows driver');
            end;
         end;
         readln(oldini, line);
      until (pos('[',strip(line)) = 1) or eof(oldini);
      mode := 5;  (* We have found an entry, see below *)
      end;

      (* Checks if we enter any interesting sections *)

      if translate(strip(line)) = '[SNDBLST.DRV]' then mode := 1
   end;
   close(oldini);

   if mode <> 5 then begin
      Writeln('Sound Blaster settings not found');
      halt(255);
   end;

   if verbose then writeln('Backing up SYSTEM.INI to SYSTEM.BAK');
   {$I-} rename(oldini,windir + '\system.bak'); {$I+}
   if ioresult = 5 then begin
      assign(oldini,windir + '\system.bak');
      erase(oldini);
      assign(oldini,windir + '\system.ini');
      rename(oldini,windir + '\system.bak');
   end;
   assign(newini, windir + '\system.ini');

   (* mode = 1  We're in [386Enh] section
      mode = 2  We're in [drivers] section
      anything else, we're in no interesting place

      This section checks SYSTEM.INI for relevant SB drivers and rem or
      unrem them out depending on if an SB was detected    *)

   if verbose then writeln('Starting modifications to SYSTEM.INI');
   mode := 0;
   reset(oldini);
   rewrite(newini);
   while not eof(oldini) do
   begin
      readln(oldini, line);
      case mode of
         1: begin repeat
               if pos('VSBPD.386',translate(strip(line))) > 0 then
                  if detected then remsemi(line)
                     else addsemi(line);
               writeln(newini,line);
               readln(oldini, line);
            until (pos('[',strip(line)) = 1) or eof(oldini);
            mode := 0;
            end;
         2: begin repeat
               if (pos('SBAWE32.DRV',translate(strip(line))) > 0) or
                  (pos('SB16FM.DRV',translate(strip(line))) > 0) or
                  (pos('SB16SND.DRV',translate(strip(line))) > 0) or
                  (pos('SB16AUX.DRV',translate(strip(line))) > 0) or
                  (pos('SB15SND.DRV',translate(strip(line))) > 0) or
                  (pos('SBFM.DRV',translate(strip(line))) > 0) or
                  (pos('SB20SND.DRV',translate(strip(line))) > 0) or
                  (pos('SBMCVSND.DRV',translate(strip(line))) > 0) or
                  (pos('SBP2FM.DRV',translate(strip(line))) > 0) or
                  (pos('SBPAUX.DRV',translate(strip(line))) > 0) or
                  (pos('SBPSND.DRV',translate(strip(line))) > 0) or
                  (pos('SPMCVSND.DRV',translate(strip(line))) > 0) or
                  (pos('SBPFM.DRV',translate(strip(line))) > 0) then
                     if detected then remsemi(line)
                        else addsemi(line);
               writeln(newini,line);
               readln(oldini, line);
            until (pos('[',strip(line)) = 1) or eof(oldini);
            mode := 0;
            end;
      end;

      (* Checks if we enter any interesting sections *)

      if translate(strip(line)) = '[386ENH]' then mode := 1
         else if translate(strip(line)) = '[DRIVERS]' then mode := 2;

     writeln(newini,line);
   end;
   close(oldini);
   close(newini);
   if verbose then writeln('Done!');
end.