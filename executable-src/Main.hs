{-# LANGUAGE RecursiveDo, OverloadedStrings, JavaScriptFFI, FlexibleContexts #-}

module Main where

import System.IO
import Control.Monad.Trans
import Control.Monad.Fix
import Reflex.Dom as Dom hiding (getKeyEvent,preventDefault)
import Data.Time
import Data.Tempo
import Data.Time.Clock.POSIX
import Data.Aeson
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import TextShow
import Control.Concurrent.MVar
import Control.Concurrent
import Data.Map.Strict
import Control.Monad
import GHCJS.DOM.Types (HTMLCanvasElement(..),uncheckedCastTo,JSVal,WebGLRenderingContext)
import JavaScript.Web.AnimationFrame
import GHCJS.Concurrent
import GHCJS.DOM.EventM
import Data.Bool
import Data.Maybe
import Data.Either
import GHCJS.Marshal.Pure
import Language.Javascript.JSaddle (liftJSM, toJSVal)
import GHCJS.Types
import Sound.OSC.Datum
import Data.Text.Encoding
import JavaScript.Object
import qualified Data.Map as Map
import Data.JSString.Text
import qualified Control.Concurrent as Con
import Debug.Trace
import Data.Char as C
import Language.Javascript.JSaddle
import Sound.MusicW

import Sound.Seis8s.Program
import Sound.Seis8s.Layer (Layer, emptyLayer)
import Sound.Seis8s.Parser
import Sound.Seis8s.GlobalMaterial


data RenderState = RenderState {
     t0 :: UTCTime,
     tSystemInit :: UTCTime, -- tSystemInit :: UTCTime,
     tempo :: Tempo,
     pVar :: ([Layer], GlobalMaterial) -- ([emptyLayer], defaultGlobalMaterial)
     }

main :: IO ()
main = do
  hSetBuffering stdout LineBuffering
  tNow <- getCurrentTime -- IO UTC
  wd <- webdirtNode
  initializeWebAudio wd
  mainWidgetWithHead headElement (bodyElement wd) -- IO ()

webdirtNode :: IO WebDirt
webdirtNode = do
  iwdn <- initializeWebDirtNode
  wd <- liftAudioIO $ newWebDirt iwdn
  return wd

headElement :: DomBuilder t m => m ()
headElement = do
  el "title" $ text "Seis8s"
  let attrs = fromList [("rel", "stylesheet"), ("type", "text/css"), ("href", "style.css")]
  -- let attrs2 = fromList [("rel", "stylesheet"), ("type", "text/css"), ("href", "jquery.highlight-within-textarea.css")]
  elAttr "link" attrs $ return ()
  -- elAttr "link" attrs2 $ return ()


intro :: Text
intro = "cumbia teclado;\n\
        \cumbia bajo;\n\
        \cumbia guira;\n\
        \cumbia congas;"

ejemplo2 :: Text
ejemplo2 = " -- cumbia usando el comando acordes \n\
\acordes [re m, fa, la];\n\
\acompanamiento (2 4) $ cumbia teclado;\n\
 \tumbao 2 $ cumbia bajo;\n\
 \cumbia guira;\n\
 \tumbao 3 $ cumbia congas;"


ejemplo3 :: Text
ejemplo3 = "-- cumbia psicodelica  \n\
\acordes [re m, fa, sol, re m]; \n\
\punteo [1a 3a 5a 6a] [1 2 2.5 3 4] $ sample 7 $ cumbia teclado; \n\
\acompañamiento (2 4 4.5) $ sample 2 $ cumbia teclado; \n\
\tumbao [(t a) (t a) (q a) (t a) (t a) (q a), (q p) (q a) (q p) (q a)] [ 1 1.5 2 3 3.5 4, 1 2 3 4] $ congas; \n\
\tumbao [1a 2a 3a 5a, 1a 5a 3a] [1 2 3 4, 1 3 4] $ cumbia bajo; \n\
\ritmo 1 $ jamblock; \n\
\ritmo [1 2 3 4, 1 1.5 2 2.5 3 3.5 4 4.5] $ cumbia guira;"


-- "acordes [re m, fa, la]; \n\
-- \compás \"partido\"; \n\
-- \punteo [3a, 5a] [3, 4, 1 1.5 2 2.5] $ sample 3 $ acordeón;\n\
-- \acompañamiento (2 4) $ vol 0.75 $ teclado; \n\
-- \tumbao 1 $ cumbia bajo; \n\
-- \ritmo [1 2 2.5 3 4 4.5] $ guira;\n\
-- \marcha [p t p a a] [1 2 3 4 4.5] $ pan 0 $ congas;"

-- "alternar 2 (acompanamiento (1 2)) $ acompanamiento (2 4) $ cumbia teclado; \n\
 -- \tumbao 2 $ cumbia bajo;\n\
 -- \cumbia guira;\n\
 -- \tumbao 3 $ cumbia congas;"

ejemplo4 :: Text
ejemplo4 = "-- cumbia psicodelica 2 \n\
\acordes [re m, fa, sol, re m]; \n\
\punteo [3a 5a 6a] [1 2 2.25 2.5 3 4] $ sample 8 $ teclado; \n\
\acompañamiento (4) $ sample 0 $ cumbia teclado; \n\
\alternar 4 (tumbao 0) $ tumbao 1 $ sample 3 $ cumbia bajo; \n\
\vol 0.65 $ cumbia güira; \n\
\tumbao 0 $ cumbia congas;"

ejemplo5 :: Text
ejemplo5 = "--cumbia tejana \n\
\tempo 120;\n\
\acordes [do, sol, fa];\n\
\punteo [1a 5a 6a] [1 2 2.5] $ acordeon; \n\
\tumbao [1a 3a 5a] [1 3 4] $ bajo;\n\
\acompanamiento ( 2  4) $ teclado; \n\
\ritmo [1 2 3 4, 1 1.5 2 2.5 3 3.5 4, 1] $ guira;\n\
\ritmo [1 2 3 4, 2 4] $ cumbia jamblock;\n\
\marcha [(q p) (q p) (q t) (q p) (q p) (q p) (q a) (q a), (q p) (q p) (q t) (q p) (q a) (q p) (t a) (t a)] [1 1.5 2 2.5 3 3.5 4 4.5, 1 1.5 2 2.5 3 3.5 4 4.5] $ congas;"

ejemplo6 :: Text
ejemplo6 = "-- balada cumbia por Kofi Oduro\n\
\tempo 84;\n\
\acordes [re m, la, la, fa, do, do, fa, re m, la, la];\n\
\alternar 5 (acompanamiento (1 2 4)) $ acompanamiento (1 4) $ cumbia teclado; \n\
\acompanamiento (2 3 4 4) $ cumbia teclado;\n\
\sample 4 $ teclado;\n\
\tumbao 5 $ cumbia congas;\n\
\vol 0.825 $ cumbia bajo;\n\
\cumbia guira;"

  -- "alternar 2 (acompanamiento (1 2)) $ acompanamiento (2 4) $ cumbia teclado;\n\
  -- \alternar 2 (tumbao 3) $ tumbao 1 $ cumbia bajo;\n\
  -- \ritmo ([1 1.5 2 2.5 3 3.5 4 4.5]) $ cumbia guira;\n\
  -- \alternar 4 (tumbao 4) $ tumbao 1 $ cumbia congas"

ejemplo7 :: Text
ejemplo7 = "-- balada por Kofi Oduro \n\
\tempo 42; \n\
\acordes [re m, fa,fa, sol, re m, fa, fa, sol, fa,fa]; \n\
\punteo [3a 4a 5a 2a 6a] [1 1.35 2.7 2.25 2.5 3 4.7 5.4] $ sample 8 $ teclado; \n\
\acompanamiento (2) $ sample 1 $ teclado; \n\
\alternar 3 (tumbao 0) $ tumbao 1 $ sample 2 $ bajo; \n\
\vol 0.45 $ tumbao 1 $ guira; \n\
\tumbao 0 $ congas;"

ejemplo8 :: Text
ejemplo8 = "-- son cubano \n\
\acordes [do, do, do, do, fa, fa, fa, fa]; \n\
\tumbao [\"1a\" \"5a\", \"5a\" (\"1a\" 1),1a 5a, 5a 1a] [1 4, 1 3, 1 4, 1 4] $ sample 4 $ bajo;\n\
\punteo [1a 3a 5a, 6a 1a, 3a 5a, 6a 1a ] [1 3 4, 2 4, 2 4, 2 4] $ sample 1 $ teclado;\n\
\marcha [p p t p, p p a a, p p t (t a), p p (t a) (t a)] [1 2 3 4, 1 2 3 4, 1 2 3 4, 1 2 3 4] $ congas; \n\
\jamblock;"

ejemplo9 :: Text
ejemplo9 = "-- salsa suave \n\
\tempo 180; \n\
\compas \"4/4\"; \n\
\acordes [do m, do m , do m, re dim ]; \n\

\tumbao 0 $ sample 1 $ teclado; \n\
\tumbao [1a 5a 1a, 5a  1a] [1 2.5 4, 2.5 4] $ sample 4 $ bajo;\n\
\marcha [p p t p p p a a] [1 1.5 2 2.5 3 3.5 4 4.5] $  congas;\n\
\preset 1  $ cumbia clave;\n\
\ritmo [ 2 4 ] $ guira"

-- "punteo [\"3a\", \"5a\"] [3, 4, 1 1.5 2 2.5 ]$ sample 3 $ cumbia teclado;\n\
-- \alternar 2 (acompanamiento (1 2)) $ acompanamiento (2 4) $ cumbia teclado; \n\
-- \tumbao 2 $ cumbia bajo; \n\
-- \cumbia guira; \n\
-- \tumbao 3 $ cumbia congas; \n"

ejemplo10 :: Text
ejemplo10 = "-- salsa rápida \n\
\tempo 108;\n\
\armonia [re m];\n\

\vol 0.8 $ punteo [3a 4a 5a] [1 2.5 3.5 4, 4] $ sample 1 $ teclado;\n\

\alternar 2 (acompanamiento (2.5 3.5)) $ acompanamiento (1 2 3.5 4.5) $ sample 0 $ teclado;\n\
\tumbao [\"1a\" \"5a\" (\"1a\" 1), \"5a\"  \"1a\"] [1 2.5 4, 2.5 4] $ sample 5 $ bajo;\n\
\marcha [p p t p p p a a] [1 1.5 2 2.5 3 3.5 4 4.5] $ congas;\n\
\preset 1  $ clave;"

-- "acordes [re m, fa, la];\n\
-- \punteo [\"3a\", \"5a\"] [3, 4, 1 1.5 2 2.5 ]$ sample 3 $ cumbia teclado;\n\
--  \alternar 2 (acompanamiento (1 2)) $ acompanamiento (2 4) $ cumbia teclado; \n\
--  \alternar 2 (acompanamiento (1 2)) $ acompanamiento (2 4) $ cumbia teclado;\n\
--  \alternar 2 (tumbao 3) $ tumbao 1 $ cumbia bajo;\n\
--  \ritmo ([1 1.5 2 2.5 3 3.5 4 4.5]) $ cumbia guira;\n\
--  \alternar 4 (tumbao 4) $ tumbao 1 $ cumbia congas"


navigateExamples :: Int -> Text
navigateExamples 0 = intro
navigateExamples 1 = ejemplo2
navigateExamples 2 = ejemplo3
navigateExamples 3 = ejemplo4
navigateExamples 4 = ejemplo5
navigateExamples 5 = ejemplo6
navigateExamples 6 = ejemplo7
navigateExamples 7 = ejemplo8
navigateExamples 8 = ejemplo9
navigateExamples 9 = ejemplo10
otherwise = intro

navigateExamplesWidget :: MonadWidget t m => Event t () -> m (Event t Text)
navigateExamplesWidget evButton = do
  numbs <- foldDyn (+) (0 :: Int)  (1 <$ evButton) -- Dynamic Int
  let numbs' = fmap (\n -> mod n 10) numbs -- Dynamic Int
  let codeExamples = fmap navigateExamples numbs' -- Dynamic Text
  return $ updated codeExamples -- Event Text

attrsForGeneralInfo :: Bool -> Map.Map T.Text T.Text
attrsForGeneralInfo b = visibility b
  where visibility True = "class" =: "contenedorTextoIntro"
        visibility False = "class" =: "contenedorTextoIntro" <> "style" =: "display: none"


logDisplay :: Bool -> T.Text
logDisplay b = dis b
  where dis True = "True"
        dis False = "False"

bodyElement :: MonadWidget t m => WebDirt -> m ()
bodyElement wd =  do
  mv <- liftIO $ forkRenderThreads wd
  -- divClass "titulo" $ do
    -- text "Seis8s"
    -- elAttr "a" ("href" =: "https://l.facebook.com/l.php?u=https%3A%2F%2Finstagram.com%2Fmariapaula.jg%3Figshid%3Dpnjbzfn31ugn%26fbclid%3DIwAR1nvWI1UKeRIvdkzYVsFICxaQee2cVjQLS4IbQc2DdnvbhOkwvT4tZbTH4&h=AT3JFjrz0ZtST7h4CFALdMsX7L2ZB9VEN0UegRPOFAYMACdy79unNDgDAHkIeHgjP4E1Z3hOgOGoguTiyOwK81ZsVdf_DwY9V-rqgmkbbmtrnEh6_NqKnCHIp7z20g") (text "Imágen por / background art by: @mariapaula.jg")


  elClass "div" "contenedorPrincipal" $ mdo
    dynBoolForInfo <- toggle True evClickInfo
    let dynAttrsForGeneralInfo = attrsForGeneralInfo <$> dynBoolForInfo
    elDynAttr "div" dynAttrsForGeneralInfo $ do
      divClass "titulo" $ text "Seis8s"
      tabDisplay "botonesDeIdioma" "botonesDeIdiomaListItems" tabMapEscogerIdioma

    (evClickPlay, evClickStop, evClickInfo, examplesButton) <- elClass "div" "editor" $ mdo
      (evClickPlay', evClickStop', evClickInfo', examplesButton') <- divClass "playEinstrucciones" $ do
        evClickInfo'' <- divClass "infoButton" $ button "?"
        examplesButton'' <- divClass "examplesButton" $ button "ⓔ"
        evClickStop'' <- divClass "stopButton" $ button "■" -- ([emptyLayer], defaultGlobalMaterial)
        evClickPlay'' <- divClass "playButton" $ button "▶"
        consoleInfo' <- holdDyn "Haz sonar el código presionando el botón ▶ | Make the code sound by pressing the ▶ button" consoleInfo
        divClass "consoleInfo" $ dynText $ fmap T.pack consoleInfo'
        return (evClickPlay'', evClickStop'', evClickInfo'', examplesButton'')
    --
      consoleInfo <- divClass "textAreaEditor" $ do
        let textAttrs = constDyn $ fromList [("class", "maineditor"){--("class", "class-example"),--}]
        code <- do
          -- voiceButton <- divClass "infoButton" $ button "speak"
          -- let evText = tagPromptlyDyn (constDyn "test") voiceButton
          -- someText <- holdDyn "" evText
          -- liftIO $ jq_highlight_brackets
          -- numbs <- foldDyn (+) (0 :: Int)  (1 <$ examplesButton) -- Dynamic Int
          -- let codeExamples = fmap navigateExamples numbs -- Dynamic Text
          navigateExamplesWidget' <- navigateExamplesWidget examplesButton
          textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  intro & textAreaConfig_setValue .~ navigateExamplesWidget'
        e <- _element_raw . fst <$> el' "div" blank -- script or text
        let evaled = tagPromptlyDyn (_textArea_value code) evClickPlay -- Event t Text
        let stopSound = tagPromptlyDyn (constDyn "silencio") evClickStop -- Event t Text
        consoleInfo' <- performEvaluate' mv $ leftmost [evaled, stopSound] -- performEvaluate' pVar evaled
        return consoleInfo'

-- Saludos!
      -- divClass "contenedorDeSaludos" $ do
      --   let textAttrsEditorDeSaludos = constDyn $ fromList [("class", "editorDeSaludos")]
      --   t <- textArea $ def & textAreaConfig_attributes .~ textAttrsEditorDeSaludos
      -- -- &  textAreaConfig_initialValue .~  intro & textAreaConfig_setValue .~ navigateExamplesWidget'
      --   evClickVoice <- button "Saludar"
      --   let evaled = tagPromptlyDyn (_textArea_value t) evClickVoice -- Event t Text
      --   performEvent_ $ ffor evaled $ \text -> liftJSM $ do
      --     jsT <- toJSVal text
      --     js_speechSynthesis jsT
      return (evClickPlay', evClickStop', evClickInfo', examplesButton')
      -- MIDI !
    -- liftIO $ enableMidi
    return ()

-- foreign import javascript safe
--   "console.log $1"
--   testSet :: JSVal -> IO()

-- testTB :: MonadWidget t m => Dynamic t T.Text -> m ()
-- testTB dt = do
--     let bob :: Dynamic t (IO ())
--         bob = (testSet.(pToJSVal)) <$> dt
--
--         bobIOEvent :: Event t (IO ())
--         bobIOEvent = updated bob
--
--         bobWidgetHostEvent :: Event t (WidgetHost m ())
--         bobWidgetHostEvent = fmap liftIO bobIOEvent
--
--     performEvent_ bobWidgetHostEvent

-- performEvaluate' :: (PerformEvent t m, MonadIO (Performable m)) => MVar ([Layer], GlobalMaterial) -> Event t Text -> m ()
performEvaluate' :: (PerformEvent t m, MonadIO (Performable m)) => MVar RenderState -> Event t Text -> m (Event t String)
performEvaluate' mv e = performEvent $ ffor e $ \textAreaCode -> liftIO $ do
  let p = parseLang $ T.unpack textAreaCode
  let
  case p of
    Right x -> do
      tNow <- getCurrentTime
      rs <- takeMVar mv
      putMVar mv $ rs {
        pVar = x
      }
      return ""
    Left x -> return $ "error: " ++ x


forkRenderThreads :: WebDirt -> IO (MVar RenderState)
forkRenderThreads wd = do
  tNow <- liftIO getCurrentTime
  mv <- newMVar $ RenderState {
       tSystemInit = tNow,
       t0 = tNow,
       tempo = Tempo {freq = 0.50, time=tNow, Data.Tempo.count=0},
       pVar = ([emptyLayer], defaultGlobalMaterial)
       }
  forkIO $ renderThread wd mv -- tNow evalT tempo wd pVar
  return mv

-- renderThread :: UTCTime -> UTCTime -> Tempo -> WebDirt -> MVar ([Layer], GlobalMaterial) -> IO ()
-- renderThread t0 evalT tempo wd pVar = do
renderThread :: WebDirt -> MVar RenderState ->  IO ()
renderThread wd mv  =  do
  mv' <- takeMVar mv
  mv'' <- renderer wd mv'
  putMVar mv mv''
  -- threadDelay 100000
  let renderEnd = (t0 mv'') -- (t0 mv'')
  let targetWakeUpTime = addUTCTime (-0.1) renderEnd
  tNow <- liftIO $ getCurrentTime --currentTime
  let diff = diffUTCTime targetWakeUpTime tNow
  when (diff > 0) $ liftIO $ threadDelay $ floor $ realToFrac $ diff * 1000000
  renderThread wd mv


renderer :: WebDirt -> RenderState -> IO RenderState
renderer wd mv = do
  let iw = t0 mv
  let ew = addUTCTime (0.1 :: NominalDiffTime) iw
  let rend = renderForStandalone (pVar mv) iw ew  --render (fromJust $ pVar mv) (tempo mv) iw ew --  [Event],  i.e. Event = (UTCTime, M.Map T.Text Datum)
  let singleJSValevents = fmap (\(u, m) -> ((realToFrac $ utcTimeToPOSIXSeconds u) + 0.0, fmap datumToJSVal m)) (fst rend)-- (realToFrac $ diffUTCTime u (tSystemInit mv),  fmap datumToJSVal m)) (fst rend) -- [IO JSVal]
  renderedCodes <- sequence $ fmap mapTextJSValToJSVal singleJSValevents -- IO [JSVal]
  sequence_ $ fmap (\r -> playSample wd r) renderedCodes -- [IO ()] -> IO ()
  return $ mv {t0 = ew, tempo = snd rend} -- mv {t0 = ew, tempo = snd rend}


tabMapEscogerIdioma :: MonadWidget t m => Map.Map Int (Text, m ())
tabMapEscogerIdioma = Map.fromList[ (1, ("Español", tabMapEspanol')),
            (2, ("English", tabMapEnIngles'))]

tabMapEspanol' ::  MonadWidget t m => m ()
tabMapEspanol' = do
  tabDisplay "menuButtons" "menuContentContainer" tabMapEspanol
  return ()

tabMapEnIngles' ::  MonadWidget t m => m ()
tabMapEnIngles' = do
  tabDisplay "menuButtons" "menuContentContainer" tabMapEnIngles
  return ()

tabMapEspanol :: MonadWidget t m => Map.Map Int (Text, m ())
tabMapEspanol  = Map.fromList[ (1, ("Sobre Seis8s", descripcion)), (2, ("Referencia", referencia)), (3, ("Agradecimientos", agradecimientos))]
            --(2, ("Canal de Discord", discordEspanol), (3, ("Ejemplos", ejemplos)), (4, ("Referencia", referencia)), (5, ("Agradecimientos", agradecimientos))]

tabMapEnIngles :: MonadWidget t m => Map.Map Int (Text, m ())
tabMapEnIngles  = Map.fromList[ (1, ("About Seis8s", description)), (2, ("Reference", reference)),  (3, ("Acknowledgements", acknowledgements))]
            -- (2, ("Discord Channel", discordEnglish), (3, ("Examples", examples)), (4, ("Reference", reference)), (5, ("Acknowledgements", acknowledgements))]

discordEspanol :: MonadWidget t m => m ()
discordEspanol = divClass "discord" $ do
  text "Unete al grupo de Discord: "
  elAttr "a" ("href" =: "https://discord.gg/ygEPS8tzzz") (text "https://discord.gg/ygEPS8tzzz")
  blank
  text "Contacto: navarrol@mcmaster.ca"
  -- el "br" $ blank
  -- text $ "Y deja un mensaje abajo! "
  -- liftJSM $ eval ("window.addEventListener('load',function() { \n\
  --     \commentBox('5731344961241088-proj'); \n\
  --     \});" :: String)
  return ()


discordEnglish :: MonadWidget t m => m ()
discordEnglish = divClass "discord" $ do
  text "Join the discord group: "
  elAttr "a" ("href" =: "https://discord.gg/ygEPS8tzzz") (text "https://discord.gg/ygEPS8tzzz")
  blank
  text "Contact: navarrol@mcmaster.ca"

  -- el "br" $ blank
  -- text $ "And leave a message below! "
  -- liftJSM $ eval ("window.addEventListener('load',function() { \n\
  --     \commentBox('5731344961241088-proj'); \n\
  --     \});" :: String)
  return ()

agradecimientos :: MonadWidget t m => m ()
agradecimientos = divClass "textoIntro" $ do
  text "Este proyecto es parte de mi doctorado llamado 'Plataformas culturalmente situadas de música por computadora y es apoyada por el Fondo Mexicano para la Cultura y las Artes (FONCA), el Consejo Mexicano de Ciencia y Tecnología (CONACYT) y el Consejo de Investigación de Ciencias Sociales y Humanidades de Canadá."
  divClass "contacto" $ do
    text "Agradecimientos especiales a"
    elAttr "a" ("href" =: "https://l.facebook.com/l.php?u=https%3A%2F%2Finstagram.com%2Fmariapaula.jg%3Figshid%3Dpnjbzfn31ugn%26fbclid%3DIwAR1nvWI1UKeRIvdkzYVsFICxaQee2cVjQLS4IbQc2DdnvbhOkwvT4tZbTH4&h=AT3JFjrz0ZtST7h4CFALdMsX7L2ZB9VEN0UegRPOFAYMACdy79unNDgDAHkIeHgjP4E1Z3hOgOGoguTiyOwK81ZsVdf_DwY9V-rqgmkbbmtrnEh6_NqKnCHIp7z20g") (text "@mariapaula.jg")
    divClass "contacto" $ text "por la imágen que aparece detrás del editor."
  divClass "contacto" $ text "Contáctame a traves de navarrol@mcmaster.ca"


acknowledgements :: MonadWidget t m => m ()
acknowledgements = divClass "textoIntro" $ do
  text "This project is part of my doctoral project called 'Culturally situated platforms for computer music' and is supported by the Mexican Fund for Culture and Arts (FONCA), the Mexican Council of Science and Technology (CONACYT), and Canada’s Social Sciences and Humanities Research Council."
  divClass "contacto" $ do
    text "Special thanks to"
    elAttr "a" ("href" =: "https://l.facebook.com/l.php?u=https%3A%2F%2Finstagram.com%2Fmariapaula.jg%3Figshid%3Dpnjbzfn31ugn%26fbclid%3DIwAR1nvWI1UKeRIvdkzYVsFICxaQee2cVjQLS4IbQc2DdnvbhOkwvT4tZbTH4&h=AT3JFjrz0ZtST7h4CFALdMsX7L2ZB9VEN0UegRPOFAYMACdy79unNDgDAHkIeHgjP4E1Z3hOgOGoguTiyOwK81ZsVdf_DwY9V-rqgmkbbmtrnEh6_NqKnCHIp7z20g") (text "@mariapaula.jg")
    divClass "contacto" $ text "for the editor's background image."
  divClass "contacto" $ text "To contact me, send me an email to navarrol@mcmaster.ca"


descripcion :: MonadWidget t m => m ()
descripcion = divClass "textoIntro" $ do
 divClass "descripcion" $ text "Seis8s es un lenguaje informático basado en la web que permite la interacción en tiempo real con audio digital y conocimientos musicales localizados. Seis8s gira en torno a comandos que se relacionan con la música latina bailable, también conocida como música latina urbana o música popular latina. Si deseas saber más, agregate al canal de Discord de Seis8s:"
 elAttr "a" ("href" =: "https://discord.gg/ygEPS8tzzz") (text "https://discord.gg/ygEPS8tzzz")
 elClass "h3" "empiezaAquiTitulo" $ text "¿Cómo usar Seis8s?"
 elClass "ol" "empiezaAqui" $ do
   el "li" $ text "Presiona ▸ para tocar el código de ejemplo que aparece en el editor a la derecha. Presiona ■ para detenerlo."
   el "li" $ text "Explora más ejemplos presionando ⓔ y después presionando ▸ para tocar cada ejemplo."
   el "li" $ text "Aprende cómo modificar los ejemplos o crear un nuevo código consultando la sección de Referencia en el menú de arriba."

 -- text "seis8s (pronunciado 'seis octavos') es un lenguaje de programación que permite la interacción en tiempo real con audio digital y conocimiento musical localizado, particularmente de músicas de Latinoamérica. Seis8s es un proyecto reciente que pretende ser colaborativo, a través de conocimiento musical consensuado desde las diferentes fronteras personales y colectivas que existen en conexión con América Latina. Seis8s también espera ser una crítica ideológica del sistema mundial de música por computadora dominante en lugar de una abstracción acrítica de las distintas visiones del mundo. El primer 'módulo' de seis8s produce música influenciada por la cumbia sonidera, un estilo particular de la clase trabajadora mexicana en México y Estados Unidos. Para obtener más información sobre Cumbia sonidera, consulte el libro "
 -- elAttr "a" ("href" =: "http://beyond-digital.org/sonideros/EPS%20Libro-%20Sonideros%20en%20las%20aceras,%20vengase%20la%20gozadera%20-%20PDFvert.pdf") (text "Sonideros en las aceras, véngase a gozadera.")
 return ()
   -- text "También puedes unirte al grupo de Discord para continuar la conversación y preguntar cosas:"
   -- link "https://discord.gg/ygEPS8tzzz"
   -- return ()


description :: MonadWidget t m => m ()
description = divClass "textoIntro" $ do
  text "Seis8s is a web-based computer language that allows real-time interaction with digital audio and localized musical knowledge. Seis8s revolves around commands that relate to Latin dance music –also known as urban Latin music or Latin popular music. Join Seis8s' Discord channel to know more:"
  elAttr "a" ("href" =: "https://discord.gg/ygEPS8tzzz") (text "https://discord.gg/ygEPS8tzzz")
  elClass "h3" "empiezaAquiTitulo" $ text "How to start using Seis8s?"
  elClass "ol" "empiezaAqui" $ do
    el "li" $ text "Click ▸ to play the example code from the editor on the right. Click ■ to stop the sound."
    el "li" $ text "Explore more examples by clicking ⓔ and ▸ to play the example."
    el "li" $ text "Learn how to modify the examples or create your own code by consulting the Reference section on the menu above."

  -- text "seis8s (pronounced 'seis octavos') is a programming language that allows real-time interaction with digital audio and localized musical knowledge, particularly of Latin American music. Seis8s is a recent project that aims to be collaborative, through consensual musical knowledge from the different personal and collective borders that exist in connection with Latin America. Six8s also hopes to be an ideological critique of the dominant world computer music system rather than an uncritical abstraction of various worldviews. The first 'module' of six8s produces music influenced by the cumbia sonidera, a particular style of the Mexican working class in Mexico and the United States. For more information on Cumbia sonidera, see the book "
  -- elAttr "a" ("href" =: "http://beyond-digital.org/sonideros/EPS%20Libro-%20Sonideros%20en%20las%20aceras,%20vengase%20la%20gozadera%20-%20PDFvert.pdf") (text "Sonideros en las aceras, véngase a gozadera.")
  return ()

  -- text "You can also join the Discord group to continue the conversation and ask questions:"
  -- link "https://discord.gg/ygEPS8tzzz"
  -- return ()



ejemplos :: MonadWidget t m => m ()
ejemplos = divClass "ejemplosCss" $ do
  text "Copie cualquiera de los siguientes bloques de código y péguelo en el editor de texto de la derecha. Hazlo sonar presionando el boton ▶."
  text "Para silenciar los sonidos borra tu código y vuelve a presionar el botón ▶."
  let textAttrs = constDyn $ fromList [("class", "ejemCode")]
  let textAttrs' = constDyn $ fromList [("class", "ejemCodeLargo")]

  -- liftIO $ jq_highlight_brackets
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ intro -- text
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ ejemplo2 -- text
  textArea $ def & textAreaConfig_attributes .~ textAttrs' &  textAreaConfig_initialValue .~ ejemplo3 -- text
  textArea $ def & textAreaConfig_attributes .~ textAttrs' &  textAreaConfig_initialValue .~ ejemplo4 -- text
  textArea $ def & textAreaConfig_attributes .~ textAttrs' &  textAreaConfig_initialValue .~ ejemplo5 -- text
  textArea $ def & textAreaConfig_attributes .~ textAttrs' &  textAreaConfig_initialValue .~ ejemplo6 -- text
  textArea $ def & textAreaConfig_attributes .~ textAttrs' &  textAreaConfig_initialValue .~ ejemplo7 -- text
  return ()


examples :: MonadWidget t m => m ()
examples = divClass "ejemplosCss" $ do
  text "Copy any of the following code blocks and paste it into the text editor on the right. Make it sound by pressing the ▶ button."
  text $ "To silence the sounds, delete your code and press the ▶ button again (it will take a few seconds to stop, but if it doesn't stop, please reload the webpage)."
  let textAttrs = constDyn $ fromList [("class",  "ejemCode")]
  let textAttrs' = constDyn $ fromList [("class",  "ejemCodeLargo")]
  -- liftIO $ jq_highlight_brackets
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ intro -- text
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ ejemplo2 -- text
  textArea $ def & textAreaConfig_attributes .~ textAttrs' &  textAreaConfig_initialValue .~ ejemplo3 -- text
  textArea $ def & textAreaConfig_attributes .~ textAttrs' &  textAreaConfig_initialValue .~ ejemplo4 -- text
  return ()


referencia :: MonadWidget t m => m ()
referencia = divClass "referenciaCss" $ do
  text "Prueba seis8s escribiendo el siguiente código: "
  let textAttrs = constDyn $ fromList [("class",  "refCode")]
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "cumbia bajo;"
  text "Hazlo sonar presionando el boton ▶. Una vez que lo ejecutes, ¡debes escuchar el sonido de un bajo con el ritmo base de la cumbia!"

  el "h3" $ text "Instrumentos"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "teclado; congas; jamblock; guira; bajo;"
  text "Para silenciar los sonidos borra todo el código y ejecuta de nuevo. Tambien puedes utilizar el comando:"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "silencio"

  el "h3" $ text "Sintaxis_básica"
  text "La función de estilo se coloca a la izquierda del instrumento: "
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "cumbia teclado;"
  text "Todas las funciones que modifican el estilo se agregan a la izquierda del instrumento seguidas de un paréntesis o un signo de peso '$': "
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompañamiento 2 (cumbia teclado);"
  text "El signo $ es equivalente a los paréntesis: "
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompañamiento 2 $ cumbia teclado;"
  text "Para silenciar los sonidos puedes utilizar el comando:"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "silencio"

  el "h3" $ text "Funciones_del_bajo"
  divClass "imagen-bajo" $ return ()
  elClass "span" "comandosCss" $ text "sample "
  text "permite cambiar la muestra de audio o sample. Acepta números enteros iguales o mayores que 0. Hay 4 pre-sets disponibles."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "sample 0 $ cumbia bajo;"
  elClass "span" "comandosCss" $ text "tumbao "
  text "permite accessar a los distintos pre-sets del bajo. Acepta números enteros iguales o mayores que 0."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao 1 $ cumbia bajo;"
  text "Con la función "
  elClass "span" "comandosCss" $ text "tumbao "
  text $ "también puedes sobreescribir las notas de los tumbaos."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao (\"1a\" \"3a\" \"5a\") $ cumbia bajo;"
  text "También puedes reesecribir los ritmos de los tumbaos."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao (\"1a\" \"5a\") (1 3) $ cumbia bajo;"
  text "También se pueden hacer listas de notas y ritmos de la siguiente forma: "
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao [\"1a\" \"5a\", \"1a\" \"3a\" \"5a\"] [1 3, 1 3 4] $ cumbia bajo;"

  el "h3" $ text "Funciones_del_teclado"
  divClass "imagen-teclado" $ return ()
  elClass "span" "comandosCss" $ text "sample "
  text "permite cambiar la muestra de audio o sample. Acepta números enteros iguales o mayores que 0."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "sample 1 $ cumbia teclado;"
  elClass "span" "comandosCss" $ text "tumbao "
  text "permite accessar a los distintos pre-sets del teclado como lo hicimos con el bajo arriba. Acepta números enteros iguales o mayores que 0."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao 2 $ cumbia teclado;"
  elClass "span" "comandosCss" $ text "acompanamiento "
  text "o "
  elClass "span" "comandosCss" $ text "acompañamiento "
  text "modifica el ritmo en el que se tocan los acordes o bloques de notas del teclado."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompanamiento 2 $ cumbia teclado;"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompanamiento (2 4) $ cumbia teclado;"
  text "También sirve para modificar las notas del teclado. Acepta hasta un máximo de 4 notas."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  "acompanamiento 2 (\"1a\" \"3a\" \"5a\") $ cumbia teclado;"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  "acompanamiento (2 4) (\"1a\" \"3a\" \"5a\")"
  text "También se puede modificar la octava de la nota, es decir que tan grave o agudo suena."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompanamiento 2 (\"1a\" \"3a\" (\"5a\" 1)) $ cumbia teclado;"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompanamiento 2 (\"1a\" \"3a\" (\"5a\" (-1)) $ cumbia teclado;"

  el "h3" $ text "Funciones_de_las_congas"
  divClass "imagen-congas" $ return ()
  elClass "span" "comandosCss" $ text "tumbao "
  text "permite accessar a los distintos pre-sets de las congas como lo hicimos con teclado y el bajo arriba. Acepta números enteros iguales o mayores que 0. Hay 4 disponibles."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao 4 $ cumbia congas;"
  elClass "span" "comandosCss" $ text "marcha "
  text $ "permite asignar los golpes de la palma, tapado y abierto a las congas. Por default suena el tambor quinto de la conga"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "marcha (\"p\" \"t\" \"p\" \"a\") $ cumbia congas;"
  text $ "También permite escribir el rimto de las congas."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "marcha (\"p\" \"t\" \"p\" \"a\" \"a\") (1 2 3 4 4.5) $ cumbia congas;"
  text $ "También permite accesar a otros tambores de las congas como la tumbadora."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "marcha (\"p\" \"t\" \"p\" (t \"a\") (t \"a\")) (1 2 3 4 4.5) $ cumbia congas;"
  text "También se pueden hacer listas de notas y ritmos de la siguiente forma."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "marcha [\"p\" \"t\" \"p\" \"a\", \"p\" \"t\" \"p\" (t \"a\") (t \"a\")] [1 2 3 4, 1 2 3 4 4.5] $ cumbia congas;"

  el "h3" $ text "Funciones_de_la_guira"
  divClass "imagen-guira" $ return ()
  elClass "span" "comandosCss" $ text "preset "
  text " permite accesar a algunos ritmos pre-cargados de la guira. Hay 2 disponibles."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  "preset 0 $ cumbia guira;"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  "preset 1 $ cumbia guira;"

  el "h3" $ text "Funciones_del_jamblock"
  divClass "imagen-jam" $ return ()
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  "cumbia jamblock;"
  text "Más funciones vienen en camino!"

  return ()


reference :: MonadWidget t m => m ()
reference = divClass "referenciaCss" $ do
  text "Try seis8s by writing the following code: "
  let textAttrs = constDyn $ fromList [("class",  "refCode")]
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "cumbia bajo;"
  text "Make it sound by pressing the ▶ button. Once you play it you should hear the sound of a bass with the base rhythm of the cumbia!"

  el "h3" $ text "Instruments"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "teclado; congas; jamblock; guira; bajo;"
  text "To silence the sounds you can use the command: "
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "silencio"

  el "h3" $ text "Basic syntax"
  text "The style function is placed to the left of the instrument: "
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "cumbia teclado;"
  text "All the functions that modify the style are added to the left of the instrument followed by a parenthesis or a '$' sign: "
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompañamiento 2 (cumbia teclado);"
  text "The $ sign is equivalent to parentheses: "
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompañamiento 2 $ cumbia teclado;"
  text "To silence the sounds you can use the command: "
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "silencio"

  el "h3" $ text "Bass functions"
  divClass "imagen-bajo" $ return ()
  elClass "span" "comandosCss" $ text "sample "
  text "allows you to change the audio sample or sample. Accepts whole numbers equal to or greater than 0. There are 4 pre-sets available."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "sample 0 $ cumbia bajo;"
  elClass "span" "comandosCss" $ text "tumbao "
  text "allows access to the different bass pre-sets. Accepts whole numbers equal to or greater than 0."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao 1 $ cumbia bajo;"
  text "With the function "
  elClass "span" "comandosCss" $ text "tumbao "
  text $ "you can also overwrite the notes of the tumbaos.s"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao (\"1a\" \"3a\" \"5a\") $ cumbia bajo;"
  text "You can also rewrite the rhythms of the tumbaos."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao (\"1a\" \"5a\") (1 3) $ cumbia bajo;"
  text "Note and rhythm lists can also be made as follows:  "
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao [\"1a\" \"5a\", \"1a\" \"3a\" \"5a\"] [1 3, 1 3 4] $ cumbia bajo;"

  el "h3" $ text "Functions of the keyboard"
  divClass "imagen-teclado" $ return ()
  elClass "span" "comandosCss" $ text "sample "
  text "allows you to change the audio sample or sample. Accepts whole numbers equal to or greater than 0."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "sample 1 $ cumbia teclado;"
  elClass "span" "comandosCss" $ text "tumbao "
  text "allows you to access the different keyboard pre-sets as we did with the bass on top. Accepts whole numbers equal to or greater than 0."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao 2 $ cumbia teclado;"
  elClass "span" "comandosCss" $ text "acompanamiento "
  text "o "
  elClass "span" "comandosCss" $ text "acompañamiento "
  text "changes in rhythm chords of the keyboard."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompanamiento 2 $ cumbia teclado;"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompanamiento (2 4) $ cumbia teclado;"
  text "It is also used to modify the notes on the keyboard. Accept up to a maximum of 4 notes."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  "acompanamiento 2 (\"1a\" \"3a\" \"5a\") $ cumbia teclado;"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  "acompanamiento (2 4) (\"1a\" \"3a\" \"5a\")"
  text "You can also modify the octave of the note, that is, how low or high it sounds."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompanamiento 2 (\"1a\" \"3a\" (\"5a\" 1)) $ cumbia teclado;"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "acompanamiento 2 (\"1a\" \"3a\" (\"5a\" (-1)) $ cumbia teclado;"

  el "h3" $ text "Conga functions"
  divClass "imagen-congas" $ return ()
  elClass "span" "comandosCss" $ text "tumbao "
  text "allows you to access the different pre-sets of the congas as we did with the keyboard and the bass on top. Accepts whole numbers equal to or greater than 0. There are 4 available."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "tumbao 4 $ cumbia congas;"
  elClass "span" "comandosCss" $ text "marcha "
  text $ "allows you to assign the hits of the palm, covered and open to the congas. By default the fifth drum of the conga plays."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "marcha (\"p\" \"t\" \"p\" \"a\") $ cumbia congas;"
  text $ "It also allows you to write the rhythm of the congas."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "marcha (\"p\" \"t\" \"p\" \"a\" \"a\") (1 2 3 4 4.5) $ cumbia congas;"
  text $ "It also allows access to other conga drums such as the tumbadora."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "marcha (\"p\" \"t\" \"p\" (t \"a\") (t \"a\")) (1 2 3 4 4.5) $ cumbia congas;"
  text "Note and rhythm lists can also be made as follows."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~ "marcha [\"p\" \"t\" \"p\" \"a\", \"p\" \"t\" \"p\" (t \"a\") (t \"a\")] [1 2 3 4, 1 2 3 4 4.5] $ cumbia congas;"

  el "h3" $ text "Functions of te güira"
  divClass "imagen-guira" $ return ()
  elClass "span" "comandosCss" $ text "preset "
  text "allows you to access some pre-loaded rhythms of the guide. There are 2 available."
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  "preset 0 $ cumbia guira;"
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  "preset 1 $ cumbia guira;"

  el "h3" $ text "Funciones_del_jamblock"
  divClass "imagen-jam" $ return ()
  textArea $ def & textAreaConfig_attributes .~ textAttrs &  textAreaConfig_initialValue .~  "cumbia jamblock;"
  text "More functions are coming on their way!"
  return ()

-- foreign import javascript safe
--   -- "document.querySelector('#estuary-root')"
--   -- "$('.array-example').highlightWithinTextarea({highlight: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']});"
--   "function myFunction() { \n\
--     \document.getElementById(\"myTextarea\").select(); \n\
--   \}"
--   js_arrayexample :: IO JSVal
--
-- newtype JQuery = JQuery JSVal
-- -- newtype Event = Event JSVal
--
-- foreign import javascript unsafe
--   "jQuery(document).ready(function(){$('textarea').select()});"
--   jq_select  ::  IO JQuery

--
-- foreign import javascript unsafe -- "$('.array-example').highlightWithinTextarea({highlight: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']});"
--   "jQuery(document).ready(function(){$('.class-example').highlightWithinTextarea({\n\
--   \highlight: [{highlight: ['$', '--', '(', ')', '[', ']'], className: 'green' }, \n\
--   \{highlight: [ ' '],   className: 'black'}, \n\
--   \{highlight: [ 'cumbia'],   className: 'vino'}, \n\
--   \{highlight: [ 'alternar', 'tumbao', 'ritmo', 'acompanamiento', 'acompañamiento', 'marcha', 'punteo', 'sample'],   className: 'red'}, \n\
--   \{highlight: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],   className: 'green'}, \n\
--   \{highlight: ['teclado', 'bajo', 'guira', 'guiro', 'güira', 'güiro', 'jam', 'congas', 'acordeon', 'silencio']},  \n\
--   \{highlight: ['acordes', 'armonia', 'armonía', 'compas', 'compás'], className: 'yellow'}]  \n\
--   \})});"
--   jq_highlight_brackets :: IO JQuery
--   -- \, {highlight: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']}] \n\

  -- "jQuery(document).ready(function(){$('.class-example').highlightWithinTextarea({\n\
  -- \highlight: [{highlight: '$' , className: 'red' }, \n\
  -- \{highlight: '(',   className: 'red'}, {highlight: ')',  className: 'red'}, \n\
  -- \{highlight: '[',  className: 'blue'}, {highlight: ']',   className: 'blue'}, \n\
  -- \{highlight: ['teclado', 'bajo', 'guira', 'jam', 'congas', 'acordeon']}]  \n\
  -- \})});"

-- foreign import javascript unsafe -- $('.array-example').highlightWithinTextarea({highlight: ['orange', /ba(na)*/gi, [0, 5] ]});
--   "jQuery(document).ready(function(){$('.array-example').highlightWithinTextarea({\n\
--   \highlight: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']})});"
--   jq_highlight_numbers :: IO JQuery


type NoteEvent = (UTCTime, Map Text Datum)

datumToJSVal :: Datum -> JSVal
datumToJSVal (Int32 x) = pToJSVal x
datumToJSVal (Double x) = pToJSVal x
datumToJSVal (ASCII_String x) = pToJSVal $ decodeUtf8 x
datumToJSVal _ = nullRef

utcTimeToAudioSeconds :: (UTCTime,Double) -> UTCTime -> Double
utcTimeToAudioSeconds (t0utc,t0audio) t1utc = realToFrac $ utcTimeToPOSIXSeconds $ addUTCTime clockDiff t1utc
  where clockDiff = realToFrac t0audio - utcTimeToPOSIXSeconds t0utc

utcTimeToAudioSeconds' :: (UTCTime,Double) -> UTCTime -> Double
utcTimeToAudioSeconds' (t0utc,t0event) tSystemInit = realToFrac $ utcTimeToPOSIXSeconds $ addUTCTime clockDiff tSystemInit
  where clockDiff = realToFrac t0event - utcTimeToPOSIXSeconds t0utc
  --
  -- 11.10 - 11.00 = 0.20
  -- 0.10 + 11.00 = 11.10
  -- 0.20 + 11.10 = 11.30

-- foreign import javascript safe
--   "document.addEventListener('DOMContentLoaded', function() { \n\
--     \var utterance = new SpeechSynthesisUtterance('Hello Luis!'); \n\ \speechSynthesis.speak(utterance); \n\
--     \}, false);"
--   js_speechSynthesis :: IO ()

-- uncomment this if working with speechSynthesis
-- foreign import javascript unsafe
--   "var utterance = new SpeechSynthesisUtterance($1); speechSynthesis.speak(utterance);"
--   js_speechSynthesis :: JSVal -> IO ()

  -- "console.log('Hello World')"

-- foreign import javascript unsafe
--   "WebMidi.enable().then(onEnabled); \
--   \function onEnabled() { \
--   \ WebMidi.inputs.forEach(function(input) {console.log(input.manufacturer, input.name)}); \
--   \ var myInput = WebMidi.inputs[0]; \
--   \ }"
--   enableMidi :: IO ()

-- uncomment this if working on midi:
-- foreign import javascript unsafe
--   "midi.js"
--   enableMidi :: IO ()


-- foreign import javascript unsafe
--   "onEnabled()"
--   onEnabled' :: IO ()


-- what is the Double on (UTCTime,Double)?
noteEventToWebDirtJSVal :: UTCTime -> (NominalDiffTime, Map.Map Text JSVal) -> IO JSVal
noteEventToWebDirtJSVal tnow (s,m) = do
    let t' = addUTCTime s tnow --  1 14.53 = 14.54
    let t'' = diffUTCTime t' tnow -- 14.54 - 14.53 = 0.01 --NominalDiffTime
    mapTextJSValToJSVal (realToFrac t'', m)

newtype WebDirt = WebDirt JSVal

instance PToJSVal WebDirt where pToJSVal (WebDirt x) = x

newWebDirt :: AudioIO m => Node -> m WebDirt
newWebDirt n = do
  ctx <- audioContext
  liftIO $ js_newWebDirt ctx n

foreign import javascript unsafe
  "$1.initializeWebAudio()"
  initializeWebAudio :: WebDirt -> IO ()

foreign import javascript unsafe
  "$r = new WebDirt('static/samples/sampleMap.json','static/samples',0,null,0.010,$1,$2)"
  js_newWebDirt :: AudioContext -> Node -> IO WebDirt

foreign import javascript unsafe
  "try { $1.playSample($2) } catch(e) { console.log(e)} "
  playSample :: WebDirt -> JSVal -> IO ()

-- temporary, just for testing
foreign import javascript unsafe
  "try { $1.playSample({ buffer: $2 }) } catch(e) { console.log(e)} "
  playBuffer :: WebDirt -> JSVal -> IO ()

foreign import javascript unsafe
 "commentBox('5731344961241088-proj')"
 commentbox :: IO ()


initializeWebDirtNode :: IO Node
initializeWebDirtNode = liftAudioIO $ do
  webDirtOutput' <- createGain 1.0
  dest <- createDestination
  connectNodes webDirtOutput' dest  --clave!
  let wdout = webDirtOutput'
  return wdout

mapTextJSValToJSVal :: (Double, Map.Map Text JSVal) -> IO JSVal
mapTextJSValToJSVal (t,m) = do
  o <- create
  unsafeSetProp "whenPosix" (pToJSVal t) o
  Map.traverseWithKey (\k v -> unsafeSetProp (textToJSString k) v o) m
  return $ jsval o
