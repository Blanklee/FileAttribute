program Fa;

uses
  Forms,
  Fattru in 'Fattru.pas' {FattrForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := '���� ��¥/�ð�/�Ӽ�';
  Application.CreateForm(TFattrForm, FattrForm);
  Application.Run;
end.

