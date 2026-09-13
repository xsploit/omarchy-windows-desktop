#include <QApplication>
#include <QDir>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QSlider>
#include <QPushButton>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimer>
int main(int argc,char**argv){
 QApplication app(argc,argv);app.setDesktopFileName("hdr-brightness");
 QWidget w;w.setWindowTitle("HDR Brightness");w.resize(520,310);
 auto l=new QVBoxLayout(&w);l->setContentsMargins(24,22,24,22);l->setSpacing(18);
 auto title=new QLabel("HDR Brightness");title->setStyleSheet("font-size:24px;font-weight:600;");l->addWidget(title);
 auto desc=new QLabel("LG TV · Software brightness boost\nChanges the whole HDR image without using the TV remote.");desc->setWordWrap(true);l->addWidget(desc);
 auto value=new QLabel; l->addWidget(value);
 auto slider=new QSlider(Qt::Horizontal);slider->setRange(0,100);slider->setObjectName("brightnessSlider");l->addWidget(slider);
 auto note=new QLabel("0 = no boost · 100 = 6× signal brightness\nThis is not Windows’ scale. High levels can flatten bright details.");note->setWordWrap(true);note->setStyleSheet("color:#b6bdcd;font-size:12px;");l->addWidget(note);
 auto status=new QLabel;status->setWordWrap(true);l->addWidget(status);
 auto row=new QHBoxLayout;l->addLayout(row);auto restore=new QPushButton("Restore previous");auto max=new QPushButton("Maximum boost");row->addWidget(restore);row->addWidget(max);
 auto update=[&](int n){value->setText(QString("Brightness boost: %1 / 100").arg(n));};
 auto call=[&](QStringList args){QProcess p;p.start(QDir::homePath()+"/.local/bin/hdr-brightness-control",args);if(!p.waitForFinished(20000)||p.exitCode()!=0){status->setText("Could not apply: "+QString::fromUtf8(p.readAllStandardError()));return;}auto obj=QJsonDocument::fromJson(p.readAllStandardOutput()).object();slider->setValue(obj["level"].toInt());update(slider->value());status->setText(obj["enabled"].toBool()?"Applied · HDR stays enabled":"Previous brightness restored");};
 QTimer timer;timer.setSingleShot(true);timer.setInterval(350);
 QObject::connect(slider,&QSlider::valueChanged,[&](int n){update(n);if(!slider->isSliderDown())timer.start();});
 QObject::connect(slider,&QSlider::sliderReleased,[&](){timer.start();});
 QObject::connect(&timer,&QTimer::timeout,[&](){call({"set",QString::number(slider->value())});});
 QObject::connect(max,&QPushButton::clicked,[&](){timer.stop();slider->setValue(100);timer.stop();call({"set","100"});});
 QObject::connect(restore,&QPushButton::clicked,[&](){timer.stop();call({"restore"});timer.stop();});
 call({"status"});timer.stop();
 app.setStyleSheet("QWidget{background:#202535;color:#f4f4f4;font-family:'Segoe UI';font-size:14px;} QPushButton{background:#353e52;border:1px solid #505a70;border-radius:5px;padding:9px;} QPushButton:hover{background:#435069;} QSlider::groove:horizontal{height:6px;background:#4b5262;border-radius:3px;} QSlider::sub-page:horizontal{background:#60cdff;border-radius:3px;} QSlider::handle:horizontal{background:#60cdff;border:3px solid #202535;width:18px;margin:-9px 0;border-radius:12px;}");
 w.show();return app.exec();
}
