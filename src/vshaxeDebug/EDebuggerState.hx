package vshaxeDebug;

import protocol.debug.Types.StackFrame;
import protocol.debug.Types.StopReason;
import adapter.DebugSession.InitializedEvent;
import adapter.DebugSession.StoppedEvent as StoppedEventImpl;

enum EDebuggerState {
	WaitingGreeting;
	Configuring;
	Running;
	Stopped(frames:Array<StackFrame>, currentFrame:Int);
}

enum EStateControlEvent {
	GreetingReceived;
	Continue;
	Stop(reason:StopReason);
	FrameUp;
	FrameDown;
	SetFrames(frames:Array<StackFrame>);
}

class StateController {
	public static function onEvent(context:Context, event:EStateControlEvent):EDebuggerState {
		var protocol = context.protocol;
		var currentState = context.debuggerState;

		return switch [currentState, event] {
			case [WaitingGreeting, GreetingReceived]:
				protocol.sendEvent(new InitializedEvent());
				Configuring;

			case [Configuring | Stopped(_, _), Continue]:
				Running;

			case [Running, Stop(reason)]:
				protocol.sendEvent(new StoppedEventImpl(reason, 1));
				Stopped([], 0);

			case [Stopped(frames, currentFrame), FrameUp] if (currentFrame < frames.length - 1):
				Stopped(frames, currentFrame + 1);

			case [Stopped(frames, currentFrame), FrameDown] if (currentFrame > 0):
				Stopped(frames, currentFrame - 1);

			case [Stopped(frames, currentFrame), SetFrames(newFrames)]:
				Stopped(newFrames, 0);

			default:
				throw 'no transition: state: $currentState, event: $event';
		}
	}
}
