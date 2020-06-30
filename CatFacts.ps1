#To prank your coworkers, remove the comment on lines 3 and 15 and run this every 1/2 hour on someone's pc. In an 8 hour work day this will produce roughly 3 cat facts

#if ((Get-Random -Maximum 10000) -lt 1875) {

Add-Type -AssemblyName System.Speech
$SpeechSynth = New-Object System.Speech.Synthesis.SpeechSynthesizer

class fact {
    [string] $fact
    [int] $length
    [string] ToString() { return $this.fact }
}
$SpeechSynth.Speak("Did you know? $([fact](irm -useb https://catfact.ninja/fact))")

#}
