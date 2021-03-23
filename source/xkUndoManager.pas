{ @abstract(This file is an extension to the KControls project.)
  @author(Martok)

  Copyright (c) 2021 Martok<BR><BR>

  <B>License:</B><BR>
  This code is licensed under BSD 3-Clause Clear License, see file License.txt or https://spdx.org/licenses/BSD-3-Clause-Clear.html.
}
unit xkUndoManager;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fgl, keditcommon, kmemo, xkMemoHelper;

type
  { TxkUndoManager }

  TxkUndoManager = class
  private type

    { TChangeSet }

    TChangeSet = class
      SelStart, SelLength: TKMemoSelectionIndex;
      ActiveBlock: TKMemoBlockAddress;
      rtf: TStringStream;
      destructor Destroy; override;
      function ToString: String; override;
    end;
    TChangeList = specialize TFPGList<TChangeSet>;
  private
    fMemo: TKMemo;
    fInternalChange: boolean;
    fChanges: TChangeList;
    fChangePointer: Integer;
    fMaxCount: integer;
  protected
    procedure DoInsertState(ContentChange, SelectionChange: boolean);
    procedure Capture(aState: TChangeSet);
    procedure Apply(aState: TChangeSet);
    procedure MemoBlockUpdate(Sender: TObject; AReasons: TKMemoUpdateReasons);
  public
    constructor Create(aMemo: TKMemo);
    destructor Destroy; override;
    procedure Reset(CaptureCurrent: boolean = True);
    procedure Undo;
    procedure Redo;
    function CanUndo: boolean;
    function CanRedo: boolean;
    property MaxCount: integer read fMaxCount write fMaxCount;
  end;

implementation

uses
  LCLProc, TypInfo;

{ TxkUndoManager.TChangeSet }

destructor TxkUndoManager.TChangeSet.Destroy;
begin
  FreeAndNil(rtf);
  inherited Destroy;
end;

function TxkUndoManager.TChangeSet.ToString: String;
begin
  Result:= '{Selection=%d:%d AB=%s}'.Format([SelStart,SelLength,String(ActiveBlock)]);
end;

{ TxkUndoManager }

constructor TxkUndoManager.Create(aMemo: TKMemo);
begin
  inherited Create;
  fMemo:= aMemo;
  fMemo.OnBlockUpdate:=@MemoBlockUpdate;
  fMemo.KeyMapping.Key[ecUndo]:= fMemo.KeyMapping.EmptyMap.Key;
  fMemo.KeyMapping.Key[ecRedo]:= fMemo.KeyMapping.EmptyMap.Key;
  fChanges:= TChangeList.Create;
  fChangePointer:= 0;
  fMaxCount:= 100;
  fInternalChange:= false;
end;

destructor TxkUndoManager.Destroy;
begin
  Reset(False);
  fChanges.Free;
  inherited Destroy;
end;

procedure TxkUndoManager.Reset(CaptureCurrent: boolean);
begin
  while fChanges.Count > 0 do begin
    fChanges[0].Free;
    fChanges.Delete(0);
  end;
  fChangePointer:= -1;
  if CaptureCurrent then
    DoInsertState(True, False);
end;

procedure TxkUndoManager.Capture(aState: TChangeSet);
begin
  aState.SelStart:= fMemo.SelStart;
  aState.SelLength:= fMemo.SelLength;
  aState.ActiveBlock:= fMemo.BlockToBlockAddress(fMemo.ActiveBlock);
  if Assigned(aState.rtf) then
    FreeAndNil(aState.rtf);
  aState.rtf:= TStringStream.Create;
  fMemo.AllSaveToRTFStream(aState.rtf);
end;

procedure TxkUndoManager.Apply(aState: TChangeSet);
var
  ctx: TKMemoBlock;
begin
  fInternalChange:= true;
  // BUG: LockUpdate  blocks important callbacks, Memo is not current to Blocks
  //fMemo.LockUpdate;
  try
    fMemo.Clear(False);
    aState.rtf.Position:= 0;
    fMemo.LoadFromRTFStream(aState.rtf, -1);
    if Length(aState.ActiveBlock) > 0 then begin
      ctx:= fMemo.BlockAddressToBlock(aState.ActiveBlock);
      if ctx is TKMemoContainer then
        fMemo.ActiveBlocks:= TKMemoContainer(ctx).Blocks
      else
        fMemo.ActiveBlocks:= ctx.ParentRootBlocks;
    end else
      fMemo.ActiveBlocks:= fMemo.Blocks;
    fMemo.Select(aState.SelStart, aState.SelLength);
  finally
    //fMemo.UnlockUpdate;
    fMemo.UpdateAll(True);
    fInternalChange:= false;
  end;
end;

procedure TxkUndoManager.DoInsertState(ContentChange, SelectionChange: boolean);
var
  state: TChangeSet;
  i: Integer;
begin
  fMemo.Blocks.LockUpdate;
  try
    // capture state
    state:= TChangeSet.Create;
    Capture(state);
    // *really* a content change compared to current pointer, if one exists?
    if ContentChange then
      if (fChanges.Count>=0) and (fChangePointer>=0) and (fChangePointer<fChanges.Count) then
        ContentChange:= (state.rtf.DataString <> fChanges[fChangePointer].rtf.DataString);
    if ContentChange then begin
      // if currently in the past, delete future
      for i:= fChangePointer - 1 downto 0 do begin
        fChanges[i].Free;
        fChanges.Delete(i);
      end;
      fChangePointer:= 0;
      fChanges.Insert(fChangePointer, state);
      DebugLn(['InsertState=ContentChange ', state.ToString]);
      // let stuff fall off the back
      while fChanges.Count > fMaxCount do begin
        fChanges[fMaxCount].Free;
        fChanges.Delete(fMaxCount);
      end;
    end else if SelectionChange then begin
      // no content change
      if (fChangePointer = 0) and (fChanges.Count>=0) then begin
        // update selection of present
        // qnd: replace with new state
        fChanges[fChangePointer].Free;
        fChanges[fChangePointer]:= state;
        DebugLn(['InsertState=Selection ', state.ToString]);
      end;
    end;
  finally
    fMemo.Blocks.UnlockUpdate;
  end;
end;

procedure TxkUndoManager.MemoBlockUpdate(Sender: TObject; AReasons: TKMemoUpdateReasons);
begin
  if fInternalChange then
    exit;
  //DebugLn(['BlockUpd=', SetToString(PTypeInfo(TypeInfo(AReasons)), @AReasons),
  //        ' Selection=', fMemo.SelStart, ':',fMemo.SelLength,
  //        ' SelContent=',fMemo.SelText]);
  DoInsertState([muContent, muExtent] * AReasons <> [], [muSelection, muSelectionScroll] * AReasons <> []);
end;

procedure TxkUndoManager.Undo;
begin
  if CanUndo then begin
    inc(fChangePointer);
    Apply(fChanges[fChangePointer]);
  end;
end;

procedure TxkUndoManager.Redo;
begin
  if CanRedo then begin
    dec(fChangePointer);
    Apply(fChanges[fChangePointer]);
  end;
end;

function TxkUndoManager.CanUndo: boolean;
begin
  Result:= fChangePointer < fChanges.Count - 1;
end;

function TxkUndoManager.CanRedo: boolean;
begin
  Result:= fChangePointer > 0;
end;


end.

