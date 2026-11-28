Name: harbour-murenahub
Summary: Murena Workspace hub for Sailfish OS
Version: 0.1.0
Release: 1
Group: Applications/Internet
License: GPL-3.0-or-later
URL: https://murena.io
Source0: %{name}-%{version}.tar.bz2
BuildRequires: pkgconfig(sailfishapp)
BuildRequires: pkgconfig(qt5embedwidget)
BuildRequires: qt5-qtdeclarative
Requires: sailfish-components-webview-qt5
%description
Native Sailfish Silica app opening Murena Workspace in Sailfish WebView.
%prep
%setup -q
%build
qmake-qt5 harbour-murenahub.pro
make %{?_smp_mflags}
%install
rm -rf %{buildroot}
install -D -m 0755 harbour-murenahub %{buildroot}%{_bindir}/harbour-murenahub
install -D -m 0644 harbour-murenahub.desktop %{buildroot}%{_datadir}/applications/harbour-murenahub.desktop
install -d %{buildroot}%{_datadir}/harbour-murenahub/qml/pages
install -m 0644 qml/harbour-murenahub.qml %{buildroot}%{_datadir}/harbour-murenahub/qml/
install -m 0644 qml/pages/*.qml %{buildroot}%{_datadir}/harbour-murenahub/qml/pages/
%files
%{_bindir}/harbour-murenahub
%{_datadir}/applications/harbour-murenahub.desktop
%{_datadir}/harbour-murenahub/qml/
