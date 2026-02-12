import 'package:dates/models/date.dart';

class Carta extends DateEvent {
  bool abierta;

  Carta({
    required super.title,
    required super.description,
    required super.date,
    this.abierta = false,
  }) : super(type: 'carta');
}

// Ejemplo de tu lista
List<Carta> misCartas = [
  Carta(
    date: "14-02-2026",
    title: "Para mi San Valentín",
    description:
        """Amor, se que no festejamos mucho este día, pero me encanta festejar todos lo días contigo, tal vez no se muy cariñoso, ni romántico, ni detallista, ni de regalos hechos a mano, pero en verdad te amo, y aunque a veces me enoje y feo, no te dejo de amar, se que cuando estoy enojado no lo demuestro y lamento mucho eso, pero en serio te quiero a mi lado, no quiero hacer que me evites, no quiero hacerte sentir que estar conmigo es un dolor insoportable, quiero disfrutar tu compañía y tu disfrutes de la mía, te quiero para toda la vida, y cuando muramos te quiero para toda mi muerte, te quiero a mi lado, te quiero estando lejos y te quiero estando enojados y obviamente te quiero estando felices.\n
    amo tu sonrisa, tus chiste, tus bromas, tu cabello, tus labios, tus pompis, tus ojos, tu todo, y aunque no me gusta que estés triste, amo que me compartas tus dolencias, tus tristezas, tus lagrimas, tus enojos, tus quejas, amo estar para ti, amor sentirme tu lugar seguro, y amo sentirte como mi lugar seguro, por eso Hoy y siempre seguiré diciéndote te amoooo.\n
    y cuando me quede sin voz te lo seguire demostrando. \n
    TE AMOOOOOOOO como si contaras todos lo segundos que has estado en este mundo y cuando acabes de contarlos lo multiplicas por los segundos que yo he tenido en esta mundo y todo eso sol osera el 0.0000000000000000000000000001% de todo lo que te amo.\n
    """,
  ),
];
