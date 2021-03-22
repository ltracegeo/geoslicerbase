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

#ifndef __qGeoSlicerAppMainWindow_h
#define __qGeoSlicerAppMainWindow_h

// GeoSlicer includes
#include "qGeoSlicerAppExport.h"
class qGeoSlicerAppMainWindowPrivate;

// Slicer includes
#include "qSlicerMainWindow.h"

class Q_GEOSLICER_APP_EXPORT qGeoSlicerAppMainWindow : public qSlicerMainWindow
{
  Q_OBJECT
public:
  typedef qSlicerMainWindow Superclass;

  qGeoSlicerAppMainWindow(QWidget *parent=0);
  virtual ~qGeoSlicerAppMainWindow();

public slots:
  void on_HelpAboutGeoSlicerAppAction_triggered();
  void on_HelpKeyboardShortcutsAction_triggered();
  void on_HelpBrowseTutorialsAction_triggered();
  void on_HelpInterfaceDocumentationAction_triggered();
  void on_HelpReportBugOrFeatureRequestAction_triggered();

protected:
  qGeoSlicerAppMainWindow(qGeoSlicerAppMainWindowPrivate* pimpl, QWidget* parent);

private:
  Q_DECLARE_PRIVATE(qGeoSlicerAppMainWindow);
  Q_DISABLE_COPY(qGeoSlicerAppMainWindow);
};

#endif
