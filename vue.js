import * as i from "./instrumento.js";
import * as parser from "./parser.mjs";


const app = Vue.createApp({
  

  data() {
    return {
         output: '',
//       banner and text-to-speech
      publish: false,
      textoDelBanner: 'Cumbia!!! Cumbia!!! Cumbia!!!',
      spanishVoices: [],
      selectedVoice: null,
//       imagen de fondo
      imagenDeFondo: 'image',
      hrefImagenDeFondo: 'https://cdn.glitch.global/1c9491c3-d804-48fe-9d1e-06e2c4f58528/bolsa-de-papas%202.svg?v=1720034945651',
      zoomInOrOut: 'zoom_in',
      sizeBase: 200,
      textSize: "200%",
      transparentCaret: true,
      yellowCaret: false,
      mostrarOpcionesMenuPanelDerecho: false,
// opciones panel izquierdo     
      mostrarOpcionesMenuPanelIzquierdo: false,
      tituloPanelIzquierdo: 'Saludos',
      mostrarConexionesMidiContenedor: false,
      mostrarTutorialesContenedor: false,
      mostrarAcercaDeContenedor: false,
      mostrarSaludosContenedor: true,
      mostrarTituloPanelIzquierdo: true,
      saludos: "Saludos!!!",
      saludosTranslated: "Greetings!!!",
      errorConsole: "Seis8s v.2",
//       
      // codeExample1: `bajo; \nteclado;`,
      codeEditorImagenDeFondoXpos: 345.28,
      codeEditorXpos: 343.5,
      consoleXpos: 343.606,
      anchoDelMenuDerecho: 63.0066,
      indiceDelDocumentoActivo: 0,
      numeroDeDocumento: 1,
      estaElDocumentoActivo: false,
      initXdocTab: 406.506,
      initXCerrarDocIcono: 549.422,
      isEditing: false,
      text: "",
      clicks: 0,
      timer: null,
      delay: 100, // Adjust the delay as needed
      initXPlusSsign: 575.524,
      espacioPlusSignYtab: 0.736,
      anchoDelDocTab: 168.017,
      docs: [],
      // docs:[{name: "Documento 1", documentoActivo: true, textareaId: "textarea1", xDocTab: 406.506, xCerrarDocIcono: 549.422, textEditor: `bajo tumbao cumbia; \nteclado acompañamiento cumbia;`}],
    };
  },

  mounted() {
    // let ejemploDeInicio = `bajo tumbao cumbia;\n teclado tumbao cumbia;\n marcha congas cumbia;`
    // let ejemploDeInicio = `tempo 150;\n armonia |Cmaj||Dm|;\n bajo (tumbao | 𝅘𝅥  𝄽  𝅘𝅥 /3 𝅘𝅥 /5|| 𝅘𝅥  𝄽  𝅘𝅥 /3 𝅘𝅥 /5|);`
    // let ejemploDeInicio = `tempo 150;\n armonia |Cmaj||Dm|;\n teclado (tumbao | 𝅘𝅥  𝄽  𝅘𝅥 /3 𝅘𝅥 /5|| 𝅘𝅥  𝄽  𝅘𝅥 /3 𝅘𝅥 /5|);`
    let ejemploDeInicio = ` tempo 150; \n armonia |Cmaj||Dm|; \n teclado (v 0.75, tumbao | 𝄽  𝅘𝅥  𝄽  𝅘𝅥 || 𝄽  𝅘𝅥  𝄽  𝅘𝅥 |);\n bajo (v 1, s 3, tumbao | 𝅘𝅥  𝄽  𝅘𝅥 /3 𝅘𝅥 /5 || 𝅘𝅥  𝄽  𝅘𝅥 /3 𝅘𝅥 /5 |);`
    // ejemploDeInicio = ejemploDeInicio.split(';').map(s => s.trim()).join('\n');
    this.agregaUnDocADocs();
    this.$nextTick(() => {
    this.docs[0].textEditor = ejemploDeInicio;
    });
//     populate text-to-speech drodpdown
  const speechSynthesis = window.speechSynthesis;
    speechSynthesis.onvoiceschanged = () => {
      // Get the list of voices available
      let voices = speechSynthesis.getVoices();

      // Filter for Spanish voices
      this.spanishVoices = voices.filter(voice => voice.lang.includes('en'));
      

      // Call mandarSaludos when the voices have been populated
      this.mandarSaludos();
    };
  },

  methods: {
    startEditing() {
      this.isEditing = true;
    },
    stopEditing() {
      this.isEditing = false;
    },

    textEditorFocus(index) {
      let key = "editorTextArea" + index;
      this.$nextTick(() => {
        this.$refs[key][0].focus();
        this.indiceDelDocumentoActivo = index;
        this.transparentCaret = true;
        this.yellowCaret = false;
      });
    },

    tabFocus(key) {
      this.$refs[key][0].focus();
      this.yellowCaret = true;
    },

    // evaluate,
    
     stop() {
        i.stopSequence();
    },
    
    stopShortCut(event) {
      if (event.ctrlKey && event.key === ".") {
        i.stopSequence();
      }
    },

    abrirMenuIzquierdo() {
      this.mostrarOpcionesMenuPanelIzquierdo =  !this.mostrarOpcionesMenuPanelIzquierdo;
      this.mostrarTituloPanelIzquierdo = !this.mostrarTituloPanelIzquierdo;
    },

    abrirMenuDerecho() {
      this.mostrarOpcionesMenuPanelDerecho =
        !this.mostrarOpcionesMenuPanelDerecho;

      if (this.mostrarOpcionesMenuPanelDerecho == true) {
        this.codeEditorImagenDeFondoXpos =
          this.codeEditorImagenDeFondoXpos + this.anchoDelMenuDerecho;
        this.codeEditorXpos = this.codeEditorXpos + this.anchoDelMenuDerecho;
        this.consoleXpos = this.consoleXpos + this.anchoDelMenuDerecho;
      } else if (this.mostrarOpcionesMenuPanelDerecho == false) {
        this.codeEditorImagenDeFondoXpos =
          this.codeEditorImagenDeFondoXpos - this.anchoDelMenuDerecho;
        this.codeEditorXpos = this.codeEditorXpos - this.anchoDelMenuDerecho;
        this.consoleXpos = this.consoleXpos - this.anchoDelMenuDerecho;
      }
    },

    activarDocumento(index) {
      this.indiceDelDocumento = index;
      for (var i = 0; i < this.docs.length; i++) {
        this.docs[i].documentoActivo = false;
      }
      this.docs[index].documentoActivo = true;
      this.textEditorFocus(index);
      this.transparentCaret = true;
      this.yellowCaret = false;
    },

    //     AGREGAR UN NUEVO DOC

    agregaUnDocADocs() {
      if (this.docs.length == 0) {
        this.initXPlusSsign = 575.524;
        this.initXdocTab = 406.506;
        this.initXCerrarDocIcono = 549.422;
        let newDoc = {
          name: "Documento ",
          documentoActivo: false,
          textareaId: "textarea",
          xDocTab: this.initXdocTab,
          xCerrarDocIcono: this.initXCerrarDocIcono,
          textEditor: "",
        };
        this.docs.push(newDoc);
        let id = this.docs.length - 1;
        this.activarDocumento(id);
        this.textEditorFocus(id);
      } else if (this.docs.length > 0 && this.docs.length < 5) {
        let lastElementOfList = this.docs.length - 1;
        this.initXdocTab =
          this.docs[lastElementOfList].xDocTab + this.anchoDelDocTab;
        this.initXCerrarDocIcono =
          this.docs[lastElementOfList].xCerrarDocIcono + this.anchoDelDocTab;
        let newDoc = {
          name: "Documento ",
          documentoActivo: false,
          textareaId: "textarea",
          xDocTab: this.initXdocTab,
          xCerrarDocIcono: this.initXCerrarDocIcono,
          textEditor: "",
        };
        this.docs.push(newDoc);
        let id = this.docs.length - 1;
        this.activarDocumento(id);
        this.textEditorFocus(id);
        let updatedLastElementOfList = id;
        this.initXPlusSsign =
          this.docs[updatedLastElementOfList].xDocTab +
          this.anchoDelDocTab +
          this.espacioPlusSignYtab;
      } else alert("El límite de documentos es 5");
    },

    // CERRAR UN DOCUMENTO

    cerrarDocumento(index) {
      if (this.docs.length == 1) {
        let replaceXdocTab1 = this.docs[index].xDocTab;
        this.initXPlusSsign = replaceXdocTab1;
        this.docs.splice(index, 1);
      } else if (this.docs.length == 2) {
        if (index == 1) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          this.initXPlusSsign = replaceXdocTab1;
          this.docs.splice(index, 1);
          this.activarDocumento(index - 1);
          let textAreaRef = index - 1;
          this.textEditorFocus(textAreaRef);
        } else if (index == 0) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          let replaceXcerrarDocIcono1 = this.docs[index].xCerrarDocIcono;
          this.docs[index + 1].xDocTab = replaceXdocTab1;
          this.docs[1].xCerrarDocIcono = replaceXcerrarDocIcono1;
          this.initXPlusSsign = replaceXdocTab1 + this.anchoDelDocTab;
          this.docs.splice(index, 1);
          this.activarDocumento(index);
          let textAreaRef = index;
          this.textEditorFocus(textAreaRef);
        }
      } else if (this.docs.length == 3) {
        if (index == 2) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          this.initXPlusSsign = replaceXdocTab1;
          this.docs.splice(index, 1);
          this.activarDocumento(index - 1);
          let textAreaRef = index - 1;
          this.textEditorFocus(textAreaRef);
        } else if (index == 1) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          let replaceXcerrarDocIcono1 = this.docs[index].xCerrarDocIcono;
          this.docs[index + 1].xDocTab = replaceXdocTab1;
          this.docs[index + 1].xCerrarDocIcono = replaceXcerrarDocIcono1;
          this.initXPlusSsign = replaceXdocTab1 + this.anchoDelDocTab;
          this.docs.splice(index, 1);
          this.activarDocumento(index);
          this.textEditorFocus(index);
        } else if (index == 0) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          let replaceXdocTab2 = this.docs[index + 1].xDocTab;
          let replaceXcerrarDocIcono1 = this.docs[index].xCerrarDocIcono;
          let replaceXcerrarDocIcono2 = this.docs[index + 1].xCerrarDocIcono;
          this.docs[index + 1].xDocTab = replaceXdocTab1;
          this.docs[index + 1].xCerrarDocIcono = replaceXcerrarDocIcono1;
          this.docs[index + 2].xDocTab = replaceXdocTab2;
          this.docs[index + 2].xCerrarDocIcono = replaceXcerrarDocIcono2;
          this.initXPlusSsign = replaceXdocTab2 + this.anchoDelDocTab;
          this.docs.splice(index, 1);
          this.activarDocumento(index);
          this.textEditorFocus(index);
        }
      } else if (this.docs.length == 4) {
        if (index == 3) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          this.initXPlusSsign = replaceXdocTab1;
          this.docs.splice(index, 1);
          this.activarDocumento(index - 1);
          let textAreaRef = index - 1;
          this.textEditorFocus(textAreaRef);
        } else if (index == 2) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          let replaceXcerrarDocIcono1 = this.docs[index].xCerrarDocIcono;
          this.docs[index + 1].xDocTab = replaceXdocTab1;
          this.docs[index + 1].xCerrarDocIcono = replaceXcerrarDocIcono1;
          this.initXPlusSsign = replaceXdocTab1 + this.anchoDelDocTab;
          this.docs.splice(index, 1);
          this.activarDocumento(index);
          this.textEditorFocus(index);
        } else if (index == 1) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          let replaceXdocTab2 = this.docs[index + 1].xDocTab;
          let replaceXcerrarDocIcono1 = this.docs[index].xCerrarDocIcono;
          let replaceXcerrarDocIcono2 = this.docs[index + 1].xCerrarDocIcono;
          this.docs[index + 1].xDocTab = replaceXdocTab1;
          this.docs[index + 1].xCerrarDocIcono = replaceXcerrarDocIcono1;
          this.docs[index + 2].xDocTab = replaceXdocTab2;
          this.docs[index + 2].xCerrarDocIcono = replaceXcerrarDocIcono2;
          this.initXPlusSsign = replaceXdocTab2 + this.anchoDelDocTab;
          this.docs.splice(index, 1);
          this.activarDocumento(index);
          this.textEditorFocus(index);
        } else if (index == 0) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          let replaceXdocTab2 = this.docs[index + 1].xDocTab;
          let replaceXdocTab3 = this.docs[index + 2].xDocTab;
          let replaceXcerrarDocIcono1 = this.docs[index].xCerrarDocIcono;
          let replaceXcerrarDocIcono2 = this.docs[index + 1].xCerrarDocIcono;
          let replaceXcerrarDocIcono3 = this.docs[index + 2].xCerrarDocIcono;
          this.docs[index + 1].xDocTab = replaceXdocTab1;
          this.docs[index + 1].xCerrarDocIcono = replaceXcerrarDocIcono1;
          this.docs[index + 2].xDocTab = replaceXdocTab2;
          this.docs[index + 2].xCerrarDocIcono = replaceXcerrarDocIcono2;
          this.docs[index + 3].xDocTab = replaceXdocTab3;
          this.docs[index + 3].xCerrarDocIcono = replaceXcerrarDocIcono3;
          this.initXPlusSsign = replaceXdocTab3 + this.anchoDelDocTab;
          this.docs.splice(index, 1);
          this.activarDocumento(index);
          this.textEditorFocus(index);
        }
      } else if (this.docs.length == 5) {
        if (index == 4) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          this.initXPlusSsign = replaceXdocTab1;
          this.docs.splice(index, 1);
          this.activarDocumento(index - 1);
          let textAreaRef = index - 1;
          this.textEditorFocus(textAreaRef);
        } else if (index == 3) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          let replaceXcerrarDocIcono1 = this.docs[index].xCerrarDocIcono;
          this.docs[index + 1].xDocTab = replaceXdocTab1;
          this.docs[index + 1].xCerrarDocIcono = replaceXcerrarDocIcono1;
          this.initXPlusSsign = replaceXdocTab1 + this.anchoDelDocTab;
          this.docs.splice(index, 1);
          this.activarDocumento(index);
          this.textEditorFocus(index);
        } else if (index == 2) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          let replaceXdocTab2 = this.docs[index + 1].xDocTab;
          let replaceXcerrarDocIcono1 = this.docs[index].xCerrarDocIcono;
          let replaceXcerrarDocIcono2 = this.docs[index + 1].xCerrarDocIcono;
          this.docs[index + 1].xDocTab = replaceXdocTab1;
          this.docs[index + 1].xCerrarDocIcono = replaceXcerrarDocIcono1;
          this.docs[index + 2].xDocTab = replaceXdocTab2;
          this.docs[index + 2].xCerrarDocIcono = replaceXcerrarDocIcono2;
          this.initXPlusSsign = replaceXdocTab2 + this.anchoDelDocTab;
          this.docs.splice(index, 1);
          this.activarDocumento(index);
          this.textEditorFocus(index);
        } else if (index == 1) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          let replaceXdocTab2 = this.docs[index + 1].xDocTab;
          let replaceXdocTab3 = this.docs[index + 2].xDocTab;
          let replaceXcerrarDocIcono1 = this.docs[index].xCerrarDocIcono;
          let replaceXcerrarDocIcono2 = this.docs[index + 1].xCerrarDocIcono;
          let replaceXcerrarDocIcono3 = this.docs[index + 2].xCerrarDocIcono;
          this.docs[index + 1].xDocTab = replaceXdocTab1;
          this.docs[index + 1].xCerrarDocIcono = replaceXcerrarDocIcono1;
          this.docs[index + 2].xDocTab = replaceXdocTab2;
          this.docs[index + 2].xCerrarDocIcono = replaceXcerrarDocIcono2;
          this.docs[index + 3].xDocTab = replaceXdocTab3;
          this.docs[index + 3].xCerrarDocIcono = replaceXcerrarDocIcono3;
          this.initXPlusSsign = replaceXdocTab3 + this.anchoDelDocTab;
          this.docs.splice(index, 1);
          this.activarDocumento(index);
          this.textEditorFocus(index);
        } else if (index == 0) {
          let replaceXdocTab1 = this.docs[index].xDocTab;
          let replaceXdocTab2 = this.docs[index + 1].xDocTab;
          let replaceXdocTab3 = this.docs[index + 2].xDocTab;
          let replaceXdocTab4 = this.docs[index + 3].xDocTab;
          let replaceXcerrarDocIcono1 = this.docs[index].xCerrarDocIcono;
          let replaceXcerrarDocIcono2 = this.docs[index + 1].xCerrarDocIcono;
          let replaceXcerrarDocIcono3 = this.docs[index + 2].xCerrarDocIcono;
          let replaceXcerrarDocIcono4 = this.docs[index + 3].xCerrarDocIcono;
          this.docs[index + 1].xDocTab = replaceXdocTab1;
          this.docs[index + 1].xCerrarDocIcono = replaceXcerrarDocIcono1;
          this.docs[index + 2].xDocTab = replaceXdocTab2;
          this.docs[index + 2].xCerrarDocIcono = replaceXcerrarDocIcono2;
          this.docs[index + 3].xDocTab = replaceXdocTab3;
          this.docs[index + 3].xCerrarDocIcono = replaceXcerrarDocIcono3;
          this.docs[index + 4].xDocTab = replaceXdocTab4;
          this.docs[index + 4].xCerrarDocIcono = replaceXcerrarDocIcono4;
          this.initXPlusSsign = replaceXdocTab4 + this.anchoDelDocTab;
          this.docs.splice(index, 1);
          this.activarDocumento(index);
          this.textEditorFocus(index);
        }
      }
    },
    
mandarSaludos() {
  
      const message = new SpeechSynthesisUtterance();
      const speechSynthesis = window.speechSynthesis;

      // If there are Spanish voices available, use the selected one
      if (this.selectedVoice) {
        message.voice = this.selectedVoice;
      }

      message.lang = "es-MX"; // Set the language to Spanish
      message.text = this.saludos;
      speechSynthesis.speak(message);

      // Publish greeting in banner
      setTimeout(() => {
        if (this.publish == true) {
          this.textoDelBanner = this.saludos;
        };
      }, 0); // Delay the update of textoDelBanner by 10 seconds, 10000 milliseconds = 10 seconds
    },
  

    incrementarTamanoDeTexto(event) {
      if (!event.ctrlKey) {
        this.zoomInOrOut = 'zoom_in';
        this.sizeBase++;
        let updatedTextSize = this.sizeBase + "%";
        this.textSize = updatedTextSize;
      }
    },

    incrementarTamanoDeTextoShortCut(event) {
      if (event.ctrlKey && event.key === "=") {
        this.zoomInOrOut = 'zoom_in';
        this.sizeBase++;
        let updatedTextSize = this.sizeBase + "%";
        this.textSize = updatedTextSize;
      }
    },

    reducirTamanoDeTexto() {
      this.zoomInOrOut = 'zoom_out';
      this.sizeBase--;
      let updatedTextSize = this.sizeBase + "%";
      this.textSize = updatedTextSize;
    },

    reducirTamanoDeTextoShortCut() {
      if (event.ctrlKey && event.key === "-") {
        this.zoomInOrOut = 'zoom_out';
        this.sizeBase--;
        let updatedTextSize = this.sizeBase + "%";
        this.textSize = updatedTextSize;
      }
    },

    downloadText() {
      const blob = new Blob(
        [this.docs[this.indiceDelDocumentoActivo].textEditor],
        { type: "text/plain" }
      );
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = "seis8s.txt";
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    },

    loadFile(event) {
      const file = event.target.files[0];
      if (file) {
        const reader = new FileReader();
        reader.onload = (e) => {
          this.docs[this.indiceDelDocumentoActivo].textEditor = e.target.result;
        };
        reader.readAsText(file);
      }
    },
    

    cargarImagenDeFondo(event) {
      this.imagenDeFondo = 'image';
      const file = event.target.files[0];
      if (file) {
        const reader = new FileReader();
        reader.onload = (e) => {
          document
            .getElementById("imageSrc")
            .setAttribute("href", e.target.result);
        };
        reader.readAsDataURL(file);
      }
    },
    
    removerImagenDeFondo(){
      this.imagenDeFondo = 'delete';
    document
      .getElementById("imageSrc")
      .setAttribute("href", '');
    }, 
        
    mostrarOpcionSaludos(){
      this.mostrarOpcionesMenuPanelIzquierdo = false;
      this.mostrarTituloPanelIzquierdo = true;
      this.tituloPanelIzquierdo = 'Saludos';
      this.mostrarSaludosContenedor = true;
      this.mostrarAcercaDeContenedor = false;
      this.mostrarTutorialesContenedor = false;
      this.mostrarConexionesMidiContenedor = false;
    }, 
    
    mostrarOpcionAcercaDe(){
      this.mostrarOpcionesMenuPanelIzquierdo = false;
      this.mostrarTituloPanelIzquierdo = true;
      this.tituloPanelIzquierdo = 'Acerca De';
      this.mostrarSaludosContenedor = false;
      this.mostrarAcercaDeContenedor = true;
      this.mostrarTutorialesContenedor = false;
      this.mostrarConexionesMidiContenedor = false;
    }, 
    
    mostrarOpcionTutoriales(){
      this.mostrarOpcionesMenuPanelIzquierdo = false;
      this.mostrarTituloPanelIzquierdo = true;
      this.tituloPanelIzquierdo = 'Tutoriales';
      this.mostrarSaludosContenedor = false;
      this.mostrarAcercaDeContenedor = false;
      this.mostrarTutorialesContenedor = true;
      this.mostrarConexionesMidiContenedor = false;
    }, 
    
    mostrarOpcionMidi(){
      this.mostrarOpcionesMenuPanelIzquierdo = false;
      this.mostrarTituloPanelIzquierdo = true;
      this.tituloPanelIzquierdo = 'MIDI';
      this.mostrarSaludosContenedor = false;
      this.mostrarAcercaDeContenedor = false;
      this.mostrarTutorialesContenedor = false;
      this.mostrarConexionesMidiContenedor = true;
    }, 
    
  convertInput() {
  const refName = 'editorTextArea' + this.indiceDelDocumentoActivo;  // Build the dynamic ref name
  const textArea = this.$refs[refName];   // Access the textarea element via the dynamic ref

  if (textArea) {
    const cursorPosition = textArea.selectionStart; // Save the cursor position
    const originalText = this.docs[this.indiceDelDocumentoActivo].textEditor; // Save original text

    // Modify the text
    this.docs[this.indiceDelDocumentoActivo].textEditor = this.processInput(originalText);

    // Calculate the length difference after modification
    const newText = this.docs[this.indiceDelDocumentoActivo].textEditor;
    const lengthDifference = newText.length - originalText.length;

    // Restore the cursor position, adjusted by the length difference
    this.$nextTick(() => {
      textArea.selectionStart = cursorPosition + lengthDifference;
      textArea.selectionEnd = cursorPosition + lengthDifference;
    });
  } else {
    console.error("Textarea ref not found:", refName);
  }
},

    
     processInput(input) {
  // Split by spaces but keep pipes attached to the next command
  let commands = input.split(' ').map(cmd => {
    if (cmd.startsWith('|')) {
      // Handle the case where there is a pipe before the command
      let commandWithoutPipe = cmd.slice(1);  // Remove the pipe for processing
      return '|' + this.replaceCommand(commandWithoutPipe);  // Reattach the pipe after processing
    } else {
      return this.replaceCommand(cmd);  // Regular replacement
    }
  });
  return commands.join(' ');
},

replaceCommand(command) {
  // Replace commands based on the map
  switch (command) {
    case ':bajo:':
      return '🎸';
    case 'n1':
      return '𝅝';
    case 'n2':
      return '𝅗𝅥';
    case 'n4':
      return '𝅘𝅥';
    case 'n8':
      return '𝅘𝅥𝅮';
    case 'n8n8':
      return '♫';
    case 'n_16':
      return '𝅘𝅥𝅯';
    // silencios
    case 's1':
      return '𝄻';
    case 's2':
      return '𝄼';
    case 's4':
      return '𝄽';
    case 's8':
      return '𝄾';
    case 's_16':
      return '𝄿';
    default:
      return command;  // If no match, return the original command
  }
},

    
    evaluate(){
       try {
       var datosDelPrograma = parser.parse(this.docs[this.indiceDelDocumentoActivo].textEditor);
       i.programa(datosDelPrograma.estadoGlobal, datosDelPrograma.pistas);
       console.log(datosDelPrograma.pistas);
       // this.errorConsole = datosDelPrograma;
       this.errorConsole = "";

     } catch (error) {
       this.errorConsole = "Error:" + error.message;
  }
      
    },
    
  
//     
  }
});

app.mount("#app");

 