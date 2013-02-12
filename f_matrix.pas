unit f_matrix;
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls,registry, sSkinProvider, sSkinManager, Buttons,
  sBitBtn, sLabel, sPanel, sEdit, sButton;
const
  MAXCOLUMNS = 165;
  NUMCOLUMNS:integer = 80;//165;
  BWidth = 20;
  BHeight = 20;
  numBitmaps = 40;
  IgnoreCount : Integer = 10;

type  TSSMode = (ssSetPwd,ssPreview,ssConfig,ssRun);
const
  SSMode      : TSSMode = ssRun;
  TestMode    : Boolean = True;
type
  TGraphicManager=class
  private
    { Private declarations }
    fMapWidth : integer;
    fMapHeight : Integer;
    fBitMap : TBitmap;
    fDefaultDC : TCanvas;

  public

     procedure BltDefaultIndex(index : Integer;x,y : integer);
     procedure BltToCanvas(sr:Trect;DestCoord:Tpoint;DestDC:TCanvas);
     property OutPutDC : TCanvas read FDefaultDC write fDefaultDC;
     property Bitmap : TBitmap read fBitmap write fBitmap;
     property MapHeight : integer read fmapHeight write FMapHeight;
     property MapWidth : integer read fmapwidth write fMapWidth;
  end;

  TMatrixColumn = class
  private
    fStartPos : integer;
    fRendervar : integer;
    fIntense,FNormal : TGraphicManager;
    FNumLetters,flastSentIndex,fCurrentPosition : Integer;
    fMaxy,fColumnX : integer;
    FLetterWIdth,FLetterHeight : integer;
    procedure SetIntense(const Value: TGraphicManager);
    procedure SetNormal(const Value: TGraphicManager);
    procedure SetstartPos(index: Integer);
  protected

  public
    constructor create;
    procedure RenderNext;
    Property StartPos : Integer read fstartPos write SetstartPos;
    property NumLetters : integer read fnumletters write FNumLetters;
    property Intense : TGraphicManager read fintense write SetIntense;
    property Normal : TGraphicManager read fNormal write SetNormal;
    property ColumnX : integer read FColumnX write FColumnX;
    Property MaxY : integer read fmaxy write fmaxy;

  end;



type
 pintarray = ^intarray;
 intarray = array[0..0] of integer;

type
  TfrmMatrix = class(TForm)
    Image1: TImage;
    Timer1: TTimer;
    Image2: TImage;
    sSkinManager1: TsSkinManager;
    sSkinProvider1: TsSkinProvider;
    sPanel1: TsPanel;
    sLabelFX1: TsLabelFX;
    sPanel3: TsPanel;
    sBitBtn1: TsBitBtn;
    sLabel1: TsLabel;
    sLabel2: TsLabel;
    sPanel2: TsPanel;
    sEdit1: TsEdit;
    sEdit2: TsEdit;
    sButton1: TsButton;
   
    procedure Timer1Timer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sBitBtn1Click(Sender: TObject);
  private
    { Private declarations }
   mouse : Tpoint;
     c : Integer;
  public
    LoadingApp : Boolean;
    { Public declarations }
  end;

 var
  OutDc       : THandle;
  frmMatrix: TfrmMatrix;
  bm : Tbitmap;
  empty,gm,gmi : TGraphicManager;
  Columns : Array[0..MAXCOLUMNS-1] of TMatrixColumn;

implementation

{$R *.DFM}

uses sSkinProps,sConst;

var
  MySem       : THandle;
  Arg1,  Arg2        : String;
  DemoWnd     : HWnd;
  MyRect      : TRect;
  MyCanvas    : TCanvas;
  x, y,  dx, dy      : Integer;
  MyBkgBitmap,  InMemBitmap : TBitmap;
  ScrWidth,  ScrHeight   : Integer;
  SysDir      : String;
  NewLen      : Integer;
  MyMod       : THandle;

{ TGraphicManager }

procedure TGraphicManager.BltDefaultIndex(index: Integer; x,y :Integer);
var
  sr : TRect;
begin
  with sr do
  begin
   left := 0;
   top  := index*FMapHeight;
   right := fMapWidth;
   bottom := top +fMapHeight;
  end;
  BltToCanvas(sr,Point(x,y),fdefaultdc);
end;

procedure TGraphicManager.BltToCanvas(sr: Trect; DestCoord: Tpoint;  DestDC: TCanvas);
var  re1: TRect; re2: TRect;
begin
  re1 := Rect(DestCoord.X,DestCoord.Y,DestCoord.X+sr.right-sr.left,DestCoord.Y+sr.bottom-sr.top);
  re2 := Rect(sr.Left,sr.top,sr.Left + sr.right-sr.left,sr.top + sr.bottom-sr.top);
  DestDC.CopyRect(re1,fBitmap.Canvas,re2);
end;

procedure TfrmMatrix.Timer1Timer(Sender: TObject);
var
  i : integer;
  b : TBitmap;
  x, y : Integer;
  s:String;  
begin
  Timer1.Enabled := False;
  try
    Inc(c);

	s := UpperCase(s_Pattern);

  for i := Length(sSkinManager1.ma)-1 downto 0 do
  begin
    if ((UpperCase(sSkinManager1.ma[i].PropertyName) = s) and (UpperCase(sSkinManager1.ma[i].ClassName) = UpperCase(s_Form))) then
    begin
      // If found then we must define new Bmp
      if (sSkinManager1.ma[i].Bmp = nil) then
         sSkinManager1.ma[i].Bmp := TBitmap.Create();

       if (sSkinManager1.ma[i].Bmp.Width <= 350) then
       begin
          sSkinManager1.ma[i].R := Rect(0,0,0,0);
          sSkinManager1.ma[i].Bmp.SetSize(self.Height,self.Width);
          sSkinManager1.ma[i].Bmp.canvas.brush.color := clblack;
          sSkinManager1.ma[i].Bmp.Canvas.FillRect(rect(0,0,self.Height,self.Width));
       end;

       empty.OutPutDc := sSkinManager1.ma[i].Bmp.Canvas;
       gmi.outputdc := sSkinManager1.ma[i].Bmp.Canvas;
       gm.OutputDc := sSkinManager1.ma[i].Bmp.Canvas;

    for y := 0 to numColumns -1 do
      Columns[y].RenderNext;

     break;
    end
  end;

	// Update of all controls
	sSkinManager1.UpdateSkin();
  //-----------------

  finally
    Timer1.Enabled := True;
  end;  
end;


function AddBGInSkin(const SkinSection, PropName:string; sm : TsSkinManager) : boolean;
var
  i, l : integer;
  s : string;
begin
  with sm do begin
    Result := False;
    if not SkinData.Active then Exit;

    s := UpperCase(PropName);
    l := Length(ma);
    // ma - is array of records with image description
    if l > 0 then begin
      // search of the required image in the massive
      for i := 0 to l - 1 do begin
        if (UpperCase(ma[i].PropertyName) = s) and (UpperCase(ma[i].ClassName) = UpperCase(skinSection))  then begin
          Result := True;
          Break;
        end;
      end;
    end;

    // If not found we must to add new image
    if not Result then begin
      l := Length(ma) + 1;
      SetLength(ma, l);
      ma[l - 1].PropertyName := '';
      ma[l - 1].ClassName := '';
      try
        ma[l - 1].Bmp := TBitmap.Create;
        ma[l - 1].Bmp.SetSize(256,256);
      finally
        ma[l - 1].PropertyName := s;
        ma[l - 1].ClassName := UpperCase(skinSection);
        ma[l - 1].Manager := sm;
        ma[l - 1].R := Rect(0, 0, ma[l - 1].Bmp.Width, ma[l - 1].Bmp.Height);
        ma[l - 1].ImageCount := 1;
        ma[l - 1].ImgType := itisaTexture;
      end;
      if ma[l - 1].Bmp.Width < 1 then begin
        FreeAndNil(ma[l - 1].Bmp);
        SetLength(ma, l - 1);
      end;

      l := Length(pa);
      if l > 0 then for i := 0 to l - 1 do if (pa[i].PropertyName = s) and (pa[i].ClassName = UpperCase(skinSection)) then begin
        FreeAndNil(pa[i].Img);

        l := Length(pa) - 1;
        if l <> i then begin
          pa[i].Img          := pa[l].Img         ;
          pa[i].ClassName    := pa[l].ClassName   ;
          pa[i].PropertyName := pa[l].PropertyName;
        end;
        SetLength(pa, l);
        Break;
      end;
      Result := True;
    end;
  end
end;

procedure TfrmMatrix.FormActivate(Sender: TObject);
var
    SkinIndex : integer;
  i : integer;
begin
     c := 0;
  if LoadingApp then begin
    LoadingApp := False;
   end;

  // For Clearing out the columns
  bm := Tbitmap.create;
  bm.Width := BWidth;
  bm.Height := BHeight*5;
  bm.canvas.brush.color := clblack;
  bm.Canvas.FillRect(rect(0,0,bwidth,bheight*5));
  empty := TGraphicManager.Create;
  empty.Bitmap := bm;
  empty.MapWidth := Image2.picture.bitmap.width;
  empty.MapHeight := BHeight;
  // These are for the Leading intense characters
  gmi := TGraphicManager.Create;
  gmi.Bitmap := Image2.picture.bitmap;
  gmi.MapWidth := Image2.picture.bitmap.width;
  gmi.MapHeight := BHeight;
 // These are the normal characters
  gm := TGraphicManager.Create;
  gm.Bitmap := Image1.picture.bitmap;
  gm.MapWidth := Image1.picture.bitmap.width;
  gm.MapHeight := BHeight;
  randomize;
  for i := 0 to numColumns - 1 do begin
    Columns[i] := TMatrixColumn.Create;
    with columns[i] do
    begin
      StartPos := Random(Self.height div bheight)*bHeight;

      if random(3) = 2 then  // This column will be an blank column??
      begin
        Intense := Empty;
        Normal :=  Empty;
        NumLetters := 2;
      end else
        begin
          Intense := gmi;
          Normal := gm;
          NumLetters := NUMBITMAPS;
        end;
      ColumnX := Random(Self.width div BWidth)*BWidth;
      MaxY := Self.Height;
    end;
 end;


  AddBGInSkin('FORM', 'PATTERN', sSkinManager1);
  AddBGInSkin('FORM', 'HOTPATTERN', sSkinManager1);
   //Receive an index of the FORM section
  SkinIndex := sSkinManager1.GetSkinIndex('FORM');
  sSkinManager1.gd[SkinIndex].Props[0].ImagePercent := 100;
  sSkinManager1.gd[SkinIndex].Props[0].GradientPercent := 0;
  sSkinManager1.gd[SkinIndex].Props[0].Transparency := 0;
  sSkinManager1.gd[SkinIndex].Props[1].ImagePercent := 100;
  sSkinManager1.gd[SkinIndex].Props[1].GradientPercent := 0;
  sSkinManager1.gd[SkinIndex].Props[1].Transparency := 0;
  sSkinManager1.gd[SkinIndex].GradientPercent := 0;
  sSkinManager1.gd[SkinIndex].ImagePercent := 100;
  sSkinManager1.gd[SkinIndex].HotGradientPercent := 0;
  sSkinManager1.gd[SkinIndex].HotImagePercent := 100;

  sSkinProvider1.SkinData.CtrlSkinState := 0;
  sSkinProvider1.SkinData.Invalidate;
end;


{ TMatrixColumn }

constructor TMatrixColumn.create;
begin
  frenderVar := 0;
end;

procedure TMatrixColumn.RenderNext;
var
 newletter : integer;
begin

  repeat
      NewLetter := random(fNumLetters);
  until newLetter <> fLastSentIndex;

  fCurrentPosition := FCurrentPosition + fLetterHeight;
  fIntense.BltDefaultIndex(NewLetter,fColumnX,FCurrentPosition);
  fNormal.BltDefaultIndex(fLastSentIndex,fcolumnX,FCurrentPosition - fLetterHeight);
  FLastSentIndex := NewLetter;
  fRenderVar := 0;
  if FcurrentPosition  > fMaxy Then
  begin
    FCurrentPosition := 0;
    self.ColumnX := Random(100) * self.FLetterWIdth;
  end;
end;

procedure TMatrixColumn.SetIntense(const Value: TGraphicManager);
begin
  fLetterWidth := value.MapWidth;
  fLetterHeight := Value.MapHeight;
  fintense := Value;
end;

procedure TMatrixColumn.SetNormal(const Value: TGraphicManager);
begin
  fLetterWidth := value.MapWidth;
  fLetterHeight := Value.MapHeight;
  fNormal := Value;
end;

procedure TMatrixColumn.SetstartPos(index : Integer);
begin
  fCurrentPosition := index;
  FstartPos := index;
end;

procedure TfrmMatrix.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  bm.free;
end;

procedure TfrmMatrix.sBitBtn1Click(Sender: TObject);
begin
  Close()
end;

end.
