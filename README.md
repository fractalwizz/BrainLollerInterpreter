## BrainLollerInterpreter
Interpreter for the Brainloller language written in Perl<br>
V0.85

### Disclaimer
Fractalwizz is not the author of any of the example programs.<br>
They are only provided to test the interpreter's functionality

### Module Dependencies
Modern::Perl<br>
GD<br>
POSIX<br>
File::Basename

### Usage
perl bl.pl inputImage OR progfile<br>
  inputImage: path of Image
  progfile: path of bf program file
  
ie:<br>
perl bl.pl ./Examples/hello.png<br>
perl bl.pl catlong.png<br>
perl bl.pl interpreter.bf

### Features
BrainLoller Esoteric Programming Language<br>
Actually just A BrainLoller-to-Brainfck converter<br>
Processes image into a program String<br>
which gets passed into the Brainfck interpreter to execute<br>
New in V0.85: Translate Brainfck programs to Brainloller

### License
MIT License<br>
(c) 2016 Fractalwizz<br>
http://github.com/fractalwizz/BrainLollerInterpreter