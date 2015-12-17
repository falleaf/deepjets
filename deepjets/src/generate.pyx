
@cython.boundscheck(False)
@cython.wraparound(False)
def generate_pythia(string config, string xmldoc,
                    int n_events,
                    int random_seed=0,
                    float beam_ecm=13000.,
                    float eta_max=5.,
                    float jet_size=0.6, float subjet_size=0.3,
                    float jet_pt_min=12.5, float subjet_pt_min=0.05):
    """
    Generate Pythia events and yield jet and constituent arrays
    """
    cdef int ievent;
    cdef Pythia* pythia = new Pythia(xmldoc, False)

    pythia.readString('Beams:eCM = {0}'.format(beam_ecm))
    pythia.readString('Random:setSeed = on')
    pythia.readString('Random:seed = {0}'.format(random_seed))
    pythia.readString("Init:showProcesses = on")
    pythia.readString("Init:showMultipartonInteractions = off")
    pythia.readString("Init:showChangedSettings = on")
    pythia.readString("Init:showChangedParticleData = off")
    pythia.readString("Next:numberShowInfo = 0")
    pythia.readString("Next:numberShowProcess = 0")
    pythia.readString("Next:numberShowEvent = 0")
    pythia.readFile(config)
    pythia.init()

    cdef int num_jet_constit = 0
    cdef int num_subjets = 0
    cdef int num_subjets_constit = 0

    cdef np.ndarray jet_arr
    cdef np.ndarray jet_constit_arr
    cdef np.ndarray subjet_constit_arr

    cdef Result* result

    dtype_jet = np.dtype([('pT', np.double), ('eta', np.double), ('phi', np.double)])
    dtype_constit = np.dtype([('ET', np.double), ('eta', np.double), ('phi', np.double)])

    try:
        ievent = 0
        while ievent < n_events:
            # Generate event. Quit if failure.
            if not pythia.next():
                raise RuntimeError("event generation aborted prematurely")

            result = get_jets(pythia.event,
                              eta_max, jet_size, subjet_size,
                              jet_pt_min, subjet_pt_min)

            num_jet_constit = result.jet.constituents().size()
            num_subjets = result.subjets.size()
            num_subjets_constit = 0
            for isubjet in range(result.subjets.size()):
                num_subjets_constit += result.subjets[isubjet].constituents().size()
            
            jet_arr = np.empty((num_subjets + 1,), dtype=dtype_jet)
            jet_constit_arr = np.empty((num_jet_constit,), dtype=dtype_constit)
            subjet_constit_arr = np.empty((num_subjets_constit,), dtype=dtype_constit)

            jets_to_arrays(result[0],
                           <double*> jet_arr.data,
                           <double*> jet_constit_arr.data,
                           <double*> subjet_constit_arr.data)
            del result

            yield jet_arr, jet_constit_arr, subjet_constit_arr
            ievent += 1
        pythia.stat()
    finally:
        del pythia
