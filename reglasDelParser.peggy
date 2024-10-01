 {

function createProperty(key, value) {
  return { [key]: value }; 
}

const datosDelPrograma = {
  estadoGlobal: {
    armonia: ['Cmaj'],
    tempo: 120, 
    compas: 4, 
    volumen: 1, 
    paneo: 0.5
  },
  pistas: []
}

//se debe llamar nota para cuadrar con las notas de Tonejs
const defaultElementoDeParte = {
  time: '0:0:0', 
  note: 'C4',  // nota o grado
  duration: '1n', 
  octavaRelativa: 0
  }
  
const defaultMusicalObject = {
  name: '',
  volumen: 1, // Default volume
  paneo: 0.5, // Default panning
  sonido: 0,
  octavaAbsoluta: 5,
  notas: ['C4'], // Default note
  parte: []
}



function normalizarVolumenDeInstrumento(v){
  return v * datosDelPrograma.estadoGlobal.volumen;
}

function completeMusicalObject(inputObject) {
  // Merge inputObject with defaultMusicalObject
  const completedObject = { ...defaultMusicalObject, ...inputObject };
  
  // Use global volumen and paneo if not set in inputObject
  if (!inputObject.hasOwnProperty('volumen')) {
    completedObject.volumen = datosDelPrograma.estadoGlobal.volumen;
  }
  if (!inputObject.hasOwnProperty('paneo')) {
    completedObject.paneo = datosDelPrograma.estadoGlobal.paneo;
  }
  
   // Execute the octava method
  function octavaAbsolutaf(instrumento){
    if (instrumento === "bajo") {
      return 4;
    } else {
      return 5;
    }
  };
  
  if (!inputObject.hasOwnProperty('octavaAbsoluta')) {
    completedObject.octavaAbsoluta = octavaAbsolutaf(completedObject.name);
    }
    
 
  return completedObject;
}

function crearAcorde(xs){
  return xs.join(" ").trim()
  };
  
function completeParteObject(inputObject) {
  // Merge inputObject with defaultElementoDeParte
  const completedObject = { ...defaultElementoDeParte, ...inputObject };  
  return completedObject;
}

// :: [Object] -> [Object]
function beatCounter(bar) {
  bar.forEach((item, index) => {
    const beat = index % 4; // Ensures the beat is within the 0-3 range (for 4/4 time)
    const barNum = Math.floor(index / 4); // Increments the bar number after every 4 beats
    item.time = `${barNum}:${beat}:0`; // Update the time property
  });
  return bar; // Optional: return the modified array
}
  //:: [Object] -> Int -> [Object]
  //[{ time: '1n', note: 'C4', duration: '1n', size: 1}, ...]
  
function numeroDeCompas(compas, numeroDeCompas){
    compas.forEach((elemento) => {
     let [bar, beat, subBeat] = elemento.time.split(':').map(Number);
      elemento.time = `${numeroDeCompas}:${beat}:${subBeat}`;
  });
}

//:: [Object] -> [Object]
// Convert note duration to time (assuming 4n = 1, 8n = 0.5, etc.)
const duracionNotaADuracionEnTiempo = (duracion) => {
    const duracionMap = {
        '1n': 4,
        '2n': 2,
        '4n': 1,
        '8n': 0.5,
        '16n': 0.25
    };
    return duracionMap[duracion] || 1; // Default to quarter note duration
};


function agregarTiempo(timeProperty, duracion) {
    let [bar, beat, subBeat] = timeProperty.split(':').map(Number);
    
    // Add the duration to the beat
    beat += duracion;

    // Extract the decimal part from the beat and add it to subBeat
    let beatInteger = Math.floor(beat);  // Get the integer part of the beat
    let beatFraction = beat - beatInteger;  // Get the fractional part of the beat

    // Convert the fractional part into subBeat units (assuming 1 beat = 4 subBeats)
    subBeat += beatFraction * 4;

    // Handle overflow of subBeat into beats
    if (subBeat >= 4) { // Assuming sub-beat division of 4 (quarter notes)
        beatInteger += Math.floor(subBeat / 4);
        subBeat %= 4;
    }

    return `${bar}:${beatInteger}:${Math.round(subBeat)}`;
}



// Function to assign time positions to notes, adjusting only beat and sub-beat
function asignarPosTiempoDeNotasPorCompas(compas) {
    compas.forEach((elemento, index) => {
        if (index === 0) {
            elemento.time = elemento.time; // First note keeps its original time
        } else {
            let duracionNotaAnterior = duracionNotaADuracionEnTiempo(compas[index - 1].duration);
            elemento.time = agregarTiempo(compas[index - 1].time, duracionNotaAnterior);
        }
    });

    return compas;
}




function asignarNumeroDeCompas(listaDeCompases){
    listaDeCompases.forEach((compas, index) => {
      numeroDeCompas(compas, index);
    });
    return listaDeCompases;
}
  
} 

start = _ (pista / estadoGlobal)* {return datosDelPrograma }
estadoGlobal
  = _ k:("armonia" / "acordes") _ v:listaDeAcordesGlobales _ ";" {
          if (v.length == 0) {
           return error(k + ' requiere uno o más compases con acordes')
          } else return datosDelPrograma.estadoGlobal.armonia = v
        }
  / _ k:("tempo" / "t") _ v:entero _ ";" _ {return datosDelPrograma.estadoGlobal.tempo = v}
  / _ k:("compas" / "c") _ v:string _ ";" _ {return datosDelPrograma.estadoGlobal.compas = v}
  / _ k:("volumen" / "v") _ v:decimal _ ";" _ {
    if (v >= 0 && v <= 1) {
      return datosDelPrograma.estadoGlobal.volumen = v
  } else {
    error("volumen requiere un número entre 0 y 1");
  }
}
  / _ k:("paneo" / "p") _ v:decimal _ ";" _ {
   if (v >= 0 && v <= 1) {
      return datosDelPrograma.estadoGlobal.paneo = v
  } else {
    error("paneo requiere un número entre 0 y 1");
  }
  }

pista 
  = _ i:instrumentIdentifier  _ p:listaDePropiedades? _ ";" _ {
  if(p == null) {
  let pista = Object.assign({}, i);
  return datosDelPrograma.pistas = [...datosDelPrograma.pistas, completeMusicalObject(pista)];
} else {
  let pista = Object.assign({}, i, ... p);
  return datosDelPrograma.pistas = [...datosDelPrograma.pistas, completeMusicalObject(pista)];
}
}  

instrumentIdentifier
  = i:"bajo" { return createProperty("name", i)}
  / i:"teclado2" { return createProperty("name", i)}
  / i:"teclado" { return createProperty("name", i)}
  / i:"bombo" {return createProperty("name", i)}
  / i:("contras"/"contratiempos" / "contratiempo") {return createProperty("name", i)}
  / i:"congas" {return createProperty("name", i)}
  

listaDePropiedades
  = "(" _ p:(propiedad|.., _ "," _|) _ ")" {return p}
  
propiedad 
  = _ k:("sonido" / "s") _ v:entero _ {return createProperty("sonido", v)}
  / _ k:("paneo" / "p") _ v:decimal _ {
  if (v >= 0 && v <= 1) {
  return createProperty("paneo", v);
  } else {
    error("paneo requiere un número entre 0 y 1");
  }
  }
  / _ k:("volumen" / "v") _ v:decimal _ {
   if (v >= 0 && v <= 1) {
  return createProperty("volumen", normalizarVolumenDeInstrumento(v));
  } else {
    error("volumen requiere un número entre 0 y 1");
  }
  }
  / _ k:("octava" / "o") _ v:entero _ {return createProperty("octavaAbsoluta", v)}
  / _ k:("notas" / "n") _ v:(notaSola / listaDeNotas) _ {return createProperty("notas", v)}
  / _ k:("parte" / "tumbao" / "acompañamiento" / "acompanamiento" / "ritmo") _ v:listaDeCompases _ {
         if (v.length == 0) {
           return error(k + " " + 'requiere uno o más compases')
          } else return createProperty("parte", v)
   }

// TODO lista de lista de parte
listaDeCompases
  =  _ ls:compas|.., _| _ {
     return asignarNumeroDeCompas(ls)
     }

compas 
   =  _ "|" _ ls:parte|.., _| _ "|" _ {
    let tamanoDelCompas = ls.reduce((acc, obj) => acc + duracionNotaADuracionEnTiempo(obj.duration), 0);
    if (tamanoDelCompas == datosDelPrograma.estadoGlobal.compas) {
      return asignarPosTiempoDeNotasPorCompas(ls);  // [{ time: '1n', note: 'C4', duration: '1n'}, ...]
    } else if (tamanoDelCompas < datosDelPrograma.estadoGlobal.compas) {
      return error('El tamano del compas es menor a ' + datosDelPrograma.estadoGlobal.compas)
    } else if (tamanoDelCompas > datosDelPrograma.estadoGlobal.compas) {
      return error('El tamano del compas es mayor a ' + datosDelPrograma.estadoGlobal.compas)
  }
}
   
parte 
  = _ v:partes _ {
       //let parte = Object.assign({}, v);
       return completeParteObject(v); // { time: '1n', note: 'C4', duration: '1n' }
       }

listaDeNotas
  = _ "[" _ notaOListaDeNotas:listaDeNotaOlistaDeNotas? _ "]" _ { return notaOListaDeNotas || []; }

listaDeNotaOlistaDeNotas =  notaOListaDeNotas|.., _ "," _| 

notaOListaDeNotas =  silencio / nota / acorde / listaDeNotas 

acorde = "\"" _ n1:nota _ n2:nota? _ n3:nota? _ n4:nota? _ n5:nota? _ "\"" {
return crearAcorde([n1, n2, n3, n4, n5]) }

silencio = "~" {return null}

notaSola
 = n:nota {return [n]}
 
nota
  = letra:letra alteracion:alteracion? octava:entero {
  if (alteracion == null) {
    return (letra + octava)
  } else {
      return (letra + alteracion + octava)
  }
}

cualidad
   = "mayor" {return 'maj'} / "maj" / "min" / "menor" {return 'min'} / "m" / "M"
    
alteracion
  = "#" / "bb" / "b" / "x" 
  
letra
  = alfabetoIngles / alfabetoLatino

  
alfabetoIngles 
  = $[A, B, C, D, E, F, G] 
  
alfabetoLatino
  = 'do' {return 'C'} / 're' {return 'D'} / 'mi' {return 'E'} / 'fa' {return 'F'} / 'sol' {return 'G'} / 'la' {return 'A'} / 'si' {return 'B'}

////ritmo más grados del bajo

partes
  = ritmoMasGradoDelBajoMasOctavaRelativa
  / ritmoSinGradoDelBajoMasOctavaRelativa
  / ritmoMasGradoDelBajo
  / ritmoSinGradoDelBajo
  / silenciosDeFigurasMusicales
  
  
silenciosDeFigurasMusicales
   = _ s:silencioDeFiguraMusical {
   let g = createProperty("note", null);
   return Object.assign(s, g)
   }
   
ritmoSinGradoDelBajoMasOctavaRelativa
   = _ r:ritmoSinGradoDelBajo _ o:octavaRelativa _ {
      return Object.assign({}, r, o);
    }

ritmoSinGradoDelBajo
   = _ f:figuraMusical {
   let g = createProperty("note", 1);
   return Object.assign(f, g)
   }
   
ritmoMasGradoDelBajoMasOctavaRelativa
   = _ r:ritmoMasGradoDelBajo _ o:octavaRelativa _ {
      return Object.assign({}, r, o);
    }
   
ritmoMasGradoDelBajo 
    = _ f:figuraMusical _ "/" _ g:gradoDelBajo _ {
    return Object.assign({}, f, g);
    }

//octava arriba o abajo 
octavaRelativa = octavaArriba
               / octavaAbajo
               
octavaArriba 
         = _ '^' _ {return createProperty("octavaRelativa", 1)}

octavaAbajo
         = _ '_' _ {return createProperty("octavaRelativa", (-1))}
         
//grados bajo
gradoDelBajo 
   = n:number {return createProperty("note", n);}

// notacion ritmica
 
 //{ time: '1n', note: 'C4', duration: '1n' } 
figuraMusical
   = _ '𝅝' _ {return createProperty("duration", '1n');}
   / _ '𝅗𝅥' _ {return createProperty("duration", '2n');}
   / _ '𝅘𝅥' _   {return createProperty("duration", '4n');}   
   / _ '𝅘𝅥𝅮' _ {return createProperty("duration", '8n');}   
   / _ '𝅘𝅥𝅯' _  {return createProperty("duration", '16n');}
   
 silencioDeFiguraMusical
   = _ '𝄻' _ {return createProperty("duration", '1n');}
   / _ '𝄼' _ {return createProperty("duration", '2n');}
   / _ '𝄽' _ {return createProperty("duration", '4n');}
   / _ '𝄾' _ {return createProperty("duration", '8n');}
   / _ '𝄿' _ {return createProperty("duration", '16n');}
   
   
///////// acordes estado global   
listaDeAcordesGlobales
   =  ls:listaDeAcordeGlobal|.., _|  {return ls}


listaDeAcordeGlobal
   = _ "|" _ ls:acordeGlobal|.., _| _ "|" _ {
          if (ls.length == 0) {
           return error('Armonia/acordes requiere uno o más acordes')
          } else return ls
         }
   
acordeGlobal = _ letra:letra alteracion:alteracion? cualidad:cualidad? _ {
  return letra + (alteracion ?? "") + (cualidad ?? "");
}
//////////////////

decimal 
   = head:entero tail: ("." entero)? {
  const decimalPart = tail ? parseFloat(`0.${tail[1]}`) : 0;
  const result = head + decimalPart
    return result
    }
  
 
entero = [0-9]+ {
  return parseInt(text(), 10);
}

number
  = [0-9]+ { return parseFloat(text()); }

string
  = [a-z]+ { return text(); }
    

word
  = $[a-z]i+

_ = [ \t\r\n]*
