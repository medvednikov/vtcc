import os

fn build_steps(vtccdir string) ! {
	mut deps := map[string]string{}
	cc_flag := if os.user_os() == 'macos' { ' -cc cc' } else { '' }
	gc_flag := if os.user_os() == 'macos' { ' -gc none' } else { '' }
	wflag := if os.user_os() == 'macos' { " -cflags '-Wno-int-conversion'" } else { '' }
	if os.user_os() != 'macos' {
		deps['building bt-log.o (tcc_backtrace symbol)'] = 'v -cg -keepc -d no_main -skip-unused -no-builtin -o bt-log.o lib/bt-log.v'
		deps['building bcheck.o: '] = 'v -d no_main -skip-unused -no-builtin -o bcheck.o lib/bcheck.v'
		deps['building bt-exe.o: '] = 'v -keepc -d no_main -skip-unused -no-builtin -o bt-exe.o lib/bt-exe.v'
		deps['building dso.o: '] = 'v -d no_main -skip-unused -no-builtin -o dso.o lib/dsohandle.v'
		deps['buildind libtcc1.o: '] = 'v -d no_main -no-builtin -o libtcc1.o lib/libtcc1/'
		deps['building vtcc.o: '] = 'v -d vtcc_dir=${vtccdir} -d no_main -skip-unused -o vtcc.o src/'
		deps['building libtcc1.a: '] = 'rm -f libtcc1.a && ar rcs libtcc1.a libtcc1.o bt-exe.o bt-log.o bcheck.o dso.o'
	} else {
		deps['building vtcc.o: '] = 'v -d vtcc_dir=${vtccdir} -d no_main -skip-unused${cc_flag}${gc_flag}${wflag} -o vtcc.o src/'
	}
	cg_flag := if os.user_os() == 'macos' { '' } else { ' -cg' }
	deps['buildind vtcc: '] = 'v${cg_flag} -skip-unused -d vtcc_dir=${vtccdir}${cc_flag}${gc_flag}${wflag} -o vtcc src/'

	os.execute('bash -c "rm -f *.a *.o"')

	for k, v in deps {
		eprint('${k}: ')
		res_btlog := os.execute(v)
		if res_btlog.exit_code == 0 {
			println('ok')
		} else {
			println('failed ${res_btlog.output}')
			return error('failed')
		}
	}
}

fn main() {
	base_path := os.args[1] or { os.getwd() }
	if !os.exists(base_path) {
		eprintln('error: base path must be supplied!')
		exit(1)
	}
	build_steps(base_path)!
}
