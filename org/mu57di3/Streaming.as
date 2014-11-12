package org.mu57di3
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import mx.controls.Image;
	import mx.core.FlexGlobals;
	import mx.utils.OnDemandEventDispatcher;

	public class Streaming extends EventDispatcher
	{
		private var nc:NetConnection;
		private var ns:NetStream;
		public var video:Video;
		public var holder:Image;
		public var isPlayed:Boolean = false;
		
		//Данные о видео файле
		public var filepath:String = '';//Урл видео файла
		public var meta:Object; //Объект с метаданными
		public var times:Object; //Массив навигационных точек со значением времени
		public var positions:Object; //Массив навигационных точек со значением позиции в файла
		public var len:Number = 0; //Длинна видео в секундах
		public var bitrate:Number = 0; //Битрейт видео
		private var filesize:Number = 0; //Размер видео в байтах
		public var video_width:Number; //Ширина видео
		public var video_height:Number; //Высота видео
		public var type:String = 'striming';
		private var seektime:Number = 0;
		private var seekpos:Number = 0;
		public var have_metada:Boolean = false;
		public var stage_width:Number;
		public var stage_height:Number;
		
		//Константы кторые описывают события которые генерит класс
		public static const FILE_STOP:String = "FILE_STOP";
		//собыие на получение метаданных нужно чтоб смасштабировать картинку с видео под размер конетейнера
		public static const ON_METADATA:String = "ON_METADAT";
		//Данные пришли порарисовать прогрессбары
		public static const DATA_IS_COMING:String = "DATA_IS_COMING";
		
		//Счетчик прогресса загрузки первой порции данных для прогрессбара при старе воспроизведения
		public var firstLoad:Boolean = true;
		public var firstPercent:Number = 0;
		public static const FIRST_LOAD_PROGRESS:String = "FIRST_LOAD_PROGRESS";
		public static const FIRST_LOADED:String = "FIRST_LOADED";
		public static const FIRST_LOAD_START:String = "FIRST_LOAD_START";
		
		
		public function Streaming()
		{
			var nsClient:Object = {};
			nsClient.onMetaData = metaDataHandler;
			
			nc = new NetConnection();
			nc.connect(null);
			
			ns = new NetStream(nc);
			ns.client = nsClient;
			ns.bufferTimeMax = 5;
			ns.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandler);
			ns.addEventListener(IOErrorEvent.IO_ERROR,nsIOErrorHandler);

		}
		
		//Обработчик событий на изменение статуса обекта NetStream
		private function netStatusHandler(e:NetStatusEvent):void{
			try{
				switch (e.info.code){
					case "NetStream.Buffer.Empty":
						holder.visible = true;
						break;
					case "NetStream.Buffer.Full":
						holder.visible = false;
						dispatchEvent(new Event(FIRST_LOADED));
						break;
					case "NetStream.Play.Stop":
						//Генерим событие на конец рекламы
						isPlayed = false;
						seektime = 0;
						seekpos = 0;
						ns.pause();
						//have_metada = false;
						dispatchEvent(new Event(FILE_STOP));
						holder.visible = false;
						break;
				}
			} catch (e:TypeError){
				//debuger.debug("ns "+error);
			}
			
		}
		
		private function metaDataHandler(item:Object):void{
			if (!have_metada){
				trace('метданные');
				meta = item;
				ns.pause();
				isPlayed = true;
				resize_video();	
				for (var key:String in item){
					trace(key+': '+item[key]+' '+typeof item[key]);
					
				}
				times = new Object();
				positions = new Object();
				if (meta.keyframes){
					times = meta.keyframes.times;
					positions = meta.keyframes.filepositions;
				} else if (meta.seekpoints) {
					times = new Object();
					positions = new Object();
					var i:Number;
					for (i = 0; i < meta.seekpoints.length; i++) {
						times[i] = meta.seekpoints[i].time;
						positions[i] = meta.seekpoints[i].offset;
					}
				}
				filesize = ns.bytesTotal;
				trace(ns.bytesTotal);
				bitrate = ns.bytesTotal/1024/meta.duration;
				len = meta.duration;
				have_metada = true;
				dispatchEvent(new Event(ON_METADATA));
				ns.resume();
			}
		}
		
		// Обертка для старта загрузки
		public function play(file:String):void {
			filepath = file;
			ns.play(filepath);
			isPlayed = true;
		}
		
		public function playTogle():void{
			if (isPlayed){
				ns.togglePause();
			}	
		}
		
		public function replay():void {
			isPlayed = true;
			ns.seek(0);
			ns.resume();
		}
		
		public function atachNetStream():void{
			video.attachNetStream(ns);
		}
		
		public function stop():void{
			ns.pause();
			ns.seek(0);
			have_metada = false;
		}
		
		
		//Обработчик собаития на ошибки ввода вывода обьекта NetStream
		private function nsIOErrorHandler():void{
			
		}
		
		//Ресайз видео 
		public function resize_video():void{
			var ds:Number;
			ds = meta.width / meta.height;
			
			if (ds>1){
				video.width = stage_width;
				video.height = video.width/ds;
			}else if (ds<=1) {
				video.height = stage_height;
				video.width = ds*video.height;
			}
			
			if (video.height>=stage_height){
				video.height = stage_height;
				video.width = ds*video.height;
			}
			
			
			
			video.y = Math.round(stage_height/2)-Math.round(video.height/2);
			video.x = Math.round(stage_width/2)-Math.round(video.width/2);
			
			video_height = meta.height;
			video_width = meta.width;
		}
		
		//перемотка
		public function seek(value: int): void {

            for (var key: String in times) {
                if ((value >= times[key]) && (value < times[int(key) + 1])) {
                    //нашли cuePoint куда мотать
                    if (positions[key] > loadedBytes || positions[key] < seekpos) {
                        //грузим данные
                        seekpos = positions[key];
                        seektime = times[key];

                        if (filepath.indexOf("?") == -1)
                            ns.play(filepath + "?start=" + seektime);
                        else
                            ns.play(filepath + "&start=" + seektime);

                      
                        break;
                    }
                    else {
                        //мотаем по кэшу
                        ns.seek(value - seektime);
                       
                        break;
                    }
                }
            }
        }
		
		
		
		
		
		//---------------- Гетэры и Сеторы------------------------------------------------------------------------------------------
		
		public function set soundTransform (vol:SoundTransform):void{
			ns.soundTransform = vol;
		}
		
		public function get time():Number{
			return ns.time+seektime;
		}
		
		public function get loadProgress():Number{
			return Math.round(((ns.bytesLoaded+seekpos) / ns.bytesTotal) * 10000) / 100;
		}
		
		public function get loadedBytes():Number{
			return ns.bytesLoaded+seekpos;
		}
		
		public function set fsize (val:Number):void{
			filesize = val;
		}
		
		public function get size ():Number{
			return filesize
		}
	}
}