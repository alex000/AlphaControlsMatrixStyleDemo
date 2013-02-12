program matrix;

uses
  Forms,
  f_matrix in 'f_matrix.pas' {frmMatrix};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMatrix, frmMatrix);
  Application.Run;
end.
