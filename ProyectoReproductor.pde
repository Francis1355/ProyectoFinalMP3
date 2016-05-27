import ddf.minim.*;
import controlP5.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.ugens.*;

import java.util.*;
import java.net.InetAddress;
import javax.swing.*;
import javax.swing.filechooser.FileFilter;
import javax.swing.filechooser.FileNameExtensionFilter;

import org.elasticsearch.action.admin.indices.exists.indices.IndicesExistsResponse;
import org.elasticsearch.action.admin.cluster.health.ClusterHealthResponse;
import org.elasticsearch.action.index.IndexRequest;
import org.elasticsearch.action.index.IndexResponse;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.action.search.SearchType;
import org.elasticsearch.client.Client;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.node.Node;
import org.elasticsearch.node.NodeBuilder;

ControlP5 ui, p, slid;
AudioPlayer song;
Minim minim;
BeatDetect beat;
Textlabel txt;
FFT fft; 
HighPassSP highpass;
LowPassSP lowpass;
BandPass bandpass;
LowPassFS   lpf;
AudioMetaData datos;
ScrollableList list;

boolean c;
float a;
float kickSize, snareSize, hatSize;
boolean selec;
int prog = 0;
int volume = 0;
int millis;
int Hpass;
int Lpass;
int Bpass;

static String INDEX_NAME = "canciones";
static String DOC_TYPE = "cancion";


Client client;
Node node;

void setup() {
  size(800, 400);//700,400
  background(255);
  ui = new ControlP5(this);

  Settings.Builder settings = Settings.settingsBuilder();

  settings.put("path.data", "esdata");
  settings.put("path.home", "/");
  settings.put("http.enabled", false);
  settings.put("index.number_of_replicas", 0);
  settings.put("index.number_of_shards", 1);

  node = NodeBuilder.nodeBuilder()
    .settings(settings)
    .clusterName("mycluster")
    .data(true)
    .local(true)
    .node();

  client = node.client();

  ClusterHealthResponse r = client.admin().cluster().prepareHealth().setWaitForGreenStatus().get();
  println(r);

  IndicesExistsResponse ier = client.admin().indices().prepareExists(INDEX_NAME).get();
  if (!ier.isExists()) {

    client.admin().indices().prepareCreate(INDEX_NAME).get();
  }

  ui.addButton("importFiles")
    .setPosition(650, 5)
    .setLabel("Importar archivos")
    .setSize(100, 20)
    .updateSize();

  ui.addButton("ecual")
    .setPosition(690, 270)
    .setLabel("Ecualizador")
    .updateSize();

  list = ui.addScrollableList("playlist")
    .setPosition(600, 30)
    .setSize(200, 350)
    .setBarHeight(20)
    .setItemHeight(20)
    .setType(ScrollableList.LIST);

  loadFiles();
  p = new ControlP5(this);
  txt = p.addTextlabel("label")
    .setText("Titulo Desconocido \nInterprete Desconocido")
    .setPosition(250, 100)
    .setColorValue(255)
    .setFont(createFont("Century Gothic", 14))
    ;

  slid= new ControlP5(this);
  slid.setColorForeground(255);
  slid.setColorBackground(0);
  slid.setColorActive(0xffff0000);
  ui.addSlider("Hpass")
    .setPosition(680, 300)
    .setSize(10, 100)
    .setRange(0, 3000)
    .setValue(0)
    .setNumberOfTickMarks(30);

  ui.addSlider("Lpass")
    .setPosition(720, 300)
    .setSize(10, 100)
    .setRange(3000, 20000) //100-150
    .setValue(3000)
    .setNumberOfTickMarks(30);

  ui.addSlider("Bpass")
    .setPosition(760, 300)
    .setSize(10, 100)
    .setRange(100, 1000)//250-2500
    .setValue(100)
    .setNumberOfTickMarks(30);
  ui.getController("Hpass").getValueLabel()
    .align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE)
    .setPaddingY(-100);
  ui.getController("Lpass")
    .getValueLabel()
    .align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE)
    .setPaddingY(-100);
  ui.getController("Bpass")
    .getValueLabel()
    .align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE)
    .setPaddingY(-100);


  ui.addButton("play")
    .setValue(0)
    .setPosition(300, height-65)
    .setSize(10, 10)
    .setImages(loadImage("btnplay1.png"), loadImage("btnplay1.png"), loadImage("btnplay1.png"))
    .updateSize();

  ui.addButton("stop")
    .setValue(0)
    .setPosition(250, height-65)
    .setSize(10, 10)
    .setImages(loadImage("btnstop1.png"), loadImage("btnstop1.png"), loadImage("btnstop1.png"))
    .updateSize();

  ui.addButton("pause")
    .setValue(0)
    .setPosition(350, height-65)
    .setSize(10, 10)
    .setImages(loadImage("btnpause3.png"), loadImage("btnpause3.png"), loadImage("btnpause3.png"))
    .updateSize();


  ui.addSlider("volume")
    .setPosition(480, height-35)
    .setSize(110, 12)
    .setRange(-40, 20)
    .setValue(0)
    .setNumberOfTickMarks(10);

  ui.addButton("mute")
    .setValue(0)
    .setPosition(445, height-42)
    .setSize(20, 20)
    .setImages(loadImage("mutes.png"), loadImage("mutes.png"), loadImage("mutes.png"))
    .updateSize();

  ui.addButton("icon")
    .setValue(0)
    .setPosition(0, height-65)
    .setSize(10, 10)
    .setImages(loadImage("mp3.png"), loadImage("mp3.png"), loadImage("mp3.png"))
    .updateSize();

  ui.addButton("cargar")
    .setPosition(75, 345)
    .setSize(100, 50);

  ui.addButton("iconLoad")
    .setValue(0)
    .setPosition(180, height-65)
    .setSize(10, 10)
    .setImages(loadImage("load.png"), loadImage("load.png"), loadImage("load.png"))
    .updateSize();

  ui.addButton("logo")
    .setValue(0)
    .setPosition(0, 0)
    .setSize(10, 10)
    .setImages(loadImage("logo.png"), loadImage("logo.png"), loadImage("logo.png"))
    .updateSize();


  //Sound initialization
  minim = new Minim(this);
}


void draw() {
  background(0);
  //fill(150,200,255);
 //150//127,0,0
  fill(127,0,0);
  
  
  noStroke();
  rect(0, 342, width, height);
  rect(600, 0, width, height);
  //fill(255);
  stroke(0);
  if (song!=null) {
    highpass.setFreq(Hpass);
    lowpass.setFreq(Lpass);
    bandpass.setFreq(Bpass);
    fill(0);
    stroke(205,0,205);
    fft.forward(song.mix);
    for (int i = 0; i < fft.specSize(); i++) {
      float band = fft.getBand(i);
      float vo = 350 - band*50;
      line(i, 355, i, vo);
    }
    if (selec) {
      if (mousePressed && mouseX>465 && mouseX<515 && mouseY>370 && mouseY<385) {
        if (song.isPlaying() == true) {
          song.pause();
          song.play(prog);
        } else {
          song.cue(prog);
          millis = prog;
        }
      }
    }

    if (mousePressed && mouseX>100 && mouseX<70 && mouseY>71 && mouseY<83) {
      song.setGain(volume);
      if (volume == -40) {
      } else {
        song.mute();
      }
    }
    if (volume == 0) {
    } else {
      song.setGain(volume);
    }
  }
}

/*
public void cargar() {
 selec = false;
 selectInput("Selecciona la cancion:", "fileSelected");
 }
 */
public void play() {
  song.play();
  println("play");
}


public void stop() {
  song.pause();
  song.rewind();
  println("stop");
}

public void pause() {
  song.pause();
  println("pause");
}

public void buttonVolume() {
  song.setGain(volume);
}

void fileSelected(File selection) {
  minim.stop();
  //song = minim.loadFile(selection.getAbsolutePath(), 1024);
  //song.setGain(volume);
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    if (song!=null) {
      song.pause();
    }
    println("User selected " + selection.getAbsolutePath());
    minim = new Minim(this);

    song = minim.loadFile(selection.getAbsolutePath(), 1024);
    fft = new FFT(song.bufferSize(), song.sampleRate());
    highpass = new HighPassSP(300, song.sampleRate());
    song.addEffect(highpass);
    lowpass = new LowPassSP(300, song.sampleRate());
    song.addEffect(lowpass);
    bandpass = new BandPass(300, 300, song.sampleRate());
    song.addEffect(bandpass);
    fft = new FFT(song.bufferSize(), song.sampleRate());
    // calculate averages based on a miminum octave width of 22 Hz
    // split each octave into three bands
    fft.logAverages(10, 5);
    datos = song.getMetaData();
    if (!datos.title().equals("")) {
      txt.setText(datos.title()+"`\n"+datos.author());
      print("sale");
    } else {
      txt.setText(datos.fileName());
      print("entra");
    }

    //btnPlay.show();
    //btnPause.hide();
  }
}


void importFiles() {
  // Selector de archivos
  JFileChooser jfc = new JFileChooser();
  // Agregamos filtro para seleccionar solo archivos .mp3
  jfc.setFileFilter(new FileNameExtensionFilter("MP3 File", "mp3"));
  // Se permite seleccionar multiples archivos a la vez
  jfc.setMultiSelectionEnabled(true);
  // Abre el dialogo de seleccion
  jfc.showOpenDialog(null);

  // Iteramos los archivos seleccionados
  for (File f : jfc.getSelectedFiles()) {
    // Si el archivo ya existe en el indice, se ignora
    GetResponse response = client.prepareGet(INDEX_NAME, DOC_TYPE, f.getAbsolutePath()).setRefresh(true).execute().actionGet();
    if (response.isExists()) {
      continue;
    }

    // Cargamos el archivo en la libreria minim para extrar los metadatos
    Minim minim = new Minim(this);
    AudioPlayer song = minim.loadFile(f.getAbsolutePath());
    AudioMetaData meta = song.getMetaData();

    // Almacenamos los metadatos en un hashmap
    Map<String, Object> doc = new HashMap<String, Object>();
    doc.put("author", meta.author());
    doc.put("title", meta.title());
    doc.put("path", f.getAbsolutePath());

    try {
      // Le decimos a ElasticSearch que guarde e indexe el objeto
      client.prepareIndex(INDEX_NAME, DOC_TYPE, f.getAbsolutePath())
        .setSource(doc)
        .execute()
        .actionGet();

      // Agregamos el archivo a la lista
      addItem(doc);
    } 
    catch(Exception e) {
      e.printStackTrace();
    }
  }
}

void playlist(int n) {
  //println(list.getItem(n));
  if (song!=null) {
    song.pause();
  }
  Map<String, Object> value = (Map<String, Object>) list.getItem(n).get("value");
  println(value.get("path"));
  minim = new Minim(this);

  song = minim.loadFile((String)value.get("path"), 1024);
  //p.show();
  //btnPause.hide();
  highpass = new HighPassSP(300, song.sampleRate());
  song.addEffect(highpass);
  lowpass = new LowPassSP(300, song.sampleRate());
  song.addEffect(lowpass);
  bandpass = new BandPass(300, 300, song.sampleRate());
  song.addEffect(bandpass);
  fft = new FFT(song.bufferSize(), song.sampleRate());
  // calculate averages based on a miminum octave width of 22 Hz
  // split each octave into three bands
  fft.logAverages(22, 10);
  datos = song.getMetaData();
  if (!datos.title().equals("")) {
    txt.setText(datos.title()+"`\n"+datos.author());
    print("sale");
  } else {
    txt.setText(datos.fileName());
    print("entra");
  }
  //song = min.loadFile(selection.getAbsolutePath(),1024);
}

void loadFiles() {
  try {
    // Buscamos todos los documentos en el indice
    SearchResponse response = client.prepareSearch(INDEX_NAME).execute().actionGet();

    // Se itera los resultados
    for (SearchHit hit : response.getHits().getHits()) {
      // Cada resultado lo agregamos a la lista
      addItem(hit.getSource());
    }
  } 
  catch(Exception e) {
    e.printStackTrace();
  }
}
void addItem(Map<String, Object> doc) {
  // Se agrega a la lista. El primer argumento es el texto a desplegar en la lista, el segundo es el objeto que queremos que almacene
  list.addItem(doc.get("author") + " - " + doc.get("title"), doc);
}