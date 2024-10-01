import * as a from "./armonia.js";

///////////// list of samples /////////////////////
const listaDeSonidosDelBajo = [{nombre: "bajoSintetico/"}, {nombre: "bajoAcustico/"}, {nombre: "bajoAspero/"}, {nombre: "bajoConDedos/"}, {nombre: "bajoFretless/"}, {nombre: "bajoPlumeado/"}, {nombre: "bajoSlap/"}]

const listaDeSonidosDelTeclado = [{nombre: "stereoGrPiano/"}, {nombre: "stereoPiano/"}, {nombre: "laPiano/"}, {nombre: "electricPiano/"}, {nombre: "stringsPiano/"}, {nombre: "dancePiano/"}, {nombre: "drawBarOrgan/"}, {nombre: "squareLead/"}, {nombre: "sawLead/"}]

const listaDeSonidosDelBombo = [{nombre: "bomboRoomSet/"}, {nombre: "bomboStandardSet4/"}]

const listaDeSonidosDelContratiempo = [{nombre: "contrasRoomSet/"}, {nombre: "contrasStandardSet4/"}]


// linear transformation para normalizar/mapear 0 a -60db y 1 a 0db
function normalizarVolumen(v){
  return ((60 * v) - 60)
}

// :: number
function establecerTempo(t){
  if (Tone.Transport.state !== "started") {
  Tone.Transport.bpm.value = t; // Set the tempo to 120 BPM
  Tone.Transport.start();
} else {
  Tone.Transport.bpm.value = t; 
 }
}


export function stopSequence(){
  Tone.Transport.stop();
}

// function bomboSamplerF(sonidoBombo, volumen, paneo) {
//   let bomboSampler = new Tone.Sampler({
//       urls: { C4: "C2.wav" },
//       release: 1,
//       baseUrl: "https://luisnavarrodelangel.github.io/sonidos-seis8s/" + sonidoBombo
//     });
//        // Create channel for the bass
//     let canalDelBombo = new Tone.Channel({
//       volume: normalizarVolumen(volumen),  // Volume in decibels
//       pan: (paneo * 2) - 1,  // Panning from -1 (left) to 1 (right)
//     }).toDestination();     

//     // Connect sampler to the channel
  
//    bomboSampler.connect(canalDelBombo);
// }

let seq1, seq2, seq3, seq4, seq5, canalDelBajo, canalDelTeclado2, canalDeContratiempos;

// Global bomboSampler and canalDelBombo, initialized only once
let bomboSampler = null;
let canalDelBombo = null;

function bomboSamplerF(sonidoBombo, volumen, paneo) {
  // Initialize the sampler if it's not already created
    bomboSampler = new Tone.Sampler({
      urls: { C4: "C2.wav" },
      release: 1,
      baseUrl: "https://luisnavarrodelangel.github.io/sonidos-seis8s/" + sonidoBombo
    });

    // Initialize the channel if not created yet
      canalDelBombo = new Tone.Channel({
        volume: normalizarVolumen(volumen), // Initial volume
        pan: (paneo * 2) - 1,  // Initial pan
      }).toDestination();
      
      bomboSampler.connect(canalDelBombo);  // Connect once
    

  // Update the sampler's sound if it has changed
  let newBaseUrl = "https://luisnavarrodelangel.github.io/sonidos-seis8s/" + sonidoBombo;
  if (bomboSampler.baseUrl !== newBaseUrl) {
    bomboSampler.releaseAll(); // Stop all currently playing notes
    bomboSampler.baseUrl = newBaseUrl;  // Update base URL to the new sound
  }

  // Update the volume and pan with smooth transitions
  canalDelBombo.volume.rampTo(normalizarVolumen(volumen), 0.5); // Smooth volume ramp
  canalDelBombo.pan.rampTo((paneo * 2) - 1, 0.5);  // Smooth pan ramp
}



let tecladoSampler = null;
let canalDelTeclado = null;

function tecladoSamplerF(sonidoTeclado, volumen, paneo) {


   tecladoSampler = new Tone.Sampler({
        urls: {
          C5: "C5.wav"
        },
        release: 1, baseUrl: "https://luisnavarrodelangel.github.io/sonidos-seis8s/" + sonidoTeclado
      });
    
   canalDelTeclado = new Tone.Channel({
    volume:  normalizarVolumen(volumen), // Volume in decibels
    pan: (paneo * 2) -1,    // Panning from 0 (left) to 1 (right)
  }).toDestination();

   tecladoSampler.connect(canalDelTeclado);
  
  let newBaseUrl = "https://luisnavarrodelangel.github.io/sonidos-seis8s/" + sonidoTeclado;
  if (tecladoSampler.baseUrl !== newBaseUrl) {
    tecladoSampler.releaseAll(); // Stop all currently playing notes
    tecladoSampler.baseUrl = newBaseUrl;  // Update base URL to the new sound
  } 
}



function playSequence(armonia, instrumento, volumen, paneo, indiceSonido, cuantizar, notas, parte, octavaAbsoluta) {
  
  // Stop and dispose of any existing sequences or channels
//   if (seq1) {
//     seq1.stop();
//     seq1.dispose();
//     seq1 = null;  // Clear reference
//   }

//   if (seq2) {
//     seq2.stop();
//     seq2.dispose();
//     seq2 = null;  // Clear reference
//   }

//   if (canalDelBajo) {
//     canalDelBajo.dispose();
//     canalDelBajo = null;  // Clear reference
//   }

//   if (canalDelTeclado) {
//     canalDelTeclado.dispose();
//     canalDelTeclado = null;  // Clear reference
//   }

  // Bajo
  if (instrumento === "bajo") {
    
    if (seq1) {
      seq1.stop();
      seq1.dispose();
      seq1 = null;
    }

    // if (canalDelBajo) {
    //   canalDelBajo.dispose();
    //   canalDelBajo = null;
    // }

    let sonidoBajo = listaDeSonidosDelBajo[indiceSonido].nombre;

    // Create bajoSampler and ensure it's fully loaded before triggering anything
    let bajoSampler = new Tone.Sampler({
      urls: { C4: "C4.wav" },
      release: 1,
      baseUrl: "https://luisnavarrodelangel.github.io/sonidos-seis8s/" + sonidoBajo
    });

    // Create channel for the bass
    canalDelBajo = new Tone.Channel({
      volume: normalizarVolumen(volumen),  // Volume in decibels
      pan: (paneo * 2) - 1,  // Panning from -1 (left) to 1 (right)
    }).toDestination();
    
      

    // Connect sampler to the channel
    bajoSampler.connect(canalDelBajo);

    // Ensure sampler is fully loaded before starting the sequence
   
 canalDelBajo.volume.rampTo(normalizarVolumen(volumen), 0.1); // Smooth volume change over 0.5 seconds
  canalDelBajo.pan.rampTo((paneo * 2) - 1, 0.1); // Smooth pan change over 0.5 seconds

     
      if (notas.length > 0 && parte.length === 0) {  // Logical operator corrected
        console.log("Starting sequence!");

        // Create and start the sequence
        
      Tone.loaded().then(() => {
      console.log("Sampler fully loaded!");
        seq1 = new Tone.Sequence((time, note) => {
          bajoSampler.triggerAttackRelease(note, 0.1, time);
        }, notas, '1m');   // '1m' represents one measure as the interval

        seq1.start(0);
      
      });
//  bajo (n [[@], [𝅗𝅥 𝅗𝅥], [𝅘𝅥 𝅘𝅥 𝅘𝅥 𝅘𝅥], []])   
    
  } else if (notas.length > 0 && parte.length > 0) {
     console.log("parte!")
        
     let _armonia = a.armoniaEnNotasExplicitas(armonia);    
     let _parte = a.armoniaEnGradosAarmoniaEnNotas(parte, _armonia, octavaAbsoluta);
     console.log('parteBajo', _parte)
    // let p =  [{ "time": "0:0:0", "note": 'C4', "duration": "4n" }, { "time": "0:1:0", "note": null, "duration": "4n" }, { "time": "0:2:0", "note": 'E4', "duration": "4n" }, { "time": "0:3:0", "note": 'G4', "duration": "4n" }]
 
    // let p =  [[{ "time": "0:0:0", "note": 1, "duration": "4n" }, { "time": "0:1:0", "note": null, "duration": "4n" }, { "time": "0:2:0", "note": 3, "duration": "4n" }, { "time": "0:3:0", "note": 5, "duration": "4n" } ]]
   
    
    // let filteredParte = _parte.flat().filter(event => event.note !== null);
    // console.log("parte", filteredParte);

     Tone.loaded().then(() => {
       seq1 = new Tone.Part((time, value) => {
        bajoSampler.triggerAttackRelease(value.note, value.duration, time);
    }, _parte).start(0);
      seq1.loop = true; // Enable looping
  
       let numeroDeCompases = a.numberOfMeasures(_parte);
       seq1.loopEnd = numeroDeCompases + 1 + "m"
     })
  }
}
    
//     Teclado
  if (instrumento === "teclado"){
    
    if (seq2) {
      seq2.stop();
      seq2.dispose();
      seq2 = null;
    }

    // if (canalDelTeclado) {
    //   canalDelTeclado.dispose();
    //   canalDelTeclado = null;
    // }
    
    // let secuenciaDeNotasYacordes = crearAcordeDesdeLista(['E4', 'C4 D5 E5   ']); 
    let secuenciaDeNotasYacordes = a.crearAcordeDesdeLista(notas); 
     
    let sonidoTeclado = listaDeSonidosDelTeclado[indiceSonido].nombre;  
    tecladoSamplerF(sonidoTeclado, volumen, paneo)
  

//    Tone.loaded().then(() => {
//       secuenciaDeNotasYacordes.forEach(function (n, index){            
//         new Tone.Sequence((time, note) => {
//          tecladoSampler.triggerAttackRelease(note, 0.1, time);
// }, n, '1m').start(0);
//       });
//    });
                    
// }
    
    // const parteTeclado = [{ "time": "0:1:0", "note": ['C4', 'E4', 'G4'], "duration": "4n" }, { "time": "0:3:0", "note": ['G4', 'B4', 'D4'], "duration": "4n" }]
//  // :: [{time, note, duration} , ... ] -> [{tonal chord}] -> [{time, note duration}, ...]

    let armoniaT = a.armoniaEnNotasExplicitas(armonia);    
    let eParte = { "time": "0:0:0", "note": 1, "duration": "4n", "octavaRelativa": 0 }
    let acorde = Tonal.Chord.get('Cmaj')
    
    // let parteTeclado_ =  a.asignarNotasSegunGradosDelAcordeTeclado(eParte, acorde, octavaAbsoluta);
    let parteTeclado_ =  a.armoniaEnGradosAarmoniaEnNotasTeclado(parte, armoniaT, octavaAbsoluta);
    console.log('parteTeclado', parteTeclado_)
    
    // :: [{time, note, duration} , ... ] -> [{tonal chord}] -> [{time, note duration}, ...]
 // function listaDeGradosAlistaDeNotasTeclado(elementosParteList, chordPropertiesList, octavaAbsoluta)
          
     Tone.loaded().then(() => {
       seq2 = new Tone.Part((time, value) => {
        tecladoSampler.triggerAttackRelease(value.note, value.duration, time);  
         // console.log("acorde", value.note);
    }, parteTeclado_).start(0);
      seq2.loop = true; // Enable looping
  
       let numeroDeCompases = a.numberOfMeasures(parteTeclado_);
       seq2.loopEnd = numeroDeCompases + 1 + "m"
     })
  }
  
  
  //     Teclado2
  if (instrumento === "teclado2"){
    
    if (seq5) {
      seq5.stop();
      seq5.dispose();
      seq5 = null;
    }

//     if (canalDelTeclado2) {
//       canalDelTeclado2.dispose();
//       canalDelTeclado2 = null;
//     }
    
    // let secuenciaDeNotasYacordes = crearAcordeDesdeLista(['E4', 'C4 D5 E5   ']); 
    let secuenciaDeNotasYacordes = a.crearAcordeDesdeLista(notas); 
     
    let sonidoTeclado = listaDeSonidosDelTeclado[indiceSonido].nombre;  
    
    let tecladoSampler = new Tone.Sampler({
        urls: {
          C5: "C5.wav"
        },
        release: 1, baseUrl: "https://luisnavarrodelangel.github.io/sonidos-seis8s/" + sonidoTeclado
      });
    
   canalDelTeclado2 = new Tone.Channel({
    volume:  normalizarVolumen(volumen), // Volume in decibels
    pan: (paneo * 2) -1,    // Panning from 0 (left) to 1 (right)
  }).toDestination();

   tecladoSampler.connect(canalDelTeclado2);

// Ensure samples are loaded
  Tone.loaded().then(() => {
    // Create a new sequence to handle all notes and chords
      seq5 = new Tone.Sequence((time, note) => {
         tecladoSampler.triggerAttackRelease(note, 0.1, time);
}, notas, '1m').start(0);
  });
    
//    Tone.loaded().then(() => {
//       secuenciaDeNotasYacordes.forEach(function (n, index){            
//         seq5 = new Tone.Sequence((time, note) => {
//          tecladoSampler.triggerAttackRelease(note, 0.1, time);
// }, n, '1m').start(0);
//       });
//    });
                    

    
   
//     let armoniaT = a.armoniaEnNotasExplicitas(armonia);    
//     let eParte = { "time": "0:0:0", "note": 1, "duration": "4n", "octavaRelativa": 0 }
//     let acorde = Tonal.Chord.get('Cmaj')
    
//     // let parteTeclado_ =  a.asignarNotasSegunGradosDelAcordeTeclado(eParte, acorde, octavaAbsoluta);
//     let parteTeclado_ =  a.armoniaEnGradosAarmoniaEnNotasTeclado(parte, armoniaT, octavaAbsoluta);
//     console.log('parteTeclado', parteTeclado_)
    
//     // :: [{time, note, duration} , ... ] -> [{tonal chord}] -> [{time, note duration}, ...]
//  // function listaDeGradosAlistaDeNotasTeclado(elementosParteList, chordPropertiesList, octavaAbsoluta)
          
//      Tone.loaded().then(() => {
//        seq5 = new Tone.Part((time, value) => {
//         tecladoSampler.triggerAttackRelease(value.note, value.duration, time);  
//          // console.log("acorde", value.note);
//     }, parteTeclado_).start(0);
//       seq2.loop = true; // Enable looping
  
//        let numeroDeCompases = a.numberOfMeasures(parteTeclado_);
//        seq5.loopEnd = numeroDeCompases + 1 + "m"
//      })
  }
  
  
   if (instrumento === "bombo") {
    
    if (seq3) {
      seq3.stop();
      seq3.dispose();
      seq3 = null;
    }

    // if (canalDelBombo) {
    //   canalDelBombo.dispose();
    //   canalDelBombo = null;
    // }
     
     

    let sonidoBombo = listaDeSonidosDelBombo[indiceSonido].nombre;

   
 // Update the existing sampler and channel with new sound, volume, and pan
  bomboSamplerF(sonidoBombo, volumen, paneo);

     // Apply smooth transitions for volume and pan
  // canalDelBombo.volume.rampTo(normalizarVolumen(volumen), 0.1); // Smooth volume change over 0.5 seconds
  // canalDelBombo.pan.rampTo((paneo * 2) - 1, 0.1); // Smooth pan change over 0.5 seconds

     
     function p(parteNonFlattened) {
      let parteFlattened = parteNonFlattened.flat();
      let filteredParte = parteFlattened.filter(e => e.note !== null);
      filteredParte.forEach(e => e.note = 'C4');
      return filteredParte;
    }

     
       let parte_ =  p(parte)

     
     // console.log("parte bombo", parte_)
     
      Tone.loaded().then(() => {
       seq3 = new Tone.Part((time, value) => {
        bomboSampler.triggerAttackRelease(value.note, value.duration, time);
    }, parte_).start(0);
      seq3.loop = true; // Enable looping
  
       let numeroDeCompases = a.numberOfMeasures(parte_);
       seq3.loopEnd = numeroDeCompases + 1 + "m"
     })
   }
  
  
  ///////////////contratiempos
  
  
  if (instrumento === "contratiempo" || instrumento === "contratiempos" || instrumento === "contras")  {
    
    if (seq4) {
      seq4.stop();
      seq4.dispose();
      seq4 = null;
    }

    // if (canalDeContratiempos) {
    //   canalDeContratiempos.dispose();
    //   canalDeContratiempos = null;
    // }
     
     

    let sonidoContratiempos = listaDeSonidosDelContratiempo[indiceSonido].nombre;

    // Create bajoSampler and ensure it's fully loaded before triggering anything
    let contratiemposSampler = new Tone.Sampler({
      urls: { C4: "F#2.wav" },
      release: 1,
      baseUrl: "https://luisnavarrodelangel.github.io/sonidos-seis8s/" + sonidoContratiempos
    });    
     
     
       // Create channel for the bass
    canalDeContratiempos = new Tone.Channel({
      volume: normalizarVolumen(volumen),  // Volume in decibels
      pan: (paneo * 2) - 1,  // Panning from -1 (left) to 1 (right)
    }).toDestination();
    
      

    // Connect sampler to the channel
    contratiemposSampler.connect(canalDeContratiempos);

     
     function p(parteNonFlattened) {
      let parteFlattened = parteNonFlattened.flat();
      let filteredParte = parteFlattened.filter(e => e.note !== null);
      filteredParte.forEach(e => e.note = 'C4');
      return filteredParte;
    }

     
       let parte_ =  p(parte)

     
     console.log("parte contras", parte_)
     
      Tone.loaded().then(() => {
       seq4 = new Tone.Part((time, value) => {
        contratiemposSampler.triggerAttackRelease(value.note, value.duration, time);
    }, parte_).start(0);
      seq4.loop = true; // Enable looping
  
       let numeroDeCompases = a.numberOfMeasures(parte_);
       seq4.loopEnd = numeroDeCompases + 1 + "m"
     });
   }
  }
  



// :: Object -> [Object] 
export function programa(estadoGlobal, pistas){
  
  establecerTempo(estadoGlobal.tempo);
 
 let arm = a.armoniaEnNotasExplicitas(estadoGlobal.armonia)
  
  if (pistas.length !== 0) { 
    pistas.forEach(function (pista){

      playSequence (estadoGlobal.armonia, pista.name, pista.volumen, pista.paneo, pista.sonido, '1m', pista.notas, pista.parte, pista.octavaAbsoluta);
  });
 } else {
  stopSequence()
 };
}