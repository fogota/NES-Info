unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, IniFiles, ImgList;

type
  TForm1 = class(TForm)
    NameTXT: TLabeledEdit;
    Label1: TLabel;
    MapperNo: TEdit;
    Label2: TLabel;
    PROMQua: TEdit;
    Label3: TLabel;
    VROMQua: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    MIRROR: TComboBox;
    SRAM: TComboBox;
    Label6: TLabel;
    Screen4: TComboBox;
    Label7: TLabel;
    Trainer: TComboBox;
    Label8: TLabel;
    Label9: TLabel;
    SeeNow: TButton;
    Bevel1: TBevel;
    Memo1: TMemo;
    MakeBin: TButton;
    SaveDialog1: TSaveDialog;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    GroupBox1: TGroupBox;
    Memo2: TMemo;
    CloseOut: TButton;
    StaticText3: TStaticText;
    Bevel2: TBevel;
    WriteNES: TButton;
    StaticText4: TStaticText;
    Bevel3: TBevel;
    OpenIn: TButton;
    SaveDialog2: TSaveDialog;
    SaveInI: TButton;
    OpenDialog1: TOpenDialog;
    Timer1: TTimer;
    Image1: TImage;
    procedure SeeNowClick(Sender: TObject);
    procedure MakeBinClick(Sender: TObject);
    procedure StaticText2Click(Sender: TObject);
    procedure CloseOutClick(Sender: TObject);
    procedure StaticText3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OpenInClick(Sender: TObject);
    procedure SaveInIClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure WriteNESClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    _H : Array[0..15] of byte;
    _Mapper : byte;
    _PROM, _VROM : byte;
    _Mirror, _sram, _sreen4, _trainer : boolean;
    openfile : string;
  public
    { Public declarations }
    procedure InfoToHead;
    procedure ReadINItoInfo;
    procedure ReadNESheadtoInfo;
    procedure InfoToForm;
    procedure FormToInfo;
    procedure Input;
    procedure Save(savefile : string);
    procedure ShowBo(left,top : integer);
  end;

procedure makeNEShead(var H : Array of byte; Mapper: byte; PROM,VROM : byte;
     Mirror, sram, trainer, sreen4: boolean);
procedure ByteArrayToFile(const ByteArray : Array of byte;
     const FileName : string );
procedure ReadFileToBuffer(filename:string;var buf:PChar;var size : Cardinal);
procedure analyzeNEShead(var Mapper: byte; var PROM,VROM : byte;
     var Mirror, sram, trainer, sreen4: boolean; H : Array of byte);

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure makeNEShead(var H : Array of byte; Mapper: byte; PROM, VROM : byte;
     Mirror, sram, trainer, sreen4: boolean);
var
  MapperL, MapperH, temp, i : byte;
begin
  H[0] := BYTE('N');
  H[1] := BYTE('E');
  H[2] := BYTE('S');
  H[3] := $1A;
  H[4] := PROM;
  H[5] := VROM;
  MapperL := Mapper and $0F;
  MapperH := Mapper and $F0;
  temp := 0;
  if Mirror  then temp := 1 or temp;
  if sram    then temp := 2 or temp;
  if sreen4  then temp := 4 or temp;
  if trainer then temp := 8 or temp;
  H[6] := temp or (MapperL shl 4);
  H[7] := MapperH ;
  for i := 8 to 15 do H[i] := 0;
end;

procedure analyzeNEShead(var Mapper: byte; var PROM,VROM : byte;
     var Mirror, sram, trainer, sreen4: boolean; H : Array of byte);
var
   MapperL, MapperH : byte;
begin
  PROM := H[4];
  VROM := H[5];
  Mirror := ((H[6] and 1)>0);
  sram   := ((H[6] and 2)>0);
  trainer:= ((H[6] and 4)>0);
  sreen4 := ((H[6] and 8)>0);
  MapperL := ((H[6] and $F0) shr 4);
  MapperH := (H[7] and $F0);
  Mapper := (MapperH or MapperL);
end;


procedure ByteArrayToFile(const ByteArray : Array of byte; const FileName : string );
var
 Count: integer;
 F: FIle of Byte;
 pTemp: Pointer;
begin
 AssignFile( F, FileName );
 Rewrite(F);
 try
    Count := Length( ByteArray );
    pTemp := @ByteArray[0];
    BlockWrite(F, pTemp^, Count );
 finally
    CloseFile( F );
 end;
end;

procedure ReadFileToBuffer(filename:string;var buf:PChar;var size : Cardinal);
var
    F:file;
begin
    assignfile(F, filename); 
    reset(f, 1); 
    try 
        size:=FileSize(F);
        getmem(buf, size+1);
        BlockRead(F, buf^, size);
        buf[size]:=#0;
    finally 
        closefile(f); 
    end; 
end;



//类的分划线//

procedure TForm1.SeeNowClick(Sender: TObject);
var   i:integer;
begin    //预览
  FormToInfo;
  InfoToHead;
  memo1.Clear;
  for i := 0 to 15 do
   begin
     memo1.Lines.Add('D'+inttoHEX(i,2)+'='+inttoHEX(_H[i],2))
   end;
end;

procedure TForm1.InfoToHead;
begin     //变量信息转NES头文件格式
  makeNEShead(_H, _Mapper, _PROM, _VROM, _Mirror, _sram, _trainer, _sreen4);
end;

procedure TForm1.InfoToForm;
begin
  MapperNo.Text := inttostr(_Mapper);
  PROMQua.Text := inttostr(_PROM);
  VROMQua.Text := inttostr(_VROM);
  if _Mirror then MIRROR.ItemIndex := 1 else MIRROR.ItemIndex := 0;
  if _sram then SRAM.ItemIndex := 0 else SRAM.ItemIndex := 1;
  if _trainer then Trainer.ItemIndex := 0 else Trainer.ItemIndex := 1;
  if _sreen4 then Screen4.ItemIndex := 0 else Screen4.ItemIndex := 1;
end;

procedure TForm1.FormToInfo;
var
  p0, p1, p2 : integer;
begin     //窗口信息转NES头文件格式
  //输入
  p0 := strtointdef(MapperNo.Text,0);
  p1 := strtointdef(PROMQua.Text,1);
  p2 := strtointdef(VROMQua.Text,1) ;
  _Mirror := (MIRROR.ItemIndex =1);
  _sram := (SRAM.ItemIndex =0);
  _sreen4 := (Screen4.ItemIndex =0);
  _trainer := (Trainer.ItemIndex =0);
  //更正
  if p0>255 then p0 := 255;
  if p0<0   then p0 := 0;
  if p1>255 then p1 := 255;
  if p1<1   then p1 := 1;
  if p2>255 then p2 := 255;
  if p2<0   then p2 := 0;
  _Mapper := byte(p0);
  _PROM := byte(p1);
  _VROM := byte(p2);
  MapperNo.Text := inttostr(_Mapper);
  PROMQua.Text := inttostr(_PROM);
  VROMQua.Text := inttostr(_VROM);
end;

procedure TForm1.MakeBinClick(Sender: TObject);
var
  savefile : string;
  key : boolean;
begin   //保存bin
  //s := LowerCase(ExtractFileExt(openfile));
  key := (length(openfile)<>0);
  if key then
     savefile := ChangeFileExt(openfile,'.bin')
   else
    begin
     SaveDialog1.InitialDir := ExtractFilePath(Paramstr(0));
     key := SaveDialog1.Execute;
     if key then savefile := SaveDialog1.FileName;
    end;
  if key then
   begin
     FormToInfo;
     InfoToHead;
     ByteArrayToFile(_H, savefile);
     ShowBo(144, 205);
   end;
end;

procedure TForm1.StaticText2Click(Sender: TObject);
begin
  form1.Width := 600;
end;

procedure TForm1.CloseOutClick(Sender: TObject);
var
 t : string;
begin
    t := LowerCase(ExtractFileExt(openfile));
    if (t ='.vk5') then
     begin
       FormToInfo;
       Save(openfile);
     end;
    close;
end;

procedure TForm1.StaticText3Click(Sender: TObject);
begin
  form1.Height := 380;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  form1.Width := 370;
  form1.Height := 320;
  openfile := Paramstr(1);
  if length(openfile)<>0 then input;
end;

procedure TForm1.Input;
var
 t, vk5name : string;
 d : integer;
begin
    NameTXT.Text := ExtractFileName(openfile);
    t := LowerCase(ExtractFileExt(openfile));
    //d := 0;
    if (t ='.vk5') then
      begin
        vk5name := ExtractFilePath(openfile)+'HEADER.bin';
        if not FileExists(vk5name) then
         begin
          showmessage('找不到HEADER.bin。尝试找工程名.nes');
          vk5name := ChangeFileExt(openfile, '.nes');
          if not FileExists(vk5name) then
           begin
             showmessage('nes文件还没有生成，不能读取。');
             openfile := '';
           end
           else
           begin
             openfile := vk5name;
             t := '.nes';
           end;
         end
         else
         begin
           openfile := vk5name;
           t := '.bin';
         end;
        NameTXT.Text := ExtractFileName(openfile);
      end;
    WriteNES.Visible := false;
    //showmessage(openfile);
    if not (length(openfile)=0) then
    begin
     if (t ='.nes') or (t ='.bin') then
        begin
          if (t ='.nes') then WriteNES.Visible := true;
          d :=1 ;
        end
        else  
        begin
          if (t ='.ini')  then
             d := 0
            else
             begin
              if MessageDlg('将按NES读取回答Yes，按Ini读取回答No。',
              mtConfirmation, [mbYes, mbNo], 0)=mrYes then
                 d := 1
                 else
                 d:=0 ;
             end;
        end;
     //showmessage(inttostr(d));
     if d=0 then
       begin
        ReadINItoInfo;
        InfoToForm;
        //WriteNES.Visible := false;
       end
       else
       begin
        ReadNESheadtoInfo;
        InfoToForm;
        //WriteNES.Visible := (t ='.nes');
       end;
    end;
end;

procedure TForm1.ReadINItoInfo;
var
  myINI : TIniFile;
begin  //读INI，显示于窗口
  myINI := TIniFile.Create(openfile) ;
  try
    _Mapper:= myINI.ReadInteger('Head','Mapper',0) ;
    _PROM  := myINI.ReadInteger('Head','PROM',1) ;
    _VROM  := myINI.ReadInteger('Head','VROM',1) ;
    _Mirror:= myINI.ReadBool('Head','Mirror',true) ;
    _sram  := myINI.ReadBool('Head','SRAM',false) ;
    _trainer:= myINI.ReadBool('Head','Trainer',false) ;
    _sreen4:= myINI.ReadBool('Head','Sreen4',false) ;
    //CheckBox1.Checked := _sreen4
  finally
    myINI.Free;
  end;
end;

procedure TForm1.OpenInClick(Sender: TObject);
begin  //打开
  OpenDialog1.InitialDir := ExtractFilePath(Paramstr(0));
  if OpenDialog1.Execute then
   begin
    openfile := OpenDialog1.FileName;
    input;
   end;
end;

procedure TForm1.ReadNESheadtoInfo;
var
  NES : PCHAR;
  i : integer;
  size : Cardinal;
begin //读NES，显示于窗口
  ReadFileToBuffer(openfile, NES, size);
  for i := 0 to 15 do _H[i] := byte(NES[i]);
  analyzeNEShead(_Mapper, _PROM, _VROM, _Mirror, _sram, _trainer, _sreen4, _H);
end;

procedure TForm1.SaveInIClick(Sender: TObject);
var
  savefile, t : string;
begin   //保存Ini
  SaveDialog2.InitialDir := ExtractFilePath(Paramstr(0));
  if SaveDialog2.Execute  then savefile := SaveDialog2.FileName;
  if length(savefile)<>0 then
   begin
     MessageDlg('将按Ini方式保存。', mtInformation, [mbOK], 0);
     t := LowerCase(ExtractFileExt(savefile));
     if (t ='.nes') or (t ='.bin') then
      begin
        MessageDlg('错误！不能选nes或bin文件。将会破坏文件，不能修复。', mtError, [mbOK], 0);
      end
      else
      begin
        FormToInfo;
        Save(savefile);
        ShowBo(232, 285);
      end;
   end;
end;

procedure TForm1.Save(savefile : string);
var
  myINI : TIniFile;
begin
     myINI := TIniFile.Create(savefile) ;
     try
       myINI.WriteInteger('Head','Mapper',_Mapper);
       myINI.WriteInteger('Head','PROM',_PROM);
       myINI.WriteInteger('Head','VROM',_VROM);
       myINI.WriteBool('Head','Mirror',_Mirror);
       myINI.WriteBool('Head','SRAM',_sram);
       myINI.WriteBool('Head','Trainer',_trainer);
       myINI.WriteBool('Head','Sreen4',_sreen4);
       //CheckBox1.Checked := _sreen4;
     finally
       myINI.Free;
     end;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if length(openfile)<>0 then
    begin
      if LowerCase(ExtractFileExt(openfile))='.vk5' then
        begin
          FormToInfo;
          Save(openfile);
        end;
    end;
end;

procedure TForm1.WriteNESClick(Sender: TObject);
var
 Stream : TFileStream;
begin //改写NES
  FormToInfo;
  InfoToHead;
  Stream := TFileStream.Create(openfile,fmOpenWrite);
  try
    Stream.Write(_H,16);
  finally
    Stream.Free;
  end;
  ShowBo(144, 285);
end;

procedure TForm1.ShowBo(left,top : integer);
begin
 with image1.Picture do
 begin
  Bitmap.TransparentMode := tmFixed; //必须在getBitmap前设置
  //Bitmap.Transparent := True;
  Bitmap.TransparentColor := Bitmap.Canvas.Pixels[0, 0]; //必须在getBitmap后设置
 end;
 Image1.Left := Left;
 Image1.Top := Top;
 Image1.Visible := True;
 Timer1.Enabled := true;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Image1.Top := Image1.Top - 1;
  Timer1.Tag := Timer1.Tag + 1;
  if Timer1.Tag>5 then
    begin
      Image1.Visible := False;
      Timer1.Tag := 0;
      Timer1.Enabled := False;
    end;
end;

end.
