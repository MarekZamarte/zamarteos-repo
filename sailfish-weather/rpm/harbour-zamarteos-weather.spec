Name: harbour-zamarteos-weather
Summary: Prognoza pogody na 7 dni dla Sailfish OS
Version: 0.1
Release: 1
Group: Applications
License: MIT
URL: https://github.com/MarekZamarte/zamarteos-repo
Source0: %{name}-%{version}.tar.bz2

Requires: sailfishsilica-qt5 >= 0.10.9
BuildRequires: pkgconfig(sailfishapp) >= 1.0.2
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Qml)
BuildRequires: pkgconfig(Qt5Quick)
BuildRequires: pkgconfig(Qt5Network)
BuildRequires: desktop-file-utils

%description
Niezależna aplikacja Sailfish Silica z siedmiodniową prognozą pogody.

%prep
%autosetup -n %{name}-%{version}

%build
%qmake5
%make_build

%install
%qmake5_install
desktop-file-install --delete-original --dir %{buildroot}%{_datadir}/applications %{buildroot}%{_datadir}/applications/*.desktop

%files
%{_bindir}/%{name}
%{_datadir}/%{name}/qml/main.qml
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/scalable/apps/%{name}.svg
