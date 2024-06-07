program Fa;

uses
  Forms,
  Fattru in 'Fattru.pas' {FattrForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := '파일 날짜/시간/속성';
  Application.CreateForm(TFattrForm, FattrForm);
  Application.Run;
end.

