## BrainLollerInterpreter
Interpreter for the Brainloller language written in Perl<br>
V0.8

### Disclaimer
Fractalwizz is not the author of any of the example programs.<br>
They are only provided to test the interpreter's functionality

### Module Dependencies
Modern::Perl<br>
GD<br>
File::Basename

### Usage
perl bl.pl inputImage<br>
  inputImage: path of Image
  
ie:<br>
perl bl.pl ./Examples/hello.png<br>
perl bl.pl catlong.png

### Features
BrainLoller Esoteric Programming Language<br>
Actually just A BrainLoller-to-Brainfck converter<br>
Processes image into a program String<br>
which gets passed into the Brainfck interpreter to execute

### TODO
Cmd parameter for debug information<br>
Cmd parameter for trace output for each step
Come up with more TODO items

### License
MIT License<br>
(c) 2016 Fractalwizz<br>
http://github.com/fractalwizz/BrainLollerInterpreter