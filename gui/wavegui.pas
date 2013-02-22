{
  Copyright (C) 2009 Robbert Latumahina

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation; either version 2.1 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

  waveformgui.pas
}

unit wavegui;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, LCLType, Graphics, globalconst, global, jacktypes,
  ComCtrls, pattern, global_command, wave, utils, ContNrs, Forms;

const
  DECIMATED_CACHE_DISTANCE = 64;
  GRAYSCALE_10 = TColor($000000);
  GRAYSCALE_20 = TColor($080808);
  GRAYSCALE_30 = TColor($111111);
  GRAYSCALE_40 = TColor($333333);
  GRAYSCALE_50 = TColor($555555);
  GRAYSCALE_60 = TColor($777777);
  GRAYSCALE_70 = TColor($999999);
  GRAYSCALE_80 = TColor($BBBBBB);
  GRAYSCALE_90 = TColor($DDDDDD);
  GRAYSCALE_100 = TColor($FFFFFF);
  REDSCALE_70 = TColor($0000BB);

type
  TMouseArea = (maNone, maSliceMarkers, maLoopMarkers, maSampleMarkers, maWave);

  { TSimpleWaveForm }

  TSimpleWaveForm = class(TCustomControl)
  private
    FData: PJack_default_audio_sample_t;
    FZoom: single;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure EraseBackground(DC: HDC); override;
    procedure Paint; override;
    property Data: PJack_default_audio_sample_t read FData write FData;
    property Zoom: single read FZoom write FZoom;
  protected
  published
  end;


  TWaveZoomCallback = procedure(ALeftPercentage, ARightPercentage: Single) of object;

  { TWaveOverview }

  TWaveOverview = class(TPersistentCustomControl)
  private
    FTotalWidth: Integer;
    FZoomBoxWidth: Integer;
    FZoomBoxLeft: Integer;
    FZoomBoxOldLeft: Integer;
    FZoomBoxRight: Integer;
    FOldX: Integer;
    FOldY: Integer;
    FMouseX: Integer;

    FZooming: Boolean;
    FZoomingLeft: Boolean;
    FZoomingRight: Boolean;

    FZoomCallback: TWaveZoomCallback;
    FModel: TWavePattern;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Update(Subject: THybridPersistentModel); override;
    procedure EraseBackground(DC: HDC); override;
    function GetModel: THybridPersistentModel; override;
    procedure SetModel(AModel: THybridPersistentModel); override;
    procedure Connect; override;
    procedure Disconnect; override;
    property ZoomCallback: TWaveZoomCallback write FZoomCallback;
    property Model: THybridPersistentModel read GetModel write SetModel;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y:Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y:Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  end;


  { TMarkerGUI }

  TMarkerGUI = class(THybridPersistentView)
  private
    FLocation: Integer;
    FOriginalLocation: Integer;
    FMarker: TMarker;
    FSelected: Boolean;
    FLocked: Boolean;
    FSliceType: Integer;
    FDecayRate: single;
    FNextSlice: TMarkerGUI;         // Points to next slice to the right or nil if last
    FPrevSlice: TMarkerGUI;         // Points to next slice to the right or nil if last
  public
    procedure Update(Subject: THybridPersistentModel); reintroduce; override;
    property Selected: Boolean read FSelected write FSelected;
    property Locked: Boolean read FLocked write FLocked;
    property Location: Integer read FLocation write FLocation;
    property OriginalLocation: Integer read FOriginalLocation write FOriginalLocation;
    property Marker: TMarker read FMarker write FMarker;
    property SliceType: Integer read FSliceType write FSliceType;
    property DecayRate: single read FDecayRate write FDecayRate;
    property NextSlice: TMarkerGUI read FNextSlice write FNextSlice;
    property PrevSlice: TMarkerGUI read FPrevSlice write FPrevSlice;
  end;

  { TWaveGUI }
  TWaveGUI = class(TPersistentCustomControl)
  private
    { GUI }
    FTransportBarHeight: Integer;
    FZoomFactorX: Single;
    FZoomFactorY: Single;
    FZoomFactorToScreen: Single;
    FZoomFactorToData: Single;
    FOriginalZoomFactorX: Single;
    FOffset: Integer;
    FOldOffset: Integer;
    FOldX: Integer;
    FOriginalOffsetX: Integer;
    FOriginalOffsetY: Integer;
    { Audio }
    FData: PJack_default_audio_sample_t;
    FDecimatedData: PJack_default_audio_sample_t;
    FSliceListGUI: TObjectList;
    FCurrentSliceIndex: Integer;
    FRealCursorPosition: Integer;
    FVirtualCursorPosition: Integer;
    FLoopStart: TLoopMarkerGUI;
    FLoopEnd: TLoopMarkerGUI;
    FLoopLength: TLoopMarkerGUI;
    FSampleStart: TSampleMarkerGUI;
    FSampleEnd: TSampleMarkerGUI;
    FBarLength: Integer;
    FDragSlice: Boolean;
    FZooming: Boolean;
    FSelectedSlice: TMarkerGUI;
    FSelectedLoopMarkerGUI: TLoopMarkerGUI;
    FSelectedSampleMarkerGUI: TSampleMarkerGUI;
    FRubberbandSelect: Boolean;
    FCursorAdder: Single;
    FCursorReal: Single;
    FCursorRamp: Single;
    FSampleRate: Single;
    FVolumeDecay: Single;
    FReadCount: Integer;
    FSampleFileName: string;
    FTransientThreshold: Integer;
    FModel: TWavePattern;
    FBitmap: TBitmap;
    FCacheIsDirty: Boolean;
    FOldCursorPosition: Integer;
    FPitch: Single;
    FRealBPM: Single;
    FPitched: Boolean;
    FMargin: single;
    FMouseArea: TMouseArea;
    FBpmFactor: Single;
    FBpmAdder: Single;
    FSampleStartLocation: Integer;
    FMouseX: Integer;
    FMaximumVisibleRange: Integer;

    procedure RecalculateWarp;
    procedure ReleaseMarker(Data: PtrInt);
    procedure SetOffset(AValue: Integer);
    procedure SetTransientThreshold(const AValue: Integer);
    procedure SetZoomFactorX(const AValue: Single);
    procedure SetZoomFactorY(const AValue: Single);
    procedure Setpitch(const Avalue: Single);
    procedure Sortslices;
    procedure UpdateSampleScale;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Update(Subject: THybridPersistentModel); reintroduce; override;
    procedure Connect; override;
    procedure Disconnect; override;
    procedure EraseBackground(DC: HDC); override;
    procedure Paint; override;
    procedure DragDrop(Source: TObject; X, Y: Integer); override;
    function SampleMarkerAt(Location: Integer; AMargin: Single): TSampleMarkerGUI;
    function LoopMarkerAt(Location: Integer; AMargin: Single): TLoopMarkerGUI;
    function NextSlice: TMarkerGUI;
    function GetSliceAt(Location: Integer; AMargin: Single): TMarkerGUI;

    function GetModel: THybridPersistentModel; override;
    procedure SetModel(AModel: THybridPersistentModel); override;

    property Data: PJack_default_audio_sample_t read FData write FData;
    property DecimatedData: PJack_default_audio_sample_t read FDecimatedData write FDecimatedData;
    property RealCursorPosition: Integer read FRealCursorPosition write FRealCursorPosition;
    property VirtualCursorPosition: Integer read FVirtualCursorPosition write FVirtualCursorPosition;
    property LoopStart: TLoopMarkerGUI read FLoopStart write FLoopStart;
    property LoopEnd: TLoopMarkerGUI read FLoopEnd write FLoopEnd;
    property LoopLength: TLoopMarkerGUI read FLoopLength write FLoopLength;
    property SampleStart: TSampleMarkerGUI read FSampleStart write FSampleStart;
    property SampleEnd: TSampleMarkerGUI read FSampleEnd write FSampleEnd;
    property SliceListGUI: TObjectList read FSliceListGUI write FSliceListGUI;
    property CursorReal: Single read FCursorReal write FCursorReal default 1.0;
    property CursorRamp: Single read FCursorRamp write FCursorRamp default 1.0;
    property SampleRate: Single read FSampleRate write FSampleRate;
    property VolumeDecay: Single read FVolumeDecay write FVolumeDecay default 1;
    property ReadCount: Integer read FReadCount write FReadCount;
    property SampleFileName: string read FSampleFileName write FSampleFileName;
    property TransientThreshold: Integer read FTransientThreshold write SetTransientThreshold;
    property BarLength: Integer read FBarLength write FBarLength;
    property Model: THybridPersistentModel read GetModel write SetModel;
    property CacheIsDirty: Boolean read FCacheIsDirty write FCacheIsDirty;
    property Pitch: Single read FPitch write SetPitch default 1;
    property Pitched: Boolean read FPitched write FPitched default False;
    property RealBPM: Single read FRealBPM write FRealBPM default 120;
  protected
    procedure DblClick; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y:Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y:Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure DragOver(Source: TObject; X, Y: Integer; State: TDragState;
                    var Accept: Boolean); override;
    procedure CreateMarkerGUI(AObjectID: string);
    procedure DeleteMarkerGUI(AObjectID: string);
  published
    property ZoomFactorX: Single read FZoomFactorX write SetZoomFactorX;
    property ZoomFactorY: Single read FZoomFactorY write SetZoomFactorY;
    property Offset: Integer read FOffset write SetOffset;
  end;

implementation

function compareByLocation(Item1 : Pointer; Item2 : Pointer) : Integer;
var
  location1, location2 : TMarkerGUI;
begin
  // We start by viewing the object pointers as TSlice objects
  location1 := TMarkerGUI(Item1);
  location2 := TMarkerGUI(Item2);

  // Now compare by location
  if location1.Location > location2.Location then
    Result := 1
  else if location1.Location = location2.Location then
    Result := 0
  else
    Result := -1;
end;

{ TWaveOverview }

constructor TWaveOverview.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FZoomBoxLeft := 0;
  FZoomBoxRight := Width;
  FZoomBoxWidth := Width;
end;

procedure TWaveOverview.Update(Subject: THybridPersistentModel);
begin
  Invalidate;
end;

procedure TWaveOverview.EraseBackground(DC: HDC);
begin
  inherited EraseBackground(DC);
end;

function TWaveOverview.GetModel: THybridPersistentModel;
begin
  Result := THybridPersistentModel(FModel);
end;

procedure TWaveOverview.SetModel(AModel: THybridPersistentModel);
begin
  FModel := TWavePattern(AModel);
end;

procedure TWaveOverview.Connect;
begin
  FModel := TWavePattern(GObjectMapper.GetModelObject(Self.ObjectID));
end;

procedure TWaveOverview.Disconnect;
begin
  inherited Disconnect;
end;

procedure TWaveOverview.Paint;
begin
  Canvas.Brush.Color := clLtGray;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(0, 0, Width, Height);

  Canvas.pen.Width := clBlack;
  Canvas.Pen.Width := 2;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(FZoomBoxLeft, 1, FZoomBoxRight, Height - 1);
end;

procedure TWaveOverview.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  FOldX := X;
  FOldY := Y;

  if Button = mbLeft then
  begin
    if (X > FZoomBoxLeft - 3) and (X < FZoomBoxLeft + 3) then
    begin
      FZoomingLeft := True;
    end
    else if (X > FZoomBoxRight - 3) and (X < FZoomBoxRight + 3) then
    begin
      FZoomingRight := True;
    end
    else
    begin
      FZooming := True;

      FZoomBoxOldLeft := FZoomBoxLeft;
    end;
  end;

  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TWaveOverview.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  FZooming := False;
  FZoomingLeft := False;
  FZoomingRight := False;

  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TWaveOverview.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  lTryLeftLocation: Integer;
  lTryRightLocation: Integer;
  lDelta: Integer;
begin
  if FZooming  then
  begin
    lDelta := X - FOldX;
    lTryLeftLocation := FZoomBoxOldLeft + lDelta;
    lTryRightLocation := FZoomBoxOldLeft + lDelta + FZoomBoxWidth;

    // Clamp to left side
    if lTryLeftLocation < 1 then
    begin
      FZoomBoxLeft := 1;
      FZoomBoxRight := FZoomBoxWidth;
    end
    // Clamp to right side
    else if lTryRightLocation >= Width then
    begin
      FZoomBoxLeft := Width - FZoomBoxWidth;
      FZoomBoxRight := Width;
    end
    // Freely move
    else
    begin
      FZoomBoxLeft := lTryLeftLocation;
      FZoomBoxRight := lTryRightLocation;
    end;
  end
  else if FZoomingLeft then
  begin
    FZoomBoxLeft := X;

    if FZoomBoxLeft >= (FZoomBoxRight - 5) then
      FZoomBoxLeft := FZoomBoxRight - 5;

    // Clamp to left side
    if FZoomBoxLeft < 1 then
      FZoomBoxLeft := 1;

    FZoomBoxWidth := FZoomBoxRight - FZoomBoxLeft;
  end
  else if FZoomingRight then
  begin
    FZoomBoxRight := X;

    if FZoomBoxRight <= (FZoomBoxLeft + 5) then
      FZoomBoxRight := FZoomBoxLeft + 5;

    // Clamp to right side
    if FZoomBoxRight > Width then
      FZoomBoxRight := Width;

    FZoomBoxWidth := FZoomBoxRight - FZoomBoxLeft;
  end;

  if FZooming or FZoomingLeft or FZoomingRight then
  begin
    if FZoomBoxRight > FZoomBoxLeft then
    begin
      if Assigned(FZoomCallback) then
      begin
        FZoomCallback((100 / Width) * FZoomBoxLeft, (100 / Width) * FZoomBoxRight);
      end;
    end;

    Invalidate;
  end;

  inherited MouseMove(Shift, X, Y);
end;

{ TSimpleWaveForm }

constructor Tsimplewaveform.Create(Aowner: Tcomponent);
begin
  inherited Create(Aowner);

  FZoom := 4;
end;

destructor Tsimplewaveform.Destroy;
begin
  inherited Destroy;
end;

procedure Tsimplewaveform.Erasebackground(Dc: Hdc);
begin
  //inherited Erasebackground(Dc);
end;

procedure Tsimplewaveform.Paint;
var
  bmp: TBitmap;
  screenloop: integer;
  zeroline: integer;
begin
  bmp := TBitmap.Create;
  try
    bmp.Height := Height;
    bmp.Width := Width;
    zeroline := Height div 2;

    bmp.Canvas.Pen.Color := clBlack;
    bmp.Canvas.Clipping := False;
    bmp.Canvas.Rectangle(0, 0, Width, Height);

    if FData <> nil then
    begin
      bmp.Canvas.Pen.Color := clBlack;
      bmp.Canvas.Line(0, zeroline, Width, zeroline);

      bmp.Canvas.Pen.Color := clBlue;
      bmp.Canvas.MoveTo(0, zeroline);

      for ScreenLoop := 0 to Pred(bmp.Width) do
        bmp.Canvas.LineTo(ScreenLoop, Round(FData[Round(ScreenLoop * FZoom)] * zeroline) + zeroline);
    end;
    Canvas.Draw(0, 0, bmp);
  finally
    bmp.Free;
  end;

  inherited Paint;
end;

procedure TWaveGUI.SetTransientThreshold(const AValue: Integer);
begin
  FTransientThreshold:= AValue;
//  BeatDetect.setThresHold(FTransientThreshold / 100);
//  AutoMarkerProcess(True);
end;

procedure TWaveGUI.SetZoomFactorX(const AValue: Single);
begin
  FZoomFactorX := AValue;
  if FZoomFactorX <= 1 then FZoomFactorX := 1;
  FZoomFactorToScreen:= (ZoomFactorX / 1000);
  FZoomFactorToData:= (1000 / ZoomFactorX);

  FCacheIsDirty := True;
end;

procedure TWaveGUI.SetZoomFactorY(const AValue: Single);
begin
  FCacheIsDirty := True;
end;

procedure TWaveGUI.Setpitch(const Avalue: Single);
begin
  if Avalue > 8 then
    FPitch := 8
  else if Avalue < 0.1 then
    FPitch := 0.1
  else
    FPitch := Avalue;
end;

constructor TWaveGUI.Create(Aowner: Tcomponent);
begin
  inherited Create(Aowner);

  Width := 1000;
  DoubleBuffered := True;

  // Loop markers
  FLoopStart := TLoopMarkerGUI.Create(ObjectID, ltStart);
  FLoopEnd := TLoopMarkerGUI.Create(ObjectID, ltEnd);
  FLoopLength := TLoopMarkerGUI.Create(ObjectID, ltLength);

  // Sample start & end -markers
  FSampleStart := TSampleMarkerGUI.Create(ObjectID, stStart);
  FSampleEnd := TSampleMarkerGUI.Create(ObjectID, stEnd);

  FMouseArea := maNone;

  // Initalize settings
  FTransportBarHeight:= 30;
  FOffset:= 0;
  FData:= nil;
  FDecimatedData:= nil;
  ZoomFactorX:= 2;
  ZoomFactorY:= 1;
  FDragSlice:= False;
  FZooming:= False;
  FRubberbandSelect:= False;
  FCursorAdder:= 0;
  FVolumeDecay:= 1;
  FCacheIsDirty := True;
  FRealBPM := 120;

  FSliceListGUI := TObjectList.Create(True);
  FCurrentSliceIndex:= 0;
end;

destructor TWaveGUI.Destroy;
begin
  FSliceListGUI.Free;

  FLoopStart.Free;
  FLoopEnd.Free;
  FLoopLength.Free;

  FSampleStart.Free;
  FSampleEnd.Free;

  inherited Destroy;
end;

procedure TWaveGUI.Update(Subject: THybridPersistentModel);
begin
  DBLog('start TWaveFormGUI.Update');

  DiffLists(
    TWavePattern(Subject).SliceList,
    SliceListGUI,
    @CreateMarkerGUI,
    @DeleteMarkerGUI);

  FLoopStart.Update(TWavePattern(Subject).LoopStart);
  FLoopEnd.Update(TWavePattern(Subject).LoopEnd);
  FLoopLength.Update(TWavePattern(Subject).LoopLength);

  FSampleStart.Update(TWavePattern(Subject).SampleStart);
  FSampleEnd.Update(TWavePattern(Subject).SampleEnd);

  FMaximumVisibleRange := TWavePattern(Subject).SampleEnd.Value + 10000;

  Sortslices;

  UpdateSampleScale;

  Invalidate;

  DBLog('end TWaveFormGUI.Update');
end;

procedure TWaveGUI.Connect;
begin
  DBLog('start TWaveFormGUI.Connect');

  FModel.LoopStart.Attach(FLoopStart);
  FModel.LoopEnd.Attach(FLoopEnd);
  FModel.LoopLength.Attach(FLoopLength);

  FModel.SampleStart.Attach(FSampleStart);
  FModel.SampleEnd.Attach(FSampleEnd);

  DBLog('end TWaveFormGUI.Connect');
end;

procedure TWaveGUI.Disconnect;
var
  lMarkerGUI: TMarkerGUI;
  lMarker: TMarker;
  lIndex: Integer;
begin
  for lIndex := Pred(FSliceListGUI.Count) downto 0 do
  begin
    lMarkerGUI := TMarkerGUI(FSliceListGUI[lIndex]);

    if Assigned(lMarkerGUI) then
    begin
      lMarker := TMarker(GObjectMapper.GetModelObject(lMarkerGUI.ObjectID));
      if Assigned(lMarker) then
      begin
        lMarker.Detach(lMarkerGUI);
        FSliceListGUI.Remove(lMarkerGUI);
      end;
    end;
  end;

  FModel.LoopStart.Detach(FLoopStart);
  FModel.LoopEnd.Detach(FLoopEnd);
  FModel.LoopLength.Detach(FLoopLength);

  FModel.SampleStart.Detach(FSampleStart);
  FModel.SampleEnd.Detach(FSampleEnd);
end;

procedure TWaveGUI.EraseBackground(DC: HDC);
begin
  // Uncomment this to enable default background erasing
//  inherited EraseBackground(DC);
end;

procedure TWaveGUI.Paint;
var
  ChannelLoop: Integer;
  ScreenLoop: Integer;
  SliceLoop: Integer;
  SliceLeft: Integer;
  SliceRight: Integer;
  PositionInData1: Single;
  PositionInData2: Single;
  ChannelScreenOffset: Integer;
  ChannelHeight: Integer;
  ChannelZeroLine: Integer;
  Adder: Single;
  AdderFactor: Single;
  DataValue: Single;
  MaxValue: Single;
  MinValue: Single;
  SubSampleLoop: Integer;
  TimeMarker: Integer;
  QuarterBeatMarkerSpacing: single;
  TimeMarkerLocation: Integer;
begin
  if not Assigned(FModel) then exit;

  FBitmap := TBitmap.Create;
  try
    FBitmap.Canvas.Clear;

    // Initializes the Bitmap Size
    FBitmap.Height := Height;
    FBitmap.Width := Width;

    // Draw loopmarker bar
    FBitmap.Canvas.Pen.Width := 1;
    FBitmap.Canvas.Pen.Color := GRAYSCALE_80;
    FBitmap.Canvas.Brush.Color := GRAYSCALE_90;
    FBitmap.Canvas.Rectangle(
      0,
      0,
      Width,
      FTransportBarHeight);

    // Draw samplemarker bar
    FBitmap.Canvas.Pen.Color := GRAYSCALE_60;
    FBitmap.Canvas.Line(
      0,
      9,
      Width,
      9);

    // Draw slicemarker bar
    FBitmap.Canvas.Pen.Color := GRAYSCALE_60;
    FBitmap.Canvas.Line(
      0,
      19,
      Width,
      19);

    // Draw sample start to end bar
    SliceLeft := Round(SampleStart.Location * FZoomFactorToScreen - FOffset);
    SliceRight := Round(SampleEnd.Location * FZoomFactorToScreen - FOffset);
    FBitmap.Canvas.Brush.Color := GRAYSCALE_60;
    FBitmap.Canvas.FillRect(
      SliceLeft,
      10,
      SliceRight,
      19);

    // Start of sample
    FBitmap.Canvas.Pen.Color := GRAYSCALE_70;
    FBitmap.Canvas.Brush.Color := GRAYSCALE_60;
    FBitmap.Canvas.Pen.Width:= 1;
    FBitmap.Canvas.Rectangle(
      SliceLeft - 5,
      10,
      SliceLeft + 5,
      19);

    // End of sample
    FBitmap.Canvas.Pen.Color := GRAYSCALE_70;
    FBitmap.Canvas.Brush.Color := GRAYSCALE_60;
    FBitmap.Canvas.Pen.Width:= 1;
    FBitmap.Canvas.Rectangle(
      SliceRight - 5,
      10,
      SliceRight + 5,
      19);

    // Full background
    FBitmap.Canvas.Brush.Color := GRAYSCALE_80;
    FBitmap.Canvas.FillRect(
      0,
      FTransportBarHeight,
      Width,
      Height);

    // Sample overlay background
    FBitmap.Canvas.Brush.Color := GRAYSCALE_90;
    FBitmap.Canvas.FillRect(
      SliceLeft,
      FTransportBarHeight,
      SliceRight,
      Height);

(*  DEBUG CODE

    case FModel.SliceState of
      ssAuto: FBitmap.Canvas.Brush.Color := clYellow;
      ssCustom: FBitmap.Canvas.Brush.Color := clLtGray;
    end;
    FBitmap.Canvas.FillRect(
      Round(FModel.SliceStartLocation * FModel.SampleScaleInverse * FZoomFactorToScreen - FOffset),
      FTransportBarHeight,
      Round(FModel.SliceEndLocation * FModel.SampleScaleInverse * FZoomFactorToScreen - FOffset),
      Height);
*)

    // Draw measurements
    FBitmap.Canvas.Pen.Width := 1;

    // 120 BPM => 2 beats/sec => 1/4th beat = 0.125 (1 / 8)
    QuarterBeatMarkerSpacing :=
      FZoomFactorToScreen * Round(GSettings.SampleRate * 0.125);

    // Draw marker white every 4 markers ( = 1 beat )
    for TimeMarker := 0 to Round(Width / QuarterBeatMarkerSpacing) do
    begin
      if TimeMarker and 3 = 0 then
      begin
        FBitmap.Canvas.Pen.Color := GRAYSCALE_70;
      {end
      else
      begin
        FBitmap.Canvas.Pen.Color := GRAYSCALE_90;
      end;}
      TimeMarkerLocation := Round((TimeMarker * QuarterBeatMarkerSpacing) - FOffset);
      FBitmap.Canvas.Line(TimeMarkerLocation, FTransportBarHeight, TimeMarkerLocation, Height);

      //FBitmap.Canvas.TextOut(TimeMarkerLocation + 2, 75, Format('%d', [TimeMarkerLocation]));
      end;
    end;

    if (TChannel(FModel.Wave.ChannelList[0]).Buffer <> nil) and
      (FModel.Wave.Frames > 0) then
    begin
      ChannelHeight := (FBitmap.Height - FTransportBarHeight) div FModel.Wave.ChannelCount;
      for ChannelLoop := 0 to Pred(FModel.Wave.ChannelCount) do
      begin
        FBitmap.Canvas.Pen.Width := 1;
        FBitmap.Canvas.Pen.Color := clBlack;
        FBitmap.Canvas.Line(0, ChannelHeight * ChannelLoop + FTransportBarHeight, Width, ChannelHeight * ChannelLoop + FTransportBarHeight);

        // First point
        ChannelScreenOffset := ChannelLoop * ChannelHeight + ChannelHeight shr 1 + FTransportBarHeight;
        ChannelZeroLine := ChannelHeight div 2;
        FBitmap.Canvas.Pen.Color := RGBToColor(35, 40, 52);
        FBitmap.Canvas.Pen.Width := 1;
        FBitmap.Canvas.Line(0, ChannelZeroLine + ChannelScreenOffset, Width, ChannelZeroLine + ChannelScreenOffset);
        FBitmap.Canvas.MoveTo(Round(FSampleStartLocation * FZoomFactorToScreen) - FOffset, ChannelScreenOffset);

        for SliceLoop := 0 to SliceListGUI.Count - 2 do
        begin
          AdderFactor := TMarkerGUI(SliceListGUI[SliceLoop]).DecayRate;

          SliceLeft :=
            Round(TMarkerGUI(SliceListGUI[SliceLoop]).Location *
            FBpmFactor * FZoomFactorToScreen - FOffset);

          SliceRight :=
            Round(TMarkerGUI(SliceListGUI[SliceLoop + 1]).Location *
            FBpmFactor * FZoomFactorToScreen - FOffset);

          Adder :=
            TMarkerGUI(SliceListGUI[SliceLoop]).OriginalLocation *
            FBpmFactor * FZoomFactorToScreen - FOffset;

          // Only render data within view
          if (SliceRight > 0) and (SliceLeft < Width) then
          begin
            for ScreenLoop := SliceLeft to Pred(SliceRight) do
            begin
              PositionInData1 :=
                (FOffset + Adder) * FBpmAdder * FZoomFactorToData;
              PositionInData2 :=
                (FOffset + Adder + AdderFactor) * FBpmAdder * FZoomFactorToData;

              // Initialize to opposite maxima
              MinValue := 1;
              MaxValue := -1;

              if (ScreenLoop >= 0) and (ScreenLoop < Width) then
              begin
                if FZoomFactorToData > 50 then
                begin
                  // Subsampling sample values when zoomed in
                  DataValue := FModel.DecimatedData[
                    Round(PositionInData1 *
                    FModel.Wave.ChannelCount + ChannelLoop) div
                    DECIMATED_CACHE_DISTANCE];

                  // Seek maxima
                  for SubSampleLoop := Round(PositionInData1) to Round(PositionInData2) - 1 do
                  begin
                    DataValue := FModel.DecimatedData[
                        (SubSampleLoop * FModel.Wave.ChannelCount + ChannelLoop) div
                        DECIMATED_CACHE_DISTANCE];

                    if DataValue < MinValue then MinValue := DataValue;
                    if DataValue > MaxValue then MaxValue := DataValue;
                  end;

                  // Make sure the value is limited to the screen range
                  if MaxValue > 1 then MaxValue := 1;
                  if MinValue < -1 then MinValue := -1;

                  FBitmap.Canvas.Line(
                    FSampleStartLocation + ScreenLoop,
                    Round(MinValue * ChannelZeroLine) + ChannelScreenOffset,
                    FSampleStartLocation + ScreenLoop,
                    Round(MaxValue * ChannelZeroLine) + ChannelScreenOffset);
                end
                else
                begin
                  // Pixelview
                  DataValue := FModel.DecimatedData[
                    (Round(PositionInData1) * FModel.Wave.ChannelCount + ChannelLoop) div
                    DECIMATED_CACHE_DISTANCE];

                  if PositionInData1 < FModel.Wave.ReadCount then
                  begin
                    // Make sure the value is limited to the screen range
                    if DataValue > 1 then DataValue := 1;
                    if DataValue < -1 then DataValue := -1;

                    FBitmap.Canvas.LineTo(
                      FSampleStartLocation + ScreenLoop,
                      Round(DataValue * ChannelZeroLine) + ChannelScreenOffset);
                  end;
                end;
              end;
              Adder := Adder + AdderFactor;
            end;
          end;
        end;

        FBitmap.Canvas.Pen.Color := clLime;
        FBitmap.Canvas.MoveTo(0, ChannelScreenOffset);

        for SliceLoop := 0 to Pred(SliceListGUI.Count) do
        begin
          SliceLeft := Round(
            FSampleStartLocation +
            TMarkerGUI(SliceListGUI[SliceLoop]).Location *
            FBpmFactor * FZoomFactorToScreen - FOffset);

          // SliceMarker
          case TMarkerGUI(SliceListGUI[SliceLoop]).SliceType of
          SLICE_UNDELETABLE: Canvas.Pen.Color := clYellow;
          SLICE_NORMAL: Canvas.Pen.Color := clRed;
          SLICE_VIRTUAL: Canvas.Pen.Color := clGray;
          end;

          if TMarkerGUI(SliceListGUI[SliceLoop]).Selected then
            FBitmap.Canvas.Pen.Color := clGreen;

          FBitmap.Canvas.Pen.Width := 1;
          FBitmap.Canvas.Pen.Color := clBlack;
          FBitmap.Canvas.Line(
            SliceLeft,
            Succ(FTransportBarHeight),
            SliceLeft,
            Height);

          if TMarkerGUI(SliceListGUI[SliceLoop]).Locked then
          begin
            FBitmap.Canvas.Brush.Color := clYellow;
            FBitmap.Canvas.Rectangle(SliceLeft - 5, 20, SliceLeft + 5, 30);
          end
          else
          begin
            FBitmap.Canvas.Brush.Color := GRAYSCALE_80;
            FBitmap.Canvas.Rectangle(SliceLeft - 5, 20, SliceLeft + 5, 30);
          end;

          //FBitmap.Canvas.TextOut(SliceLeft + 2, 60, Format('%d', [TMarkerGUI(SliceListGUI[SliceLoop]).Location]));
          //FBitmap.Canvas.TextOut(SliceLeft + 5, 60, Format('%f', [TMarkerGUI(SliceListGUI[SliceLoop]).DecayRate]));
          //FBitmap.Canvas.TextOut(SliceLeft + 5, 70, Format('%f', [1 /TMarkerGUI(SliceListGUI[SliceLoop]).DecayRate]));
        end;

        SliceLeft := Round(LoopStart.Location * FZoomFactorToScreen - FOffset);
        FBitmap.Canvas.Pen.Color := clRed;
        FBitmap.Canvas.Brush.Color := REDSCALE_70;
        FBitmap.Canvas.Pen.Width := 3;
        FBitmap.Canvas.Line(
          SliceLeft,
          Succ(FTransportBarHeight),
          SliceLeft,
          Height);
        FBitmap.Canvas.Pen.Width := 1;
        FBitmap.Canvas.Rectangle(SliceLeft - 5, 1, SliceLeft + 5, 9);
        FBitmap.Canvas.TextOut(SliceLeft + 10, 50, Format('LoopStart %d', [LoopStart.Location]));

        SliceLeft := Round(LoopEnd.Location * FZoomFactorToScreen - FOffset);
        FBitmap.Canvas.Pen.Color := clRed;
        FBitmap.Canvas.Brush.Color := REDSCALE_70;
        FBitmap.Canvas.Pen.Width := 3;
        FBitmap.Canvas.Line(
          SliceLeft,
          Succ(FTransportBarHeight),
          SliceLeft,
          Height);
        FBitmap.Canvas.Pen.Width := 1;
        FBitmap.Canvas.Rectangle(SliceLeft - 5, 1, SliceLeft + 5, 9);
        FBitmap.Canvas.TextOut(SliceLeft + 10, 50, Format('LoopEnd %d', [LoopEnd.Location]));

        FCacheIsDirty := False;
      end;
    end;

    Canvas.Draw(0, 0, FBitmap);
  finally
    FBitmap.Free;
  end;

  // Draw cursor
  SliceLeft := Round(FModel.RealCursorPosition * FZoomFactorToScreen - FOffset);
  if FOldCursorPosition <> SliceLeft then
  begin
    Canvas.Pen.Color := clRed;
    Canvas.Line(SliceLeft, Succ(FTransportBarHeight), SliceLeft, Height);
    //Canvas.TextOut(SliceLeft + 10, 50, Format('BPMScale %f', [FModel.BPMscale]));

    FOldCursorPosition := SliceLeft;
  end;

(*   Debug code

  SliceLeft := Round(FModel.CursorAdder * FModel.SampleScaleInverse * FZoomFactorToScreen - FOffset);
  if FOldCursorPosition <> SliceLeft then
  begin
    Canvas.Pen.Color := clBlue;
    Canvas.Line(SliceLeft, Succ(FTransportBarHeight), SliceLeft, Height);

    FOldCursorPosition := SliceLeft;
  end;

  Canvas.Pen.Width := 2;
  SliceLeft := Round(FModel.SliceStartLocation * FModel.SampleScaleInverse * FZoomFactorToScreen - FOffset);
  if FOldCursorPosition <> SliceLeft then
  begin
    Canvas.Pen.Color := clGreen;
    Canvas.Line(SliceLeft, Succ(FTransportBarHeight), SliceLeft, Height);

    FOldCursorPosition := SliceLeft;
  end;

  SliceLeft := Round(FModel.SliceEndLocation * FModel.SampleScaleInverse * FZoomFactorToScreen - FOffset);
  if FOldCursorPosition <> SliceLeft then
  begin
    Canvas.Pen.Color := clGreen;
    Canvas.Line(SliceLeft, Succ(FTransportBarHeight), SliceLeft, Height);

    FOldCursorPosition := SliceLeft;
  end;
  Canvas.Pen.Width := 1;   *)

  inherited Paint;
end;

procedure TWaveGUI.UpdateSampleScale;
begin
  // Original to Scaled BPM rate factor
  FBpmFactor := (SampleEnd.Location - SampleStart.Location) / FModel.Wave.Frames;
  FBpmAdder := 1 / FBpmFactor;
  FSampleStartLocation := Round(SampleStart.Location * FZoomFactorToScreen);
end;

procedure TWaveGUI.DblClick;
var
  lDetectSliceMarker: TMarkerGUI;
  lRemoveMarkerCommand: TRemoveMarkerCommand;
  lAddMarkerCommand: TAddMarkerCommand;
  lXRelative: Integer;
begin
  lXRelative := Round((FOffset + FMouseX) * FZoomFactorToData * FBpmAdder) - Round(SampleStart.Location * FBpmAdder);

  lDetectSliceMarker := GetSliceAt(lXRelative, 5 * FZoomFactorToData);
  if Assigned(lDetectSliceMarker) then
  begin
    lRemoveMarkerCommand := TRemoveMarkerCommand.Create(Self.ObjectID);
    try
      lRemoveMarkerCommand.ObjectID := lDetectSliceMarker.ObjectID;
      lRemoveMarkerCommand.Persist := True;

      GCommandQueue.PushCommand(lRemoveMarkerCommand);
    except
      lRemoveMarkerCommand.Free;
    end;
  end
  else
  begin
    lAddMarkerCommand := TAddMarkerCommand.Create(Self.ObjectID);
    try
      lAddMarkerCommand.Location := lXRelative;
      lAddMarkerCommand.Persist := True;

      GCommandQueue.PushCommand(lAddMarkerCommand);
    except
      lAddMarkerCommand.Free;
    end;
  end;

  FCacheIsDirty := True;
  Invalidate;

  inherited DblClick;
end;

procedure TWaveGUI.Mousedown(Button: Tmousebutton; Shift: Tshiftstate; X,
  Y: Integer);
var
  lXRelative: Integer;
  lMousePosition: Integer;
  lMoveMarkerCommand: TUpdateMarkerCommand;
  lToggleLockCommand: TToggleLockMarkerCommand;
  lUpdateWaveLoopMarkerCommand: TUpdateWaveLoopMarkerCommand;
  lUpdateWaveSampleMarkerCommand: TUpdateWaveSampleMarkerCommand;
begin
  FMouseX := X;

  FMargin := 5 * FZoomFactorToData;

  lXRelative := Round((FOffset + X) * FZoomFactorToData);

  // Where are we in this control?
  lMousePosition := Y{ - Top};
  if (lMousePosition >= 0) and (lMousePosition < 10) then
  begin
    FMouseArea := maLoopMarkers;
  end
  else if (lMousePosition >= 10) and (lMousePosition < 20) then
  begin
    FMouseArea := maSampleMarkers;
  end
  else if (lMousePosition >= 20) and (lMousePosition < 30) then
  begin
    FMouseArea := maSliceMarkers;
  end
  else
  begin
    FMouseArea := maWave;
  end;

  case FMouseArea of
    maSliceMarkers:
    begin
      FSelectedSlice :=
        GetSliceAt(
          Round(lXRelative * FBpmAdder) -
          Round(SampleStart.Location * FBpmAdder),
        FMargin);

      if Assigned(FSelectedSlice) then
      begin
        case Button of
          mbLeft:
          begin
            if FSelectedSlice.Locked then
            begin
              FDragSlice := True;

              lMoveMarkerCommand := TUpdateMarkerCommand.Create(Self.ObjectID);
              try
                lMoveMarkerCommand.ObjectID := FSelectedSlice.ObjectID;
                lMoveMarkerCommand.Location := FSelectedSlice.Location;
                lMoveMarkerCommand.Persist := True;

                GCommandQueue.PushCommand(lMoveMarkerCommand);
              except
                lMoveMarkerCommand.Free;
              end;
            end;
          end;
          mbRight:
          begin
            lToggleLockCommand := TToggleLockMarkerCommand.Create(Self.ObjectID);
            try
              lToggleLockCommand.ObjectID := FSelectedSlice.ObjectID;

              GCommandQueue.PushCommand(lToggleLockCommand);
            except
              lToggleLockCommand.Free;
            end;
          end;
        end;
      end;
    end;
    maLoopMarkers:
    begin
      FSelectedLoopMarkerGUI := LoopMarkerAt(lXRelative, FMargin);

      if Assigned(FSelectedLoopMarkerGUI) then
      begin
        lUpdateWaveLoopMarkerCommand := TUpdateWaveLoopMarkerCommand.Create(Self.ObjectID);
        try
          lUpdateWaveLoopMarkerCommand.ObjectID := FSelectedLoopMarkerGUI.ObjectID;
          lUpdateWaveLoopMarkerCommand.DataType := FSelectedLoopMarkerGUI.DataType;
          lUpdateWaveLoopMarkerCommand.Persist := True;
          lUpdateWaveLoopMarkerCommand.Location := lXRelative;

          GCommandQueue.PushCommand(lUpdateWaveLoopMarkerCommand);
        except
          lUpdateWaveLoopMarkerCommand.Free;
        end;
      end;
    end;
    maSampleMarkers:
    begin
      FSelectedSampleMarkerGUI := SampleMarkerAt(lXRelative, FMargin);

      if Assigned(FSelectedSampleMarkerGUI) then
      begin
        lUpdateWaveSampleMarkerCommand := TUpdateWaveSampleMarkerCommand.Create(Self.ObjectID);
        try
          lUpdateWaveSampleMarkerCommand.ObjectID := FSelectedSampleMarkerGUI.ObjectID;
          lUpdateWaveSampleMarkerCommand.DataType := FSelectedSampleMarkerGUI.DataType;
          lUpdateWaveSampleMarkerCommand.Persist := True;
          lUpdateWaveSampleMarkerCommand.Location := lXRelative;

          GCommandQueue.PushCommand(lUpdateWaveSampleMarkerCommand);
        except
          lUpdateWaveSampleMarkerCommand.Free;
        end;
      end;
    end;
    maWave:
    begin
      if Button = mbLeft then
      begin
        FOriginalZoomFactorX := FZoomFactorX;
        FOriginalOffsetX := X;
        FOriginalOffsetY := Y;
        FOldOffset:= FOffset;
        FOldX:= X;
        FZooming := True;
      end;
    end;
  end;

  FCacheIsDirty := True;
  Invalidate;

  inherited Mousedown(Button, Shift, X, Y);
end;

procedure TWaveGUI.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  lXRelative: Integer;
  lMoveMarkerCommand: TUpdateMarkerCommand;
  lUpdateWaveLoopMarkerCommand: TUpdateWaveLoopMarkerCommand;
  lUpdateWaveSampleMarkerCommand: TUpdateWaveSampleMarkerCommand;
begin
  FMouseX := X;

  lXRelative := Round((FOffset + X) * FZoomFactorToData);

  if Assigned(FSelectedLoopMarkerGUI) then
  begin
    lUpdateWaveLoopMarkerCommand := TUpdateWaveLoopMarkerCommand.Create(Self.ObjectID);
    try
      lUpdateWaveLoopMarkerCommand.DataType := FSelectedLoopMarkerGUI.DataType;
      lUpdateWaveLoopMarkerCommand.Persist := False;
      lUpdateWaveLoopMarkerCommand.Location := lXRelative;

      GCommandQueue.PushCommand(lUpdateWaveLoopMarkerCommand);
    except
      lUpdateWaveLoopMarkerCommand.Free;
    end;

    FSelectedLoopMarkerGUI := nil;
  end
  else if Assigned(FSelectedSampleMarkerGUI) then
  begin
    lUpdateWaveSampleMarkerCommand := TUpdateWaveSampleMarkerCommand.Create(Self.ObjectID);
    try
      lUpdateWaveSampleMarkerCommand.DataType := FSelectedSampleMarkerGUI.DataType;
      lUpdateWaveSampleMarkerCommand.Persist := False;
      lUpdateWaveSampleMarkerCommand.Location := lXRelative;

      GCommandQueue.PushCommand(lUpdateWaveSampleMarkerCommand);
    except
      lUpdateWaveSampleMarkerCommand.Free;
    end;

    UpdateSampleScale;

    FSelectedSampleMarkerGUI := nil;
  end
  else if FDragSlice then
  begin
    // Update model with last slice location before end drag slice
    // do not persist as this is done BEFORE a change
    lMoveMarkerCommand := TUpdateMarkerCommand.Create(Self.ObjectID);
    try
      lMoveMarkerCommand.ObjectID := FSelectedSlice.ObjectID;
      lMoveMarkerCommand.Location := Round(lXRelative * FBpmAdder) - Round(SampleStart.Location * FBpmAdder);
      lMoveMarkerCommand.Persist := False;

      GCommandQueue.PushCommand(lMoveMarkerCommand);
    except
      lMoveMarkerCommand.Free;
    end;

    FDragSlice:= False;
  end;

  if FZooming then
    FZooming:= False;

  FMouseArea := maNone;

  FCacheIsDirty := True;
  Invalidate;

  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TWaveGUI.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  lXRelative: Integer;
  lXLocationInSample: Integer;
begin
  FMouseX := X;

  lXRelative := Round((FOffset + X) * FZoomFactorToData);

  if Assigned(FSelectedLoopMarkerGUI) then
  begin
    FSelectedLoopMarkerGUI.Location := lXRelative;
  end
  else if Assigned(FSelectedSampleMarkerGUI) then
  begin
    UpdateSampleScale;
    FSelectedSampleMarkerGUI.Location := lXRelative;
  end
  else if FDragSlice then
  begin
    if Assigned(FSelectedSlice) then
    begin
      if FSelectedSlice.Locked then
      begin
        lXLocationInSample :=
          Round(lXRelative * FBpmAdder) -
          Round(SampleStart.Location * FBpmAdder);

        if (lXLocationInSample > FSelectedSlice.PrevSlice.Location) and
           (lXLocationInSample < FSelectedSlice.NextSlice.Location) then
        begin
          FSelectedSlice.Location := lXLocationInSample;

          Sortslices;
        end;
      end;
    end;
  end
  else if FZooming then
  begin
    FZoomFactorX := FOriginalZoomFactorX + ((FOriginalOffsetY - Y) / 5);
    if FZoomFactorX < 0.3 then FZoomFactorX := 0.3;
    FOffset := FOldOffset - (X - FOldX);

  end;

  FCacheIsDirty := True;
  Invalidate;

  inherited MouseMove(Shift, X, Y);
end;

procedure TWaveGUI.DragDrop(Source: TObject; X, Y: Integer);
var
  lTreeView: TTreeView;
  lDropWave: TPatternDropWaveCommand;
begin
  inherited DragDrop(Source, X, Y);

  if Source is TTreeView then
  begin
    lTreeView := TTreeView(Source);
    {
      If Source is wav file then create pattern
      else if Source is pattern then move pattern (or copy with Ctrl held)
    }
    lDropWave := TPatternDropWaveCommand.Create(Self.ObjectID);
    try
      lDropWave.FileName := lTreeView.Selected.Text;

      GCommandQueue.PushCommand(lDropWave);
    except
      lDropWave.Free;
    end;
  end;
end;

function TWaveGUI.SampleMarkerAt(Location: Integer; AMargin: Single
  ): TSampleMarkerGUI;
begin
  SampleStart.Location := FModel.SampleStart.Value;
  SampleEnd.Location := FModel.SampleEnd.Value;

  Result := nil;

  if Abs(Location - SampleStart.Location) < AMargin then
  begin
    Result := SampleStart;
  end
  else
  if Abs(Location - SampleEnd.Location) < AMargin then
  begin
    Result := SampleEnd;
  end;
end;

procedure TWaveGUI.DragOver(Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  inherited DragOver(Source, X, Y, State, Accept);

  Accept := True;
end;


function TWaveGUI.NextSlice: TMarkerGUI;
var
  lMarker: TMarkerGUI;
begin
  Result := nil;

  if FCurrentSliceIndex < SliceListGUI.Count then
    lMarker := TMarkerGUI(SliceListGUI[FCurrentSliceIndex])
  else
    lMarker := TMarkerGUI(SliceListGUI.Last);

  if Assigned(lMarker) then
    Result := lMarker.NextSlice
  else
    Result := nil;
end;

procedure TWaveGUI.Sortslices;
var
  i: Integer;
begin
  if FSliceListGUI.Count = 0 then
    exit;

  // Link all sorted
  FSliceListGUI.Sort(@compareByLocation);
  for i := 0 to FSliceListGUI.Count - 2 do
  begin
    if i = 0 then
    begin
      TMarkerGUI(FSliceListGUI[i]).PrevSlice:= nil;
    end;
    if (i + 1) <= FSliceListGUI.Count then
    begin
      TMarkerGUI(FSliceListGUI[i]).NextSlice:= TMarkerGUI(FSliceListGUI[i + 1]);
      TMarkerGUI(FSliceListGUI[i + 1]).PrevSlice:= TMarkerGUI(FSliceListGUI[i]);
    end
    else
      TMarkerGUI(FSliceListGUI[i]).NextSlice:= nil;
  end;

  RecalculateWarp;
end;

procedure TWaveGUI.RecalculateWarp;
var
  i: Integer;
begin
  for i := 0 to FSliceListGUI.Count - 2 do
  begin
    TMarkerGUI(FSliceListGUI[i]).DecayRate :=
      (TMarkerGUI(FSliceListGUI[i + 1]).OriginalLocation - TMarkerGUI(FSliceListGUI[i]).OriginalLocation) /
      (TMarkerGUI(FSliceListGUI[i + 1]).Location - TMarkerGUI(FSliceListGUI[i]).Location);
  end;

  // Just initialize the last marker as it's not valid otherwise
  TMarkerGUI(FSliceListGUI[FSliceListGUI.Count - 1]).DecayRate := 1;

  CacheIsDirty := True;
end;

function TWaveGUI.GetSliceAt(Location: Integer; AMargin: Single): TMarkerGUI;
var
  i: Integer;
  lSlice: TMarkerGUI;
begin
  Result := nil;

  for i := 0 to Pred(SliceListGUI.Count) do
  begin
    lSlice := TMarkerGUI(SliceListGUI[i]);

    if Abs(Location - lSlice.Location) < AMargin then
    begin
      if lSlice.SliceType <> SLICE_UNDELETABLE then
      begin
        Result:= lSlice;
        FCurrentSliceIndex:= i;
        break;
      end;
    end;
  end;
end;

function TWaveGUI.GetModel: THybridPersistentModel;
begin
  Result := THybridPersistentModel(FModel);
end;

procedure TWaveGUI.SetModel(AModel: THybridPersistentModel);
begin
  FModel := TWavePattern(AModel);
end;

function TWaveGUI.LoopMarkerAt(Location: Integer; AMargin: Single): TLoopMarkerGUI;
begin
  LoopStart.Location := FModel.LoopStart.Value;
  LoopEnd.Location := FModel.LoopEnd.Value;
  LoopLength.Location := FModel.LoopLength.Value;

  Result := nil;

  if Abs(Location - LoopStart.Location) < AMargin then
  begin
    Result := LoopStart;
  end
  else
  if Abs(Location - LoopEnd.Location) < AMargin then
  begin
    Result := LoopEnd;
  end
  else
  if Abs(Location - LoopLength.Location) < AMargin then
  begin
    Result := LoopLength;
  end;
end;

procedure TWaveGUI.CreateMarkerGUI(AObjectID: string);
var
  lMarker: TMarker;
  lMarkerGUI: TMarkerGUI;
begin
  DBLog('start TWaveFormGUI.CreateMarkerGUI ' + AObjectID);

  lMarker := TMarker(GObjectMapper.GetModelObject(AObjectID));
  if Assigned(lMarker) then
  begin
    lMarkerGUI := TMarkerGUI.Create(Self.ObjectID);
    lMarkerGUI.ObjectID := lMarker.ObjectID;
    lMarkerGUI.ObjectOwnerID := lMarker.ObjectOwnerID;
    lMarkerGUI.Location := lMarker.Location;
    lMarkerGUI.OriginalLocation := lMarker.OrigLocation;
    lMarkerGUI.Selected := lMarker.Selected;
    lMarkerGUI.Locked := lMarker.Locked;
    lMarkerGUI.DecayRate := lMarker.DecayRate;
    lMarkerGUI.Marker := lMarker;

    FSliceListGUI.Add(lMarkerGUI);

    lMarker.Attach(lMarkerGUI);
  end;

  DBLog('end TWaveFormGUI.CreateMarkerGUI');
end;


procedure TWaveGUI.ReleaseMarker(Data: PtrInt);
var
  lMarkerGUI: TMarkerGUI;
begin
  lMarkerGUI := TMarkerGUI(Data);
  if Assigned(lMarkerGUI) then
  begin
    FSliceListGUI.Remove(lMarkerGUI);
  end;

  Invalidate;
end;

procedure TWaveGUI.SetOffset(AValue: Integer);
begin
  if FOffset = AValue then Exit;
  FOffset := AValue;

  Invalidate;
end;

procedure TWaveGUI.DeleteMarkerGUI(AObjectID: string);
var
  lMarkerGUI: TMarkerGUI;
  lIndex: Integer;
begin
  DBLog('start TWaveFormGUI.DeleteMarkerGUI : ' + AObjectID);

  for lIndex := Pred(FSliceListGUI.Count) downto 0 do
  begin
    lMarkerGUI := TMarkerGUI(FSliceListGUI[lIndex]);
    if Assigned(lMarkerGUI) then
    begin
      if lMarkerGUI.ObjectID = AObjectID then
      begin
        Application.QueueAsyncCall(@ReleaseMarker, PtrInt(lMarkerGUI));
      end;
    end;
  end;

  DBLog('end TWaveFormGUI.DeleteMarkerGUI');
end;

{ TMarkerGUI }

procedure TMarkerGUI.Update(Subject: THybridPersistentModel);
var
  lMarker: TMarker;
begin
  lMarker := TMarker(Subject);
  if Assigned(lMarker) then
  begin
    Self.Selected := lMarker.Selected;
    Self.Location := lMarker.Location;
    Self.OriginalLocation := lMarker.OrigLocation;
    Self.DecayRate := lMarker.DecayRate;
    Self.SliceType := lMarker.SliceType;
    Self.Locked := lMarker.Locked;
  end;
end;

initialization
  RegisterClass(TWaveGUI);

end.

