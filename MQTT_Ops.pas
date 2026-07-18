unit MQTT_Ops;

interface

uses
  OverbyteIcsMQTT;

type
  TMQTTOnlineProc = procedure(Sender: TIcsMQTTClient) of object;

const
  DEF_MQTT_HOST = 'localhost';
  DEF_MQTT_PORT = 1883;

procedure MQTTConnect(client : TIcsMQTTClient;
                      host : String;
                      port : Integer);

implementation

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure MQTTConnect(client : TIcsMQTTClient;
                      host : String;
                      port : Integer);
begin
  client.Host := host;
  client.Port := port;
  client.Activate(TRUE);
end; // MQTTConnect

end.
