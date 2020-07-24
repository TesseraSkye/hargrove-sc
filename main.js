import sc from supercolliderjs

sc.server.boot().then(async server => {
  //synth defs here
  const def = await server.synthDef(
    "formant",
    `{ |out=0, fundfreq=440, formantfreq=440, bwfreq=100, timeScale=1, pan=0|
      var saw, envd, panned;

      saw = Formant.ar(fundfreq, formantfreq, bwfreq);

      envd = saw * EnvGen.kr(Env.sine(0.1, 0.2), timeScale: timeScale, doneAction: 2);
      panned = Pan2.ar(envd * AmpCompA.kr(fundfreq, 0.2, 0.7), pan);

      OffsetOut.ar(out, panned);
    }`,
  );

  //group thing
  const group = server.group();

  const freqSpec = {
    minval: 100,
    maxval: 8000,
    warp: "exp",
  };

  const randFreq = () => sc.map.mapWithSpec(Math.random(), freqSpec);
  
  //function to spawn a synth event
  const spawn = dur => {
    server.synth(
      def,
      {
        fundFreq: randFreq(),
        formantFreq: randFreq(),
        bwFreq: randFreq(),
        pan: sc.map.linToLin(0, 1, -1, 1, Math.random()),
        timeScale: dur,
      },
      group,
    );

    const next = Math.random() *0.25;

    setTimeout(() => spawn(next), next*1000);
  };

    spawn(Math.random());
  }, console.error);