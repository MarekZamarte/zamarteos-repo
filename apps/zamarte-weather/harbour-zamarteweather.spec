Name:       harbour-zamarteweather
Version:    0.1.0
Release:    1
Summary:    Czytelna prognoza pogody dla Zamartego
License:    BSD-3-Clause
Group:      Qt/Qt
BuildArch:  aarch64
Source0:    %{name}-%{version}.tar.bz2
BuildRequires: sailfishsilica-qt5
BuildRequires: qt5-qtdeclarative
Requires: sailfishsilica-qt5

%description
Aplikacja pogodowa Sailfish OS dla Zamartego z aktualną pogodą i prognozą 7-dniową.

%prep
%setup -q -n %{name}-%{version}

%build
qmake harbour-zamarteweather.pro
make %{?_smp_mflags}

%install
make install INSTALL_ROOT=%{buildroot}

%files
%{_bindir}/harbour-zamarteweather
%{_datadir}/harbour-zamarteweather/qml/harbour-zamarteweather.qml
%{_datadir}/harbour-zamarteweather/qml/WeatherPage.qml
%{_datadir}/harbour-zamarteweather/qml/cover.qml
%{_datadir}/applications/harbour-zamarteweather.desktop
