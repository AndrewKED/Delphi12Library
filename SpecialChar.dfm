object fSpecialCharacters: TfSpecialCharacters
  Left = 429
  Top = 184
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Insert Special Character'
  ClientHeight = 283
  ClientWidth = 259
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object sgCharacters: TStringGrid
    Left = 0
    Top = 0
    Width = 259
    Height = 260
    Align = alClient
    ColCount = 16
    DefaultColWidth = 15
    DefaultRowHeight = 15
    FixedCols = 0
    RowCount = 16
    FixedRows = 0
    TabOrder = 0
    OnDblClick = sgCharactersDblClick
  end
  object Panel1: TPanel
    Left = 0
    Top = 260
    Width = 259
    Height = 23
    Align = alBottom
    Caption = 'Dbl-Click to Select             ESC to Abort'
    TabOrder = 1
  end
end
