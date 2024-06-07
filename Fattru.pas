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
		sysdt: TSystemTime;						//��¥�����
		attr: integer;							//�Ӽ������
		DefaultWidth: integer;					//�����̸��� ���� â�� �ÿ��ٰ� �ٽ� ���϶� ���ƿ� ũ��
		OpenMode: (omDialog, omDrop, omParam);	//�Ϲݿ���, Drag & Drop���� ����, ParamStr(1)�� ����
		procedure DisplayAttrib;				//������ ���糯¥�� �Ӽ��� �ҷ��� ǥ���� �ش�.
		function Cure1 (s: string): string;		//�����̸����� \�� /�� �ٲپ� �ش�.
	public
		{ Public declarations }
	end;

var
	FattrForm: TFattrForm;

implementation

{$R *.DFM}


//������ ���糯¥�� �Ӽ��� ǥ���� �ش�.
procedure TFattrForm.DisplayAttrib;
const
	DayOfWeek = '�Ͽ�ȭ�������';
var
	s: string;
begin
	// �� �Լ� �����߿��� ���� ���ϵ��� Lock�� �Ǵ�.
	SpinEdit1.tag:= 0;

	dirty:= false;
	SpinEdit1.value:= sysdt.wYear;
	SpinEdit2.value:= sysdt.wMonth;
	SpinEdit3.value:= sysdt.wDay;
	SpinEdit4.value:= sysdt.wHour;
	SpinEdit5.value:= sysdt.wMinute;
	SpinEdit6.value:= sysdt.wSecond;
	s:= '���糯¥: ' + inttostr(sysdt.wYear) + '-';
	if sysdt.wMonth < 10 then s:= s+'0';
	s:= s + inttostr(sysdt.wMonth) + '-';
	if sysdt.wDay < 10 then s:= s+'0';
	s:= s + inttostr(sysdt.wDay) + ' (';
	s:= s + DayOfWeek[sysdt.wDayOfWeek*2+1] + DayOfWeek[sysdt.wDayOfWeek*2+2] + '����) ';
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
	s:= '���ϼӼ� (����Ӽ�: ';
	if CheckBox1.checked then s:= s+'A';
	if CheckBox2.checked then s:= s+'R';
	if CheckBox3.checked then s:= s+'H';
	if CheckBox4.checked then s:= s+'S';
	GroupBox1.caption:= s + ')';

	//�����̸��� �ʹ� ��� �߸��Ƿ� ���� �ʺ� Ű���ش�
	Width:= DefaultWidth;		//���� ��� �ÿ��� �־����� ������� ����
	if Width < Label7.Left + Label7.Width + 20 then
		Width:= Label7.Left + Label7.Width + 20;

	// Lock�� Ǯ���ش�.
	SpinEdit1.tag:= 0;
end;	//SetValues

procedure TFattrForm.FormCreate(Sender: TObject);
begin
	filename:= '';
	dirty:= false;
	attr:= 0;
	DefaultWidth:= Width;
	fillchar (sysdt, sizeof(sysdt), 0);

	//����࿡�� ���ڸ� �ְų� Ž���⿡�� �� ���α׷��� ������������� Drag & Drop���� ���
	if (ParamCount > 0) then begin
		OpenMode:= omParam;		//OpenFile �Լ����� ParamStr(1)�� ������ �س��´�.
		OpenFile (Sender);		//������ ����.
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
	//������ �ҷ����� ���ȿ��� ��� SpinEdit 1���� 6���� ������ �ٲ����
	//�ƹ��� ���ϰ� �׳� ����������.
	if SpinEdit1.tag = 1 then exit;

	//SpinEdit ���� ���� �ٲ���ٸ�
	if (Sender is TSpinEdit) then begin
		// SpinEdit ���� min�� max ���̸� �ѹ��� ���� �ֵ��� �����Ѵ�.
		if (Sender as TSpinEdit).Text = '' then exit;
		if (Sender as TSpinEdit).Value = (Sender as TSpinEdit).MinValue then
			(Sender as TSpinEdit).Value:= (Sender as TSpinEdit).MaxValue - 1;
		if (Sender as TSpinEdit).Value = (Sender as TSpinEdit).MaxValue then
			(Sender as TSpinEdit).Value:= (Sender as TSpinEdit).MinValue + 1;
	end;

	//CheckBox ���� ���� �ٲ���ٸ�
	a:= attr;
	if (Sender is TCheckBox) then begin
		//����ڰ� �ٲ� �Ӽ��� ������ ���ϼӼ��� ���Ѵ�
		if CheckBox1.Checked then a:= a or faArchive
		else a:= a and (not faArchive);
		if CheckBox2.Checked then a:= a or faReadOnly
		else a:= a and (not faReadOnly);
		if CheckBox3.Checked then a:= a or faHidden
		else a:= a and (not faHidden);
		if CheckBox4.Checked then a:= a or faSysFile
		else a:= a and (not faSysFile);
	end;

	//�ٲ� ����� �����Ͱ� ������
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

	//���������� ��¥/�ð�/�Ӽ��� �޶�������
	else begin
		dirty:= true;
		RestoreButton.Enabled:= true;
	end;
end;	//SpinEdit1Change

procedure TFattrForm.OpenFile(Sender: TObject);
var
	r: word;
begin
	if dirty then begin				//��������� ������ ����� ó���Ѵ�
		r:= MessageDlg ('��������� ����ұ��?', mtConfirmation, mbYesNoCancel, 0);
		if r = mrCancel then exit;
		if r = mrYes then begin
			ApplyAttr (Sender);		//����� �Ѵ�
			if dirty then exit;		//����� ���������� �׳� ����������
		end;
	end;

	//Drag & Drop ���� ��û�� ������ ���� ��쳪 Command Parameter�� ���� ������ ���� ���� �Ϲ����� ���Ͽ����� ��찡 ���� �ٸ���.
	if OpenMode = omParam then			//����࿡�� ���ڸ� �ְų� Ž���⿡�� �� ���α׷��� ������������� Drag & Drop���� ���
		filename:= ParamStr(1)			//���� ������ ��ġ�� ������ ���� ù��° �ϳ��� ������ �Ѵ�.
	else if OpenMode = omDrop then			//Drag & Drop �Ͽ� ������ ���ٸ� ��ȭ���� �������� �ٷ� ������ ����.
		filename:= FileDrop1.Files.Strings[0]	//���� ������ ��ġ�� ������ ���� ù��° �ϳ��� ������ �Ѵ�.
	else begin					//�޴� ���� ���Ͽ� �Ϲ������� ������ ���� ���
		if OpenDialog1.Execute = false then exit;
		filename:= OpenDialog1.FileName;
	end;
	OpenMode:= omDialog;				//Default������ ���ش�.

	//filename�� ���� ������ �о�� ǥ���� �ش�.
	Label1.Enabled:= true;
	Label2.Enabled:= true;
	Label3.Enabled:= true;
	Label4.Enabled:= true;
	Label5.Enabled:= true;
	Label6.Enabled:= true;
	Label7.Enabled:= true;
	Label7.caption:= '����: ' + Cure1(filename);	//��� \�� /�� �ٲ۴�.
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
		ShowMessage ('������ ������ �����ϴ�.');
	end;

	attr:= FileGetAttr (filename);
	DisplayAttrib;

	OpenButton.Default:= false;
	RestoreButton.Enabled:= false;
	ApplyButton.Enabled:= true;			//Apply ��ư�� �׻� Enable�� ���д�
	ApplyButton.Default:= true;			//ENTER�� ġ�� ����� �Ҽ��ְ�
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
	//CheckBox�κ��� �Ӽ��� ������ �����
	a:= 0;
	if CheckBox1.checked then a:= a or faArchive;
	if CheckBox2.checked then a:= a or faReadOnly;
	if CheckBox3.checked then a:= a or faHidden;
	if CheckBox4.checked then a:= a or faSysFile;

	//SpinEdit�κ��� ��¥/�ð��� �ܾ�� �����Ѵ�
	fillchar (d, sizeof(d), 0);
	d.wYear  := SpinEdit1.value;
	d.wMonth := SpinEdit2.value;
	d.wDay   := SpinEdit3.value;
	d.wHour  := SpinEdit4.value;
	d.wMinute:= SpinEdit5.value;
	d.wSecond:= SpinEdit6.value;

	if attr and faReadOnly <> 0 then		//ReadOnly�̸� ��¥�� ����� �� �����Ƿ� ��� ���д�
	if(FileSetAttr(filename, attr and (not faReadOnly)) <> 0) then begin
		MessageDlg ('������ ��¥/�ð�/�Ӽ��� ����� ���� �����ϴ�.', mtError, [mbOk], 0); exit;
	end;

	FileHandle:= FileOpen (filename, fmOpenReadWrite or fmShareDenyNone);
	if(FileSetDate(FileHandle,DateTimeToFileDate(SystemTimeToDateTime(d))) <> 0) then begin
		MessageDlg ('������ ��¥/�ð�/�Ӽ��� ����� ���� �����ϴ�.', mtError, [mbOk], 0);
		FileClose (FileHandle);			//������ �ݰ�
		FileSetAttr (filename, attr);		//���� �Ӽ���� ���ͽ��� �ְ�
		exit;					//����������
	end;
	FileClose (FileHandle);

	FileSetAttr(filename,a);			//�Ӽ��� ����� �ش�. ���̻� ���ٸ� ������ ���� �ʴ´ٰ� �����Ѵ�

	dirty:= false;					//����� ���������� �����ϱ� ����������
	RestoreButton.Enabled:= false;

	//attr�� sysdt�� uodate�� �ش�.
	attr:= a;
	sysdt:= d;

	//�ٲ� �Ӽ��� ǥ���� �ش� (SetValues�� �ִ� �Ͱ� �Ȱ��� ���� ����)
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
	//��������� ������ ����� ó���Ѵ�
	r:= MessageDlg ('��������� ����ұ��?', mtConfirmation, mbYesNoCancel, 0);
	if r = mrNo then exit;
	if r = mrYes then begin
		ApplyAttr (Sender);			//����� �Ѵ�
		if dirty then CanClose:= false;		//����� ���������� ���������� �ʴ´�
		exit;
	end;
	if r = mrCancel then CanClose:= false;
end;

procedure TFattrForm.FileDrop1Drop(Sender: TObject);
begin
	OpenMode:= omDrop;				//OpenStep �Լ����� ������ �� �� ���Ͽ��� ��ȭ���ڸ� �������� �ʰ�
	OpenFile (Sender);				//Drop�� ���� �߿��� ù��° ���� ������ ������ �ش�.
end;	//FileDrop1Drop

//C:\File �� C:/File�� �ٲ۴�
function TFattrForm.Cure1 (s: string): string;
var
	i: integer;
begin
	//��� \�� /�� �ٲ۴�.
	for i:= length(s) downto 1 do
	if s[i] = '\' then s[i]:= '/';
	result:= s;
end;

end.

