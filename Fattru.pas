unit Fattru;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	StdCtrls, Buttons, Spin, FileDrop;

type
	TFattrForm = class(TForm)
		OpenDialog1: TOpenDialog;
		SpinEdit1: TSpinEdit;
		SpinEdit2: TSpinEdit;
		SpinEdit3: TSpinEdit;
		SpinEdit4: TSpinEdit;
		SpinEdit5: TSpinEdit;
		SpinEdit6: TSpinEdit;
		Label1: TLabel;
		Label2: TLabel;
		Label3: TLabel;
		Label4: TLabel;
		Label5: TLabel;
		Label6: TLabel;
		Label7: TLabel;
		Label8: TLabel;
		OpenButton: TBitBtn;
		RestoreButton: TBitBtn;
		ApplyButton: TBitBtn;
		ExitButton: TBitBtn;
		GroupBox1: TGroupBox;
		CheckBox1: TCheckBox;
		CheckBox2: TCheckBox;
		CheckBox3: TCheckBox;
		CheckBox4: TCheckBox;
		FileDrop1: TFileDrop;
		procedure FormCreate(Sender: TObject);
		procedure SpinEdit1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure SpinEdit1Change(Sender: TObject);
		procedure OpenFile(Sender: TObject);
		procedure RestoreAttr(Sender: TObject);
		procedure ApplyAttr(Sender: TObject);
		procedure ExitClick(Sender: TObject);
		procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
		procedure FileDrop1Drop(Sender: TObject);
	private
		{ Private declarations }
		filename: string;
		dirty: boolean;
		sysdt: TSystemTime;						//날짜저장용
		attr: integer;							//속성저장용
		DefaultWidth: integer;					//파일이름이 길경우 창을 늘였다가 다시 줄일때 돌아올 크기
		OpenMode: (omDialog, omDrop, omParam);	//일반열기, Drag & Drop으로 열기, ParamStr(1)로 열기
		procedure DisplayAttrib;				//파일의 현재날짜와 속성을 불러와 표시해 준다.
		function Cure1 (s: string): string;		//파일이름에서 \를 /로 바꾸어 준다.
	public
		{ Public declarations }
	end;

var
	FattrForm: TFattrForm;

implementation

{$R *.DFM}


//파일의 현재날짜와 속성을 표시해 준다.
procedure TFattrForm.DisplayAttrib;
const
	DayOfWeek = '일월화수목금토';
var
	s: string;
begin
	// 이 함수 동작중에는 딴짓 못하도록 Lock을 건다.
	SpinEdit1.tag:= 0;

	dirty:= false;
	SpinEdit1.value:= sysdt.wYear;
	SpinEdit2.value:= sysdt.wMonth;
	SpinEdit3.value:= sysdt.wDay;
	SpinEdit4.value:= sysdt.wHour;
	SpinEdit5.value:= sysdt.wMinute;
	SpinEdit6.value:= sysdt.wSecond;
	s:= '현재날짜: ' + inttostr(sysdt.wYear) + '-';
	if sysdt.wMonth < 10 then s:= s+'0';
	s:= s + inttostr(sysdt.wMonth) + '-';
	if sysdt.wDay < 10 then s:= s+'0';
	s:= s + inttostr(sysdt.wDay) + ' (';
	s:= s + DayOfWeek[sysdt.wDayOfWeek*2+1] + DayOfWeek[sysdt.wDayOfWeek*2+2] + '요일) ';
	if sysdt.wHour < 10 then s:= s+'0';
	s:= s + inttostr(sysdt.wHour) + ':';
	if sysdt.wMinute < 10 then s:= s+'0';
	s:= s + inttostr(sysdt.wMinute) + ':';
	if sysdt.wSecond < 10 then s:= s+'0';
	s:= s + inttostr(sysdt.wSecond) + '';
	Label8.caption:= s;

	CheckBox1.checked:= (attr and faArchive)  <> 0;
	CheckBox2.checked:= (attr and faReadOnly) <> 0;
	CheckBox3.checked:= (attr and faHidden)   <> 0;
	CheckBox4.checked:= (attr and faSysFile)  <> 0;
	s:= '파일속성 (현재속성: ';
	if CheckBox1.checked then s:= s+'A';
	if CheckBox2.checked then s:= s+'R';
	if CheckBox3.checked then s:= s+'H';
	if CheckBox4.checked then s:= s+'S';
	GroupBox1.caption:= s + ')';

	//파일이름이 너무 길면 잘리므로 폼의 너비를 키워준다
	Width:= DefaultWidth;		//전에 길게 늘여져 있었으면 원래대로 복구
	if Width < Label7.Left + Label7.Width + 20 then
		Width:= Label7.Left + Label7.Width + 20;

	// Lock을 풀어준다.
	SpinEdit1.tag:= 0;
end;	//SetValues

procedure TFattrForm.FormCreate(Sender: TObject);
begin
	filename:= '';
	dirty:= false;
	attr:= 0;
	DefaultWidth:= Width;
	fillchar (sysdt, sizeof(sysdt), 0);

	//명령행에서 인자를 주거나 탐색기에서 이 프로그램의 단축아이콘으로 Drag & Drop했을 경우
	if (ParamCount > 0) then begin
		OpenMode:= omParam;		//OpenFile 함수에서 ParamStr(1)을 열도록 해놓는다.
		OpenFile (Sender);		//파일을 연다.
	end else OpenMode:= omDialog;
end;

procedure TFattrForm.SpinEdit1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	if Key=VK_RETURN then
		if ApplyButton.Default then ApplyAttr (Sender)
		else if OpenButton.Default then OpenFile (Sender);
end;	//SpinEdit1KeyDown

procedure TFattrForm.SpinEdit1Change(Sender: TObject);
var
	a: integer;
begin
	//파일을 불러오는 동안에는 비록 SpinEdit 1부터 6가찌 열나게 바뀌더라도
	//아무짓 안하고 그냥 빠져나간다.
	if SpinEdit1.tag = 1 then exit;

	//SpinEdit 쪽이 뭔가 바뀌었다면
	if (Sender is TSpinEdit) then begin
		// SpinEdit 값이 min과 max 사이를 한바퀴 돌수 있도록 지원한다.
		if (Sender as TSpinEdit).Text = '' then exit;
		if (Sender as TSpinEdit).Value = (Sender as TSpinEdit).MinValue then
			(Sender as TSpinEdit).Value:= (Sender as TSpinEdit).MaxValue - 1;
		if (Sender as TSpinEdit).Value = (Sender as TSpinEdit).MaxValue then
			(Sender as TSpinEdit).Value:= (Sender as TSpinEdit).MinValue + 1;
	end;

	//CheckBox 쪽이 뭔가 바뀌었다면
	a:= attr;
	if (Sender is TCheckBox) then begin
		//사용자가 바꾼 속성과 원래의 파일속성을 비교한다
		if CheckBox1.Checked then a:= a or faArchive
		else a:= a and (not faArchive);
		if CheckBox2.Checked then a:= a or faReadOnly
		else a:= a and (not faReadOnly);
		if CheckBox3.Checked then a:= a or faHidden
		else a:= a and (not faHidden);
		if CheckBox4.Checked then a:= a or faSysFile
		else a:= a and (not faSysFile);
	end;

	//바꾼 결과가 원래것과 같으면
	if(a = attr) and
		(sysdt.wYear   = SpinEdit1.Value) and
		(sysdt.wMonth  = SpinEdit2.Value) and
		(sysdt.wDay    = SpinEdit3.Value) and
		(sysdt.wHour   = SpinEdit4.Value) and
		(sysdt.wMinute = SpinEdit5.Value) and
		(sysdt.wSecond = SpinEdit6.Value) then
	begin
		dirty:= false;
		RestoreButton.Enabled:= false;
	end

	//원래파일의 날짜/시각/속성과 달라졌으면
	else begin
		dirty:= true;
		RestoreButton.Enabled:= true;
	end;
end;	//SpinEdit1Change

procedure TFattrForm.OpenFile(Sender: TObject);
var
	r: word;
begin
	if dirty then begin				//변경사항이 있으면 물어보고 처리한다
		r:= MessageDlg ('변경사항을 기록할까요?', mtConfirmation, mbYesNoCancel, 0);
		if r = mrCancel then exit;
		if r = mrYes then begin
			ApplyAttr (Sender);		//기록을 한다
			if dirty then exit;		//기록을 실패했으면 그냥 빠져나간다
		end;
	end;

	//Drag & Drop 으로 요청된 파일을 여는 경우나 Command Parameter를 통해 파일을 여는 경우는 일반적인 파일열기의 경우가 조금 다르다.
	if OpenMode = omParam then			//명령행에서 인자를 주거나 탐색기에서 이 프로그램의 단축아이콘으로 Drag & Drop했을 경우
		filename:= ParamStr(1)			//여러 파일이 뭉치로 들어오면 그중 첫번째 하나만 열도록 한다.
	else if OpenMode = omDrop then			//Drag & Drop 하여 파일을 연다면 대화상자 열지말고 바로 파일을 연다.
		filename:= FileDrop1.Files.Strings[0]	//여러 파일이 뭉치로 들어오면 그중 첫번째 하나만 열도록 한다.
	else begin					//메뉴 등을 통하여 일반적으로 파일을 여는 경우
		if OpenDialog1.Execute = false then exit;
		filename:= OpenDialog1.FileName;
	end;
	OpenMode:= omDialog;				//Default값으로 해준다.

	//filename에 대한 정보를 읽어와 표시해 준다.
	Label1.Enabled:= true;
	Label2.Enabled:= true;
	Label3.Enabled:= true;
	Label4.Enabled:= true;
	Label5.Enabled:= true;
	Label6.Enabled:= true;
	Label7.Enabled:= true;
	Label7.caption:= '파일: ' + Cure1(filename);	//모든 \를 /로 바꾼다.
	Label8.Enabled:= true;
	SpinEdit1.Enabled:= true;
	SpinEdit2.Enabled:= true;
	SpinEdit3.Enabled:= true;
	SpinEdit4.Enabled:= true;
	SpinEdit5.Enabled:= true;
	SpinEdit6.Enabled:= true;
	SpinEdit1.Color:= clWindow;
	SpinEdit2.Color:= clWindow;
	SpinEdit3.Color:= clWindow;
	SpinEdit4.Color:= clWindow;
	SpinEdit5.Color:= clWindow;
	SpinEdit6.Color:= clWindow;
	SpinEdit1.Font.Color:= clBlack;
	SpinEdit2.Font.Color:= clBlack;
	SpinEdit3.Font.Color:= clBlack;
	SpinEdit4.Font.Color:= clBlack;
	SpinEdit5.Font.Color:= clBlack;
	SpinEdit6.Font.Color:= clBlack;
	GroupBox1.Font.Color:= clBlack;
	GroupBox1.Enabled:= true;
	// SpinEdit6.SetFocus;

	try
		DateTimeToSystemTime(FileDateToDateTime(FileAge(filename)), sysdt);
	except
		ShowMessage ('파일을 읽을수 없습니다.');
	end;

	attr:= FileGetAttr (filename);
	DisplayAttrib;

	OpenButton.Default:= false;
	RestoreButton.Enabled:= false;
	ApplyButton.Enabled:= true;			//Apply 버튼은 항상 Enable로 놔둔다
	ApplyButton.Default:= true;			//ENTER만 치면 기록을 할수있게
end;	//BitBtn1Click

procedure TFattrForm.RestoreAttr(Sender: TObject);
begin
	DisplayAttrib;
	RestoreButton.Enabled:= false;
end;	//BitBtn2Click

procedure TFattrForm.ApplyAttr(Sender: TObject);
var
	a: integer;		//temp attr
	d: TSystemTime;		//temp sysdt
	FileHandle: integer;
begin
	//CheckBox로부터 속성을 조합해 만든다
	a:= 0;
	if CheckBox1.checked then a:= a or faArchive;
	if CheckBox2.checked then a:= a or faReadOnly;
	if CheckBox3.checked then a:= a or faHidden;
	if CheckBox4.checked then a:= a or faSysFile;

	//SpinEdit로부터 날짜/시각을 긁어와 조합한다
	fillchar (d, sizeof(d), 0);
	d.wYear  := SpinEdit1.value;
	d.wMonth := SpinEdit2.value;
	d.wDay   := SpinEdit3.value;
	d.wHour  := SpinEdit4.value;
	d.wMinute:= SpinEdit5.value;
	d.wSecond:= SpinEdit6.value;

	if attr and faReadOnly <> 0 then		//ReadOnly이면 날짜를 기록할 수 없으므로 잠시 꺼둔다
	if(FileSetAttr(filename, attr and (not faReadOnly)) <> 0) then begin
		MessageDlg ('파일의 날짜/시각/속성을 기록할 수가 없습니다.', mtError, [mbOk], 0); exit;
	end;

	FileHandle:= FileOpen (filename, fmOpenReadWrite or fmShareDenyNone);
	if(FileSetDate(FileHandle,DateTimeToFileDate(SystemTimeToDateTime(d))) <> 0) then begin
		MessageDlg ('파일의 날짜/시각/속성을 기록할 수가 없습니다.', mtError, [mbOk], 0);
		FileClose (FileHandle);			//파일을 닫고
		FileSetAttr (filename, attr);		//원래 속성대로 복귀시켜 주고
		exit;					//빠져나간다
	end;
	FileClose (FileHandle);

	FileSetAttr(filename,a);			//속성을 기록해 준다. 더이상 별다른 에러가 나지 않는다고 가정한다

	dirty:= false;					//기록을 성공적으로 했으니까 깨끗해졌다
	RestoreButton.Enabled:= false;

	//attr와 sysdt를 uodate해 준다.
	attr:= a;
	sysdt:= d;

	//바뀐 속성을 표시해 준다 (SetValues에 있는 것과 똑같은 여섯 줄임)
	DisplayAttrib;
end;	//BitBtn3Click

procedure TFattrForm.ExitClick(Sender: TObject);
begin
	Close;
end;

procedure TFattrForm.FormCloseQuery(Sender: TObject;
	var CanClose: Boolean);
var
	r: word;
begin
	CanClose:= true;
	if not dirty then exit;
	//변경사항이 있으면 물어보고 처리한다
	r:= MessageDlg ('변경사항을 기록할까요?', mtConfirmation, mbYesNoCancel, 0);
	if r = mrNo then exit;
	if r = mrYes then begin
		ApplyAttr (Sender);			//기록을 한다
		if dirty then CanClose:= false;		//기록을 실패했으면 빠져나가지 않는다
		exit;
	end;
	if r = mrCancel then CanClose:= false;
end;

procedure TFattrForm.FileDrop1Drop(Sender: TObject);
begin
	OpenMode:= omDrop;				//OpenStep 함수에서 파일을 열 때 파일열기 대화상자를 실행하지 않고
	OpenFile (Sender);				//Drop된 파일 중에서 첫번째 것을 열도록 지정해 준다.
end;	//FileDrop1Drop

//C:\File 을 C:/File로 바꾼다
function TFattrForm.Cure1 (s: string): string;
var
	i: integer;
begin
	//모든 \를 /로 바꾼다.
	for i:= length(s) downto 1 do
	if s[i] = '\' then s[i]:= '/';
	result:= s;
end;

end.

