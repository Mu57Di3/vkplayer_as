package  
{
	/**
	 * ...
	 * @author Mu57Di3
	 */
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.utils.Timer;
	import org.mu57di3.Streaming;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.display.StageAlign;
	
	
	public class app extends Sprite 
	{
		private var VideoLoader:Streaming;
		private var volumeTransform :SoundTransform;
		private var mainTimer:Timer;
		private var video:Video;
		private var uic:MovieClip;
		
		public function app() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.align = StageAlign.TOP_LEFT
			
			stage.addEventListener(Event.RESIZE, resizeHandler);
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, fullScreenhandler);
			
			volumeTransform = new SoundTransform();
			volumeTransform.volume = 0.1;
			
			//Основной таймер монитор воспроизведения
			mainTimer = new Timer(10);
			mainTimer.addEventListener( TimerEvent.TIMER, timerHandler);
			
			uic = new MovieClip();
			uic.width = stage.stageWidth;
			uic.height = stage.stageHeight;
			uic.x = 0;
			uic.y = 0;
			uic.scaleX = uic.scaleY = 1;
			VideoLoader = new Streaming();
			VideoLoader.video = new Video()
			VideoLoader.atachNetStream();
			VideoLoader.video.smoothing = true;
			
			uic.addChild(VideoLoader.video);
			stage.addChild(uic);
			VideoLoader.stage_height = stage.stageHeight;
			VideoLoader.stage_width = stage.stageWidth;
			VideoLoader.soundTransform = volumeTransform;
			VideoLoader.addEventListener(Streaming.ON_METADATA, onMetadatHendler);
			VideoLoader.addEventListener(Streaming.FILE_STOP, onStopHandler);
			//подрубаем функции внешнего интерфейса
			setCallbacks();
			
			//VideoLoader.play("http://cs12546v4.vk.me/u711703/videos/8cfe91d1f2.720.mp4?extra=Ll_qh1VMMdop6OelZ1DjJFHDKytceosNmtifflX5_Hao9p4oo4igxgUk08crU5Qd-VKQDoq9xTEulkquCNOKlyLMqZUiVtuZ");
			
		}
		
		private function onMetadatHendler(e:Event):void {
			log(VideoLoader.video.x);
			log(VideoLoader.video.y);
		}
		
		private function resizeHandler(e:Event):void {
			
			VideoLoader.stage_height = stage.stageHeight;
			VideoLoader.stage_width = stage.stageWidth;
			if(VideoLoader.isPlayed){
				VideoLoader.resize_video();
			}
			trace('resize');
		}
		
		private function onStopHandler(e:Event):void {
			mainTimer.stop();
			mainTimer.reset();
			if (ExternalInterface.available) {
				ExternalInterface.call('MDP_SWF_Adapter.stop');
			}
		}
		
		private function fullScreenhandler(e:FullScreenEvent):void {
			
		}
		
		//Основной таймер для всяких апдейтов прогресса проигрывания
		private function timerHandler(e:TimerEvent):void {
			if (stage.align != StageAlign.TOP_LEFT){
				stage.align = StageAlign.TOP_LEFT;	
			}
			
			if (ExternalInterface.available) {
				ExternalInterface.call('MDP_SWF_Adapter.update',[VideoLoader.time,VideoLoader.loadProgress]);
			}
		}
		
		
		
		protected function setCallbacks():void {
			if (ExternalInterface.available) {
				//Старт проигрывание вообще или нового файла
				ExternalInterface.addCallback('startPlay', function(file:String):void {
					VideoLoader.play(file);
					mainTimer.start();
				});
				
				//Плей/пауза
				ExternalInterface.addCallback('pp', function():void {
					VideoLoader.playTogle();;
				});
				
				//Регулировка громкости
				ExternalInterface.addCallback('volume', function(vol:Number):void {
					if (vol > 1 ) {
						vol = 1;
					} else if (vol < 0) {
						vol = 0;
					}
					volumeTransform.volume = vol;
					VideoLoader.soundTransform = volumeTransform;
				});
				
				ExternalInterface.addCallback('replay',function ():void {
					VideoLoader.replay();
					mainTimer.start();
					
				});
				
				
				
				
				
				//Перемотка время в секундах
				ExternalInterface.addCallback('seek', function(pos:Number):void {
					VideoLoader.seek(pos);
				});
								
				
			}
		}
		
		
				
		private function log(m:*):void {
			if (ExternalInterface.available) {
				ExternalInterface.call('console.log',m);
			}
		}
		
	}
	
	

}