# simple makefile to simplify repetitive build env management tasks under posix

PYTHON := $(shell which python)
output := /data/edawe/public/deepjets/events
setup := cd /home/edawe/workspace/deepjets; source /data/edawe/public/setup.sh; source setup.sh;
WMASS := 80.385

.PHONY: events

all: clean inplace

clean-pyc:
	@find . -name "*.pyc" -exec rm {} \;

clean-so:
	@find deepjets -name "*.so" -exec rm {} \;

clean-build:
	@rm -rf build

clean: clean-build clean-pyc clean-so

in: inplace # just a shortcut
inplace:
	@$(PYTHON) setup.py build_ext -i

events:
	mkdir -p $(output)/log
	# default samples used in http://arxiv.org/abs/1511.05190 
	#echo "$(setup) ./generate wprime.config --events 500000 --output $(output)/wprime_default_0p6.h5 --cut-on-pdgid 24 --pt-min 250 --pt-max 300 --jet-size 0.6" | qsub -e $(output)/log -o $(output)/log -N wprime_default_0p6
	echo "$(setup) ./generate w.config --events 500000 --output $(output)/w_default_0p6.h5 --params \"PhaseSpace:pTHatMin = 230;PhaseSpace:pTHatMax = 320\" --trimmed-pt-min 250 --trimmed-pt-max 300 --jet-size 0.6" | qsub -e $(output)/log -o $(output)/log -N w_default_0p6
	echo "$(setup) ./generate qcd.config --events 500000 --output $(output)/qcd_default_0p6.h5 --params \"PhaseSpace:pTHatMin = 230;PhaseSpace:pTHatMax = 320\" --trimmed-pt-min 250 --trimmed-pt-max 300 --jet-size 0.6" | qsub -e $(output)/log -o $(output)/log -N qcd_default_0p6
	# no shrink
	for pthatmin in $$(seq 150 50 500); do \
		echo "$(setup) ./generate qcd.config --jet-size 1.2 --events 100000 --output $(output)/qcd_1p2_$${pthatmin}.h5 --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N qcd_1p2_$${pthatmin}; \
		echo "$(setup) ./generate w.config --jet-size 1.2 --events 100000 --output $(output)/w_1p2_$${pthatmin}.h5 --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N w_1p2_$${pthatmin}; \
		echo "$(setup) ./generate qcd.config --jet-size 1 --events 100000 --output $(output)/qcd_1p0_$${pthatmin}.h5 --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N qcd_1p0_$${pthatmin}; \
		echo "$(setup) ./generate w.config --jet-size 1 --events 100000 --output $(output)/w_1p0_$${pthatmin}.h5 --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N w_1p0_$${pthatmin}; \
	done
	# shrink with jet mass
	for pthatmin in $$(seq 150 50 500); do \
		echo "$(setup) ./generate qcd.config --jet-size 1.2 --events 100000 --output $(output)/qcd_shrink_1p2_$${pthatmin}.h5 --shrink --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N qcd_shrink_1p2_$${pthatmin}; \
		echo "$(setup) ./generate w.config --jet-size 1.2 --events 100000 --output $(output)/w_shrink_1p2_$${pthatmin}.h5 --shrink --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N w_shrink_1p2_$${pthatmin}; \
		echo "$(setup) ./generate qcd.config --jet-size 1 --events 100000 --output $(output)/qcd_shrink_1p0_$${pthatmin}.h5 --shrink --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N qcd_shrink_1p0_$${pthatmin}; \
		echo "$(setup) ./generate w.config --jet-size 1 --events 100000 --output $(output)/w_shrink_1p0_$${pthatmin}.h5 --shrink --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N w_shrink_1p0_$${pthatmin}; \
	done
	# shrink with W mass
	for pthatmin in $$(seq 150 50 500); do \
		echo "$(setup) ./generate qcd.config --jet-size 1.2 --events 100000 --output $(output)/qcd_shrink_wmass_1p2_$${pthatmin}.h5 --shrink --shrink-mass $(WMASS) --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N qcd_shrink_wmass_1p2_$${pthatmin}; \
		echo "$(setup) ./generate w.config --jet-size 1.2 --events 100000 --output $(output)/w_shrink_wmass_1p2_$${pthatmin}.h5 --shrink --shrink-mass $(WMASS) --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N w_shrink_wmass_1p2_$${pthatmin}; \
		echo "$(setup) ./generate qcd.config --jet-size 1 --events 100000 --output $(output)/qcd_shrink_wmass_1p0_$${pthatmin}.h5 --shrink --shrink-mass $(WMASS) --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N qcd_shrink_wmass_1p0_$${pthatmin}; \
		echo "$(setup) ./generate w.config --jet-size 1 --events 100000 --output $(output)/w_shrink_wmass_1p0_$${pthatmin}.h5 --shrink --shrink-mass $(WMASS) --seed $${pthatmin} --params \"PhaseSpace:pTHatMin = $${pthatmin}\"" | qsub -e $(output)/log -o $(output)/log -N w_shrink_wmass_1p0_$${pthatmin}; \
	done

images:
	mkdir -p $(output)/log
	for chunk in $$(seq 1 1 10); do \
		echo "$(setup) ./generate_images w.config $(output)/w_images.h5 --events 10000 --jobs 4" | qsub -e $(output)/log -o $(output)/log -N w_images_$${chunk} -l nodes=1:ppn=4; \
	done
	for chunk in $$(seq 1 1 10); do \
		echo "$(setup) ./generate_images qcd.config $(output)/qcd_images.h5 --events 10000 --jobs 4" | qsub -e $(output)/log -o $(output)/log -N qcd_images_$${chunk} -l nodes=1:ppn=4; \
	done

w-images-no-batch:
	mkdir -p $(output)/log
	for chunk in $$(seq 1 1 10); do \
		./generate_images w.config $(output)/w_images.h5 --events 10000 --jobs 10; \
	done

qcd-images-no-batch:
	mkdir -p $(output)/log
	for chunk in $$(seq 1 1 10); do \
		./generate_images qcd.config $(output)/qcd_images.h5 --events 10000 --jobs 10; \
	done
