/*==============================================================================

  Copyright (c) Kitware, Inc.

  See http://www.slicer.org/copyright/copyright.txt for details.

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  This file was originally developed by Julien Finet, Kitware, Inc.
  and was partially funded by NIH grant 3P41RR013218-12S1

==============================================================================*/

// GeoSlicer includes
#include "qGeoSlicerAppMainWindow.h"
#include "qGeoSlicerAppMainWindow_p.h"

// Qt includes
#include <QDesktopWidget>
#include <QDesktopServices>
#include <QPixmap>
#include <QStyle>
#include <QUrl>

// Slicer includes
#include "qSlicerApplication.h"
#include "qSlicerAboutDialog.h"
#include "qSlicerMainWindow_p.h"
#include "qSlicerModuleSelectorToolBar.h"
#include "qSlicerAbstractModule.h"
#include "qSlicerActionsDialog.h"
#include "qSlicerErrorReportDialog.h"
#include "qSlicerModuleManager.h"
#include "vtkSlicerVersionConfigure.h" // For Slicer_VERSION_MAJOR,Slicer_VERSION_MINOR

//-----------------------------------------------------------------------------
// qGeoSlicerAppMainWindowPrivate methods

qGeoSlicerAppMainWindowPrivate::qGeoSlicerAppMainWindowPrivate(qGeoSlicerAppMainWindow& object)
  : Superclass(object)
{
}

//-----------------------------------------------------------------------------
qGeoSlicerAppMainWindowPrivate::~qGeoSlicerAppMainWindowPrivate()
{
}

//-----------------------------------------------------------------------------
void qGeoSlicerAppMainWindowPrivate::init()
{
#if (QT_VERSION >= QT_VERSION_CHECK(5, 7, 0))
  QApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
#endif
  Q_Q(qGeoSlicerAppMainWindow);
  this->Superclass::init();
}

//-----------------------------------------------------------------------------
void qGeoSlicerAppMainWindowPrivate::setupUi(QMainWindow * mainWindow)
{
  qSlicerApplication * app = qSlicerApplication::application();
  //----------------------------------------------------------------------------
  // Add actions
  //----------------------------------------------------------------------------
  QAction* helpKeyboardShortcutsAction = new QAction(mainWindow);
  helpKeyboardShortcutsAction->setObjectName("HelpKeyboardShortcutsAction");
  helpKeyboardShortcutsAction->setText(qGeoSlicerAppMainWindow::tr("&Keyboard Shortcuts"));
  helpKeyboardShortcutsAction->setToolTip(qGeoSlicerAppMainWindow::tr("Raise a window that lists commonly-used keyboard shortcuts."));

  QAction* helpInterfaceDocumentationAction = new QAction(mainWindow);
  helpInterfaceDocumentationAction->setObjectName("HelpInterfaceDocumentationAction");
  helpInterfaceDocumentationAction->setText(qGeoSlicerAppMainWindow::tr("Interface Documentation"));
  helpInterfaceDocumentationAction->setShortcut(QKeySequence(qGeoSlicerAppMainWindow::tr("Ctrl+1", "Interface Documentation")));

  QAction* helpBrowseTutorialsAction = new QAction(mainWindow);
  helpBrowseTutorialsAction->setObjectName("HelpBrowseTutorialsAction");
  helpBrowseTutorialsAction->setText(qGeoSlicerAppMainWindow::tr("Browse tutorials"));
  helpBrowseTutorialsAction->setToolTip(qGeoSlicerAppMainWindow::tr("Raise the training pages in your favorite web browser"));

  QAction* helpReportBugOrFeatureRequestAction = new QAction(mainWindow);
  helpReportBugOrFeatureRequestAction->setObjectName("HelpReportBugOrFeatureRequestAction");
  helpReportBugOrFeatureRequestAction->setText(qGeoSlicerAppMainWindow::tr("Report a bug"));
  helpReportBugOrFeatureRequestAction->setToolTip(qGeoSlicerAppMainWindow::tr("Report error or request enhancement or new feature."));

  QAction* helpAboutSlicerAppAction = new QAction(mainWindow);
  helpAboutSlicerAppAction->setObjectName("HelpAboutGeoSlicerAppAction");
  helpAboutSlicerAppAction->setText("About " + app->applicationName());

  //----------------------------------------------------------------------------
// Calling "setupUi()" after adding the actions above allows the call
// to "QMetaObject::connectSlotsByName()" done in "setupUi()" to
// successfully connect each slot with its corresponding action.
  this->Superclass::setupUi(mainWindow);

  //----------------------------------------------------------------------------
  // Configure
  //----------------------------------------------------------------------------
  mainWindow->setWindowIcon(QIcon(":/Icons/Medium/DesktopIcon.png"));

  this->HelpMenu->addAction(helpKeyboardShortcutsAction);
  this->HelpMenu->addAction(helpInterfaceDocumentationAction);
  this->HelpMenu->addAction(helpBrowseTutorialsAction);
  this->HelpMenu->addSeparator();
  this->HelpMenu->addAction(helpReportBugOrFeatureRequestAction);
  this->HelpMenu->addAction(helpAboutSlicerAppAction);

  //----------------------------------------------------------------------------
  // Icons in the menu
  //----------------------------------------------------------------------------

  QIcon networkIcon = mainWindow->style()->standardIcon(QStyle::SP_DriveNetIcon);
  QIcon informationIcon = mainWindow->style()->standardIcon(QStyle::SP_MessageBoxInformation);
  QIcon questionIcon = mainWindow->style()->standardIcon(QStyle::SP_MessageBoxQuestion);

  helpBrowseTutorialsAction->setIcon(networkIcon);
  helpInterfaceDocumentationAction->setIcon(networkIcon);
  helpAboutSlicerAppAction->setIcon(informationIcon);
  helpReportBugOrFeatureRequestAction->setIcon(questionIcon);


  this->LogoLabel->setVisible(false);

  // Hide the toolbars
  // this->MainToolBar->setVisible(false);
  //this->ModuleSelectorToolBar->setVisible(false);
  // this->ModuleToolBar->setVisible(false);
  // this->ViewToolBar->setVisible(false);
  // this->MouseModeToolBar->setVisible(false);
  // this->CaptureToolBar->setVisible(false);
  // this->ViewersToolBar->setVisible(false);
  // this->DialogToolBar->setVisible(false);

  // Hide the menus
  //this->menubar->setVisible(false);
  //this->FileMenu->setVisible(false);
  //this->EditMenu->setVisible(false);
  //this->ViewMenu->setVisible(false);
  //this->LayoutMenu->setVisible(false);
  //this->HelpMenu->setVisible(false);

  // Hide the modules panel
  //this->PanelDockWidget->setVisible(false);
  // this->DataProbeCollapsibleWidget->setCollapsed(true);
  // this->DataProbeCollapsibleWidget->setVisible(false);
  // this->StatusBar->setVisible(false);
}

//-----------------------------------------------------------------------------
// qGeoSlicerAppMainWindow methods

//-----------------------------------------------------------------------------
qGeoSlicerAppMainWindow::qGeoSlicerAppMainWindow(QWidget* windowParent)
  : Superclass(new qGeoSlicerAppMainWindowPrivate(*this), windowParent)
{
  Q_D(qGeoSlicerAppMainWindow);
  d->init();
}

//-----------------------------------------------------------------------------
qGeoSlicerAppMainWindow::qGeoSlicerAppMainWindow(
  qGeoSlicerAppMainWindowPrivate* pimpl, QWidget* windowParent)
  : Superclass(pimpl, windowParent)
{
  // init() is called by derived class.
}

//-----------------------------------------------------------------------------
qGeoSlicerAppMainWindow::~qGeoSlicerAppMainWindow()
{
}

//-----------------------------------------------------------------------------
void qGeoSlicerAppMainWindow::on_HelpAboutGeoSlicerAppAction_triggered()
{
  qSlicerAboutDialog about(this);
  about.setLogo(QPixmap(":/Logo.png"));
  about.setWindowIcon(QIcon(":/Icons/Medium/DesktopIcon.png"));
  about.exec();
}

void qGeoSlicerAppMainWindow::on_HelpKeyboardShortcutsAction_triggered()
{
  qSlicerActionsDialog actionsDialog(this);
  actionsDialog.setActionsWithNoShortcutVisible(false);
  actionsDialog.setMenuActionsVisible(false);
  actionsDialog.addActions(this->findChildren<QAction*>(), "Slicer Application");
  actionsDialog.setWindowIcon(QIcon(":/Icons/Medium/DesktopIcon.png"));

  // scan the modules for their actions
  QList<QAction*> moduleActions;
  qSlicerModuleManager * moduleManager = qSlicerApplication::application()->moduleManager();
  foreach(const QString& moduleName, moduleManager->modulesNames())
    {
    qSlicerAbstractModule* module =
      qobject_cast<qSlicerAbstractModule*>(moduleManager->module(moduleName));
    if (module)
      {
      moduleActions << module->action();
      }
    }
  if (moduleActions.size())
    {
    actionsDialog.addActions(moduleActions, "Modules");
    }
  // TODO add more actions
  actionsDialog.exec();
}

//---------------------------------------------------------------------------
void qGeoSlicerAppMainWindow::on_HelpBrowseTutorialsAction_triggered()
{
  QString url;
  if (qSlicerApplication::application()->releaseType() == "Stable")
    {
    url = QString("http://www.slicer.org/slicerWiki/index.php/Documentation/%1.%2/Training")
                    .arg(Slicer_VERSION_MAJOR).arg(Slicer_VERSION_MINOR);
    }
  else
    {
    url = QString("http://www.slicer.org/slicerWiki/index.php/Documentation/Nightly/Training");
    }
  QDesktopServices::openUrl(QUrl(url));
}

//---------------------------------------------------------------------------
void qGeoSlicerAppMainWindow::on_HelpInterfaceDocumentationAction_triggered()
{
  QString url;
  if (qSlicerApplication::application()->releaseType() == "Stable")
    {
    url = QString("http://www.slicer.org/slicerWiki/index.php/Documentation/%1.%2")
                    .arg(Slicer_VERSION_MAJOR).arg(Slicer_VERSION_MINOR);
    }
  else
    {
    url = QString("http://www.slicer.org/slicerWiki/index.php/Documentation/Nightly");
    }
  QDesktopServices::openUrl(QUrl(url));
}

//---------------------------------------------------------------------------
void qGeoSlicerAppMainWindow::on_HelpReportBugOrFeatureRequestAction_triggered()
{
  qSlicerErrorReportDialog errorReport(this);
  errorReport.setWindowIcon(QIcon(":/Icons/Medium/DesktopIcon.png"));
  errorReport.exec();
}
