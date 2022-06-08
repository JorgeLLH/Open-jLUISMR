Pin = Model( v = potential, i = flow )

OnePort = Model(
    p = Pin,
    n = Pin,
    equations = :[
        0 = p.i + n.i
        v = p.v - n.v
        i = p.i ] )

Resistor = OnePort | Model( R = 1.0u"Ω", equations = :[ R*i = v ], )

Capacitor = OnePort | Model( C = 1.0u"F", v=Map(init=0.0u"V"), equations = :[ C*der(v) = i ] )

Inductor = OnePort | Model( L = 1.0u"H", i=Map(init=0.0u"A"), equations = :[ L*der(i) = v ] )

ConstantVoltage = OnePort | Model( V = 1.0u"V", equations = :[ v = V ] )