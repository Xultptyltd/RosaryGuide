const P = {
  sign:"In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
  creed:"I believe in God, the Father almighty, Creator of heaven and earth, and in Jesus Christ, his only Son, our Lord, who was conceived by the Holy Spirit, born of the Virgin Mary, suffered under Pontius Pilate, was crucified, died and was buried; he descended into hell; on the third day he rose again from the dead; he ascended into heaven, and is seated at the right hand of God the Father almighty; from there he will come to judge the living and the dead.</p><p>I believe in the Holy Spirit, the holy catholic Church, the communion of saints, the forgiveness of sins, the resurrection of the body, and life everlasting. Amen.",
  our:"Our Father, who art in heaven, hallowed be thy name; thy kingdom come; thy will be done on earth as it is in heaven.</p><p>Give us this day our daily bread; and forgive us our trespasses as we forgive those who trespass against us; and lead us not into temptation, but deliver us from evil. Amen.",
  hail:"Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus.</p><p>Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.",
  glory:"Glory be to the Father, and to the Son, and to the Holy Spirit.</p><p>As it was in the beginning, is now, and ever shall be, world without end. Amen.",
  fatima:"O my Jesus, forgive us our sins, save us from the fires of hell; lead all souls to Heaven, especially those who have most need of your mercy. Amen.",
  queen:"Hail, Holy Queen, Mother of Mercy, our life, our sweetness and our hope. To thee do we cry, poor banished children of Eve. To thee do we send up our sighs, mourning and weeping in this valley of tears.</p><p>Turn then, most gracious advocate, thine eyes of mercy toward us, and after this our exile, show unto us the blessed fruit of thy womb, Jesus.</p><p>O clement, O loving, O sweet Virgin Mary.",
  vV:"Pray for us, O holy Mother of God.",
  vR:"That we may be made worthy of the promises of Christ.",
  michael:"Saint Michael the Archangel, defend us in battle. Be our protection against the wickedness and snares of the devil.</p><p>May God rebuke him, we humbly pray; and do thou, O Prince of the heavenly host, by the power of God, cast into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls. Amen.",
  closing:"O God, whose Only Begotten Son, by his life, Death, and Resurrection, has purchased for us the rewards of eternal life, grant, we beseech thee, that while meditating on these mysteries of the most holy Rosary of the Blessed Virgin Mary, we may imitate what they contain and obtain what they promise, through the same Christ our Lord. Amen."
};

/* Latin of the same prayers. Titles in PT: [English, Latin]. */
const PL = {
  sign:"In nomine Patris, et Filii, et Spiritus Sancti. Amen.",
  creed:"Credo in Deum Patrem omnipotentem, Creatorem caeli et terrae. Et in Iesum Christum, Filium eius unicum, Dominum nostrum, qui conceptus est de Spiritu Sancto, natus ex Maria Virgine, passus sub Pontio Pilato, crucifixus, mortuus, et sepultus; descendit ad inferos; tertia die resurrexit a mortuis; ascendit ad caelos, sedet ad dexteram Dei Patris omnipotentis; inde venturus est iudicare vivos et mortuos.</p><p>Credo in Spiritum Sanctum, sanctam Ecclesiam catholicam, sanctorum communionem, remissionem peccatorum, carnis resurrectionem, vitam aeternam. Amen.",
  our:"Pater noster, qui es in caelis, sanctificetur nomen tuum. Adveniat regnum tuum. Fiat voluntas tua, sicut in caelo, et in terra.</p><p>Panem nostrum cotidianum da nobis hodie, et dimitte nobis debita nostra, sicut et nos dimittimus debitoribus nostris. Et ne nos inducas in tentationem, sed libera nos a malo. Amen.",
  hail:"Ave Maria, gratia plena, Dominus tecum. Benedicta tu in mulieribus, et benedictus fructus ventris tui, Iesus.</p><p>Sancta Maria, Mater Dei, ora pro nobis peccatoribus, nunc et in hora mortis nostrae. Amen.",
  glory:"Gloria Patri, et Filio, et Spiritui Sancto.</p><p>Sicut erat in principio, et nunc, et semper, et in saecula saeculorum. Amen.",
  fatima:"O mi Iesu, dimitte nobis peccata nostra, libera nos ab igne inferni, perduc omnes animas in caelum, praesertim maxime indigentes misericordia tua. Amen.",
  queen:"Salve, Regina, mater misericordiae, vita, dulcedo, et spes nostra, salve. Ad te clamamus, exsules filii Hevae. Ad te suspiramus, gementes et flentes in hac lacrimarum valle.</p><p>Eia ergo, advocata nostra, illos tuos misericordes oculos ad nos converte. Et Iesum, benedictum fructum ventris tui, nobis post hoc exsilium ostende.</p><p>O clemens, o pia, o dulcis Virgo Maria.",
  vV:"Ora pro nobis, sancta Dei Genetrix.",
  vR:"Ut digni efficiamur promissionibus Christi.",
  michael:"Sancte Michael Archangele, defende nos in proelio; contra nequitiam et insidias diaboli esto praesidium.</p><p>Imperet illi Deus, supplices deprecamur: tuque, Princeps militiae caelestis, Satanam aliosque spiritus malignos, qui ad perditionem animarum pervagantur in mundo, divina virtute in infernum detrude. Amen.",
  closing:"Deus, cuius Unigenitus per vitam, mortem et resurrectionem suam nobis salutis aeternae praemia comparavit: concede, quaesumus, ut haec mysteria sacratissimi Rosarii beatae Mariae Virginis recolentes, et imitemur quod continent, et quod promittunt assequamur. Per eundem Christum Dominum nostrum. Amen."
};
const PT = {
  "Sign of the Cross":["Sign of the Cross","Signum Crucis"],
  "Apostles' Creed":["Apostles' Creed","Symbolum Apostolorum"],
  "Our Father":["Our Father","Pater Noster"],
  "Hail Mary":["Hail Mary","Ave Maria"],
  "Glory Be":["Glory Be","Gloria Patri"],
  "Fatima Prayer":["Fatima Prayer","O mi Iesu"],
  "Hail, Holy Queen":["Hail, Holy Queen","Salve Regina"],
  "The Versicle":["The Versicle","Versiculum"],
  "Closing Prayer":["Closing Prayer","Oratio"]
  ,"Saint Michael the Archangel":["Saint Michael the Archangel","Sancte Michael Archangele"]
};
const PKEY = {
  "Sign of the Cross":"sign",
  "Apostles' Creed":"creed",
  "Our Father":"our",
  "Hail Mary":"hail",
  "Glory Be":"glory",
  "Fatima Prayer":"fatima",
  "Hail, Holy Queen":"queen",
  "Closing Prayer":"closing"
};

/* Shown on the last screen, one a day. */
const QUOTES = [
  {t:"When the Holy Rosary is said well, it gives Jesus and Mary more glory and is more meritorious than any other prayer.", by:"St. Louis de Montfort"},
  {t:"Never will anyone who says his Rosary every day be led astray. This is a statement that I would gladly sign with my blood.", by:"St. Louis de Montfort"},
  {t:"The Rosary is the most powerful weapon to touch the Heart of Jesus, Our Redeemer, who loves His Mother.", by:"St. Louis de Montfort"},
  {t:"The rose is the queen of flowers, and so the Rosary is the rose of devotions and the most important one.", by:"St. Louis de Montfort"},
  {t:"The Rosary is a priceless treasure inspired by God.", by:"St. Louis de Montfort"},
  {t:"If you say the Rosary faithfully unto death… you will receive a never-fading crown of glory.", by:"St. Louis de Montfort"},
  {t:"The Rosary is the weapon for these times.", by:"St. Padre Pio"},
  {t:"Love the Madonna and pray the Rosary, for her Rosary is the weapon against the evils of the world today.", by:"St. Padre Pio"},
  {t:"The Rosary is a powerful weapon to put the demons to flight.", by:"St. Padre Pio"},
  {t:"Give me an army saying the Rosary and I will conquer the world.", by:"Blessed Pope Pius IX"},
  {t:"The greatest method of praying is to pray the Rosary.", by:"St. Francis de Sales"},
  {t:"The Rosary is my favorite prayer. A marvelous prayer! Marvelous in its simplicity and its depth.", by:"St. John Paul II"},
  {t:"How beautiful is the family that recites the Rosary every evening.", by:"St. John Paul II"},
  {t:"The Rosary is the most beautiful and the richest in graces of all prayers… if you wish peace to reign in your homes, recite the family Rosary.", by:"Pope St. Pius X"},
  {t:"The Rosary is the most excellent form of prayer and the most efficacious means of attaining eternal life.", by:"Pope Leo XIII"},
  {t:"All my works and labors are based on two things: The Mass and the Rosary.", by:"St. John Vianney"},
  {t:"One day, through the Rosary and the Scapular, Our Lady will save the world.", by:"Attributed to St. Dominic"},
  {t:"You shall obtain all you ask of me by the recitation of the Rosary.", by:"Our Lady to Blessed Alan de la Roche"},
  {t:"After the Holy Sacrifice of the Mass, there is nothing in the Church that I love as much as the Rosary.", by:"Our Lady to Blessed Alan de la Roche"},
  {t:"There is no problem, I tell you, no matter how difficult it is, that we cannot resolve by the prayer of the Holy Rosary.", by:"Sister Lucia of Fatima"}
];
