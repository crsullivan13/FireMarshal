import socket
import logging
from .wlutil import *

# The amount of memory to use when launching
launch_mem = "16384"
launch_cores = "4"

# Kinda hacky (technically not guaranteed to give a free port, just very likely)
def get_free_tcp_port():
	tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	tcp.bind(('', 0))
	addr, port = tcp.getsockname()
	tcp.close()
	return str(port)

# Returns a command string to luanch the given config in spike. Must be called with shell=True.
def getSpikeCmd(config, nodisk=False):
    if 'spike' in config:
        spikeBin = config['spike']
    else:
        spikeBin = 'spike'

    if nodisk:
        return str(spikeBin) + " " + config.get('spike-args', '') + ' -p' + launch_cores + ' -m' + launch_mem + " " + str(config['bin']) + '-nodisk'
    elif 'img' not in config:
        return str(spikeBin) + " " + config.get('spike-args', '') + ' -p' + launch_cores + ' -m' + launch_mem + " " + str(config['bin'])
    else:
        raise ValueError("Spike does not support disk-based configurations")

# Returns a command string to luanch the given config in qemu. Must be called with shell=True.
def getQemuCmd(config, nodisk=False):
    log = logging.getLogger()

    launch_port = get_free_tcp_port()

    if nodisk:
        exe = config['bin'] + '-nodisk'
    else:
        exe = config['bin']

    cmd = ['qemu-system-riscv64',
           '-nographic',
           '-bios none',
           '-smp', launch_cores,
           '-machine', 'virt',
           '-m', launch_mem,
           '-kernel', str(exe),
           '-object', 'rng-random,filename=/dev/urandom,id=rng0',
           '-device', 'virtio-rng-device,rng=rng0',
           '-device', 'virtio-net-device,netdev=usernet',
           '-netdev', 'user,id=usernet,hostfwd=tcp::' + launch_port + '-:22']

    if 'img' in config and not nodisk:
        cmd = cmd + ['-device', 'virtio-blk-device,drive=hd0',
                     '-drive', 'file=' + str(config['img']) + ',format=raw,id=hd0']

    return " ".join(cmd) + " " + config.get('qemu-args', '')

def launchWorkload(cfgName, cfgs, job='all', spike=False, interactive=True):
    """Launches the specified workload in functional simulation.

    cfgName: unique name of the workload in the cfgs
    cfgs: initialized configuration (contains all possible workloads)
    job: Which job to launch. 'all' launches the parent of all the jobs (i.e. the base workload).
    spike: Use spike instead of the default qemu as the functional simulator
    interactive: If true, the output from the simulator will be displayed to
        stdout. If false, only the uartlog will be written (it is written live and
        unbuffered so users can still 'tail' the output if they'd like).

    Returns: Path of output directory
    """
    log = logging.getLogger()
    baseConfig = cfgs[cfgName]

    # Bare-metal tests don't work on qemu yet
    if baseConfig.get('distro') == 'bare' and spike != True:
        raise RuntimeError("Bare-metal workloads do not currently support Qemu. Please run this workload under spike.")

    if 'jobs' in baseConfig.keys() and job != 'all':
        # Run the specified job
        config = cfgs[cfgName]['jobs'][job]
    else:
        # Run the base image
        config = cfgs[cfgName]
 
    if config['launch']:
        baseResDir = getOpt('res-dir') / getOpt('run-name')
        runResDir = baseResDir / config['name']
        uartLog = runResDir / "uartlog"
        os.makedirs(runResDir)

        if spike:
            if 'img' in config and not config['nodisk']:
                sys.exit("Spike currently does not support disk-based " +
                        "configurations. Please use an initramfs based image.")
            cmd = getSpikeCmd(config, config['nodisk'])
        else:
            cmd = getQemuCmd(config, config['nodisk'])

        log.info("Running: " + "".join(cmd))
        if not interactive:
            log.info("For live output see: " + str(uartLog))
        with open(uartLog, 'wb', buffering=0) as uartF:
            with sp.Popen(cmd.split(), stderr=sp.STDOUT, stdout=sp.PIPE) as p:
                    for c in iter(lambda: p.stdout.read(1), b''):
                        if interactive:
                            sys.stdout.buffer.write(c)
                            sys.stdout.flush()
                        uartF.write(c)

        if 'outputs' in config:
            outputSpec = [ FileSpec(src=f, dst=runResDir) for f in config['outputs']] 
            copyImgFiles(config['img'], outputSpec, direction='out')

        if 'post_run_hook' in config:
            log.info("Running post_run_hook script: " + str(config['post_run_hook']))
            try:
                run([config['post_run_hook'], baseResDir], cwd=config['workdir'])
            except sp.CalledProcessError as e:
                log.info("\nRun output available in: " + str(runResDir.parent))
                raise RuntimeError("Post run hook failed:\n" + e.output)

        return runResDir
    else:
        log.info("Workload launch skipped ('launch'=false in config)")
        return None


