Program FileDateTime;
{$I-,S-,R-,E-,D-,L-}
uses
	crt, dos;
var
	f: file;
	t: datetime;
	dt: longint;

function inttostr (a:integer): string;
var
	i: integer;
	s: string;
begin
	i:= 1;
	s:= '';
	repeat
		s:= char(a mod 10 + byte('0')) + s;
		a:= a div 10;
		inc (i);
	until a=0;
	if byte(s[0]) mod 2 = 1 then s:= '0'+s;
	inttostr:= s;
end;	{inttostr}

Procedure KeyboardtoDatetime (var t: datetime);
var
	i: integer;
	s: string;
	ch: char;
Begin
	s:= inttostr(t.year)+'-'+inttostr(t.month)+'-'+inttostr(t.day)+' '
		 +inttostr(t.hour)+':'+inttostr(t.min);
	writeln;
	writeln ('Please reset file date and time, press ENTER to update, press ESC to cancel.');
	writeln ('Ins,  Del  : Year');
	writeln ('Home, End  : Month');
	writeln ('PgUp, PgDn : Day');
	writeln ('Up,   Down : Hour');
	writeln ('Left, Right: Minute');
	writeln;
	write (paramstr(1), ': ', s, '  ');
	repeat
		ch:= readkey;
		if ch=#0 then begin
			ch:= readkey;
			if ch=#75 then if t.min=0     then t.min:=59    else dec (t.min);
			if ch=#77 then if t.min=59    then t.min:=0     else inc (t.min);
			if ch=#80 then if t.hour=0    then t.hour:=23   else dec (t.hour);
			if ch=#72 then if t.hour=23   then t.hour:=0    else inc (t.hour);
			if ch=#81 then if t.day=1     then t.day:=31    else dec (t.day);
			if ch=#73 then if t.day=31    then t.day:=1     else inc (t.day);
			if ch=#79 then if t.month=1   then t.month:=12  else dec (t.month);
			if ch=#71 then if t.month=12  then t.month:=1   else inc (t.month);
			if ch=#83 then if t.year=1    then t.year:=2030 else dec (t.year);
			if ch=#82 then if t.year=2030 then t.year:=1    else inc (t.year);
			s:= inttostr(t.year)+'-'+inttostr(t.month)+'-'+inttostr(t.day)+' '
				 +inttostr(t.hour)+':'+inttostr(t.min);
			write (#13, paramstr(1), ': ', s, '  ');
		end;
	until (ch=#13) or (ch=#27);
	if ch=#27 then halt;
End;	{KeyboardtoDatetime}

Procedure ParamstrtoDatetime (var t: datetime);
var
	i: integer;
	s: string;
Begin
	s:= paramstr(2);	{97-11-21 20:35}
	if not ((s[0]=#5) or (s[0]=#8) or(s[0]=#14)) then begin
		writeln ('Format error!'); halt;
	end;

	for i:= 1 to 14 do dec (s[i], byte('0'));
	if (s[0]=#14) or (s[0]=#8) then begin		{date}
		t.year := 1900+byte(s[1])*10+byte(s[2]);
		t.month:= byte(s[4])*10+byte(s[5]);
		t.day  := byte(s[7])*10+byte(s[8]);
	end;
	if s[0]=#14 then begin		{time}
		t.hour := byte(s[10])*10+byte(s[11]);
		t.min  := byte(s[13])*10+byte(s[14]);
		t.sec  := 0;
	end
	else if s[0]=#5 then begin		{time}
		t.hour := byte(s[1])*10+byte(s[2]);
		t.min  := byte(s[4])*10+byte(s[5]);
		t.sec  := 0;
	end;
End;	{ParamstrtoDatetime}

BEGIN
	if paramcount = 0 then begin
		writeln;
		writeln ('File date and time cure program');
		writeln ('usage  : dt <filename> [datetime]');
		writeln ('example: dt test.txt 97-07-21 13:30');
		writeln ('         dt test.exe 97-11-01 09:05');
		writeln ('         dt test.txt 97-06-22');
		writeln ('         dt test.exe 10:30');
		writeln ('         dt test.txt 10:30');
		writeln ('         dt test.exe');
		halt;
	end;

	assign (f, paramstr(1));
	filemode:= 0;	{read only}
	reset (f);
	if ioresult<>0 then begin
		writeln ('Cannot open file.');
		halt;
	end;
	getftime (f, dt);
	close (f);

	unpacktime (dt, t);
	if paramcount=1 then KeyboardtoDateTime (t)
	else ParamstrtoDatetime (t);
	PackTime (t, dt);
	reset (f);
	setftime (f, dt);
	if DosError<>0 then writeln ('Some Error happened !');
	close (f);
END.

97-11-21 19:30
