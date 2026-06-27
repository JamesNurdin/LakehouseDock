from __future__ import annotations

import logging
import re
import os
import subprocess
import socket
from dataclasses import dataclass, field
from datetime import datetime
from typing import Dict, List, Optional

import csv
from pathlib import Path

import json
from urllib.request import urlopen


# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# -----------------------------------------------------------------------------
# Hardcoded benchmark flags
# -----------------------------------------------------------------------------

@dataclass(frozen=True)
class ProfilerBenchmarkConfig:
    # CPU
    enable_cpu_metadata: bool = True
    enable_cpu_st_benchmark: bool = True
    enable_cpu_mt_benchmark: bool = True

    # RAM
    enable_ram_metadata: bool = True
    enable_ram_speed_benchmark: bool = True

    # IO / Ceph / shared storage
    enable_io_benchmark: bool = True
    enable_ceph_sequential_read: bool = True
    enable_ceph_random_read: bool = True

    # Network
    enable_network_benchmark: bool = True
    enable_network_mesh_csv: bool = True


# Change these values manually depending on the run you want.
BENCHMARK_CONFIG = ProfilerBenchmarkConfig(
    enable_cpu_metadata=False,
    enable_cpu_st_benchmark=True,
    enable_cpu_mt_benchmark=True,

    enable_ram_metadata=False,
    enable_ram_speed_benchmark=True,

    enable_io_benchmark=True,
    enable_ceph_sequential_read=True,
    enable_ceph_random_read=False,

    enable_network_benchmark=False,
    enable_network_mesh_csv=False,
)


# -----------------------------------------------------------------------------
# Exceptions
# -----------------------------------------------------------------------------

class ProcessErrorException(RuntimeError):
    pass


# -----------------------------------------------------------------------------
# Unit conversion
# Mirrors UnitConverter.groovy
# -----------------------------------------------------------------------------

class UnitConverter:
    @staticmethod
    def convert_unit_string_to_bytes(s: str) -> Optional[int]:
        s = s.strip()
        if "KiB" in s:
            return round(float(s.split(" KiB")[0]) * 1024)
        elif "MiB" in s:
            return round(float(s.split(" MiB")[0]) * 1024 * 1024)
        elif "GiB" in s:
            return round(float(s.split(" GiB")[0]) * 1024 * 1024 * 1024)
        elif "KB" in s:
            return round(float(s.split(" KB")[0]) * 1000)
        elif "MB" in s:
            return round(float(s.split(" MB")[0]) * 1000 * 1000)
        elif "GB" in s:
            return round(float(s.split(" GB")[0]) * 1000 * 1000 * 1000)
        return None

    @staticmethod
    def convert_unit_string_to_mb(s: str) -> Optional[float]:
        s = s.strip()
        if "KiB" in s:
            return round(float(s.split(" KiB")[0]) / 976.5625, 2)
        elif "MiB" in s:
            return round(float(s.split(" MiB")[0]) / 1.048576, 2)
        elif "GiB" in s:
            return round(float(s.split(" GiB")[0]) * 1073.741824, 2)
        elif "KB" in s:
            return round(float(s.split(" KB")[0]) / 1000, 2)
        elif "MB" in s:
            return round(float(s.split(" MB")[0]), 2)
        elif "GB" in s:
            return round(float(s.split(" GB")[0]) * 1000, 2)
        return None

    @staticmethod
    def convert_unit_string_to_gb(s: str) -> Optional[float]:
        s = s.strip()
        if "KiB" in s:
            return round(float(s.split(" KiB")[0]) * 1.024e-6, 4)
        elif "MiB" in s:
            return round(float(s.split(" MiB")[0]) * 0.001048576, 4)
        elif "GiB" in s:
            return round(float(s.split(" GiB")[0]) * 1.073741824, 4)
        elif "KB" in s:
            return round(float(s.split(" KB")[0]) / 1000 / 1000, 4)
        elif "MB" in s:
            return round(float(s.split(" MB")[0]) / 1000, 4)
        elif "GB" in s:
            return round(float(s.split(" GB")[0]), 4)
        return None


# -----------------------------------------------------------------------------
# Entity-like dataclasses
# -----------------------------------------------------------------------------

@dataclass
class CPURepresentation:
    architecture: Optional[str] = None
    cpus: Optional[int] = None
    thread_per_core: Optional[str] = None
    cores_per_socket: Optional[str] = None
    sockets: Optional[str] = None
    model_name: Optional[str] = None
    l1d_cache: Optional[int] = None
    l1i_cache: Optional[int] = None
    l2_cache: Optional[int] = None
    l3_cache: Optional[int] = None
    cpu_speed_st_events_per_second: Optional[float] = None
    cpu_speed_mt_events_per_second: Optional[float] = None

    def update_cpu(self, other: "CPURepresentation") -> None:
        self.__dict__.update(other.__dict__)


@dataclass
class RAMModule:
    size: Optional[str] = None
    speed: Optional[str] = None
    total_width: Optional[str] = None
    memory_width: Optional[str] = None


@dataclass
class RAMRepresentation:
    ram_speed: Optional[float] = None
    total_ram_bytes: Optional[int] = None
    rammodule: List[RAMModule] = field(default_factory=list)

    def update_ram(self, other: Optional["RAMRepresentation"]) -> None:
        if other is None:
            return
        self.__dict__.update(other.__dict__)


@dataclass
class IORepresentation:
    ceph_sequ_read_iops: Optional[float] = None
    ceph_sequ_read_bw: Optional[float] = None
    ceph_sequ_read_lat_us: Optional[float] = None
    ceph_rand_read_iops: Optional[float] = None
    ceph_rand_read_bw: Optional[float] = None
    ceph_rand_read_lat_us: Optional[float] = None

    def update_io(self, other: "IORepresentation") -> None:
        self.__dict__.update(other.__dict__)


@dataclass
class NetworkRepresentation:
    avg_rtt_ms: Optional[float] = None
    avg_bandwidth_mbps: Optional[float] = None
    targets_profiled: Optional[int] = None

    def update_network(self, other: "NetworkRepresentation") -> None:
        self.__dict__.update(other.__dict__)


@dataclass
class NodeRepresentation:
    node_ip: str
    node_name: Optional[str]
    pod_name: Optional[str]
    query_id: Optional[str]
    profile_type: Optional[str]
    profile_launched_at: Optional[str]
    cpu: CPURepresentation
    ram: RAMRepresentation
    io: IORepresentation
    network: NetworkRepresentation
    last_modified_date: datetime = field(default_factory=datetime.utcnow)


def flatten_node_representation(node: NodeRepresentation) -> dict:
    return {
        "query_id": node.query_id,
        "profile_type": node.profile_type,
        "node_name": node.node_name,
        "node_ip": node.node_ip,
        "pod_name": node.pod_name,
        "last_modified_date": node.last_modified_date.isoformat(),
        "profile_launched_at": node.profile_launched_at,

        "cpu_architecture": node.cpu.architecture,
        "cpu_cpus": node.cpu.cpus,
        "cpu_thread_per_core": node.cpu.thread_per_core,
        "cpu_cores_per_socket": node.cpu.cores_per_socket,
        "cpu_sockets": node.cpu.sockets,
        "cpu_model_name": node.cpu.model_name,
        "cpu_l1d_cache": node.cpu.l1d_cache,
        "cpu_l1i_cache": node.cpu.l1i_cache,
        "cpu_l2_cache": node.cpu.l2_cache,
        "cpu_l3_cache": node.cpu.l3_cache,
        "cpu_speed_st_events_per_second": node.cpu.cpu_speed_st_events_per_second,
        "cpu_speed_mt_events_per_second": node.cpu.cpu_speed_mt_events_per_second,

        "ram_speed_gb_s": node.ram.ram_speed,
        "ram_total_bytes": node.ram.total_ram_bytes,

        "ceph_io_sequ_read_iops": node.io.ceph_sequ_read_iops,
        "ceph_io_sequ_read_bw_mb": node.io.ceph_sequ_read_bw,
        "ceph_io_rand_read_iops": node.io.ceph_rand_read_iops,
        "ceph_io_rand_read_bw_mb": node.io.ceph_rand_read_bw,
        "ceph_io_sequ_read_lat_us": node.io.ceph_sequ_read_lat_us,
        "ceph_io_rand_read_lat_us": node.io.ceph_rand_read_lat_us,

        "network_avg_rtt_ms": node.network.avg_rtt_ms,
        "network_targets_profiled": node.network.targets_profiled,
    }


def append_node_representation_to_csv(node: NodeRepresentation, csv_path: str | Path) -> None:
    csv_path = Path(csv_path)
    row = flatten_node_representation(node)

    write_header = not csv_path.exists()

    with csv_path.open("a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(row.keys()))
        if write_header:
            writer.writeheader()
        writer.writerow(row)


class NodeRepresentationRepository:
    def __init__(self) -> None:
        self._store: Dict[str, NodeRepresentation] = {}

    def find_by_id(self, node_ip: str) -> Optional[NodeRepresentation]:
        return self._store.get(node_ip)

    def save(self, node_representation: NodeRepresentation) -> NodeRepresentation:
        self._store[node_representation.node_ip] = node_representation
        return node_representation


# -----------------------------------------------------------------------------
# Process executor helper
# Mirrors ProcessExecutorHelperService.groovy
# -----------------------------------------------------------------------------

class ProcessExecutorHelperService:
    def execute_process(self, command: str, waiting_time_ms: int) -> Optional[str]:
        logger.info("Execute '%s' with waitingTime %s", command, waiting_time_ms)
        timeout_s = waiting_time_ms / 1000.0

        try:
            proc = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout_s,
            )
        except subprocess.TimeoutExpired as exc:
            logger.error("Timeout executing: %s", command)
            raise ProcessErrorException(f"Command timed out: {command}") from exc
        except Exception as exc:
            logger.error("Error executing: %s", command)
            raise ProcessErrorException(f"Failed to execute: {command}") from exc

        stdout = proc.stdout or ""
        stderr = proc.stderr or ""

        if stdout.strip():
            return stdout

        logger.error(
            "There was an error executing: '%s' with waitingTime %s. stderr=%s",
            command,
            waiting_time_ms,
            stderr.strip(),
        )
        return None


# -----------------------------------------------------------------------------
# Network service
# -----------------------------------------------------------------------------

class NetworkRepresentationService:
    def __init__(
        self,
        process_executor_helper_service: ProcessExecutorHelperService,
        config: ProfilerBenchmarkConfig,
    ) -> None:
        self.process_executor_helper_service = process_executor_helper_service
        self.config = config

    def _fetch_cluster_node_map(self) -> dict[str, str]:
        """Fetch physical node IPs and map them to node names."""
        url = "http://usage.apps.os.dcs.gla.ac.uk/?format=json"
        node_map = {}

        try:
            logger.info("Fetching physical host nodes from %s", url)
            with urlopen(url, timeout=10) as resp:
                data = json.loads(resp.read().decode("utf-8"))

            for item in data.get("node_usage", []):
                node_name = item.get("node_name")
                if node_name:
                    try:
                        ip = socket.gethostbyname(node_name)
                        node_map[ip] = node_name
                    except socket.error:
                        continue

            logger.info("Successfully resolved %d physical node mappings.", len(node_map))

        except Exception as e:
            logger.error("Failed to fetch cluster node map: %s", e)

        return node_map

    def _write_mesh_csv(self, mesh_data: list[dict]) -> None:
        """Write 1:1 host RTT metrics."""
        if not mesh_data:
            return

        mesh_dir = Path("/mnt/primary/Main/profile_cluster/results/mesh")
        mesh_dir.mkdir(parents=True, exist_ok=True)

        my_node_name = os.getenv("MY_NODE_NAME", "unknown-node").replace("/", "_")
        mesh_file = mesh_dir / f"{my_node_name}_host_network_mesh.csv"

        write_header = not mesh_file.exists()
        fieldnames = [
            "timestamp",
            "source_node",
            "target_node_name",
            "target_node_ip",
            "rtt_ms",
        ]

        with mesh_file.open("a", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            if write_header:
                writer.writeheader()
            writer.writerows(mesh_data)

        logger.info("Appended %d host links to %s", len(mesh_data), mesh_file.name)

    def tcp_ping(self, target_ip: str, port: int = 22, count: int = 3) -> Optional[float]:
        import time

        rtts = []

        for _ in range(count):
            try:
                start_time = time.perf_counter()
                with socket.create_connection((target_ip, port), timeout=1.0):
                    end_time = time.perf_counter()
                rtts.append((end_time - start_time) * 1000)
            except (socket.timeout, ConnectionRefusedError, socket.error):
                continue

        if not rtts:
            return None

        return round(sum(rtts) / len(rtts), 3)

    def create_network_representation(self) -> NetworkRepresentation:
        logger.info("In create_network_representation()")

        if not self.config.enable_network_benchmark:
            logger.info("Network benchmark disabled")
            return NetworkRepresentation()

        node_map = self._fetch_cluster_node_map()

        if not node_map:
            return NetworkRepresentation()

        rtts = []
        mesh_data = []
        my_node_name = os.getenv("MY_NODE_NAME", "unknown-node")
        test_port = 22

        for target_ip, target_name in node_map.items():
            try:
                if target_ip == socket.gethostbyname(socket.gethostname()):
                    continue
            except Exception:
                pass

            avg_rtt = self.tcp_ping(target_ip, port=test_port)

            if avg_rtt is not None:
                rtts.append(avg_rtt)
                mesh_data.append({
                    "timestamp": datetime.utcnow().isoformat(),
                    "source_node": my_node_name,
                    "target_node_name": target_name,
                    "target_node_ip": target_ip,
                    "rtt_ms": avg_rtt,
                })

        if self.config.enable_network_mesh_csv:
            self._write_mesh_csv(mesh_data)
        else:
            logger.info("Network mesh CSV output disabled")

        if not rtts:
            return NetworkRepresentation(targets_profiled=0)

        cluster_avg_rtt = round(sum(rtts) / len(rtts), 3)

        return NetworkRepresentation(
            avg_rtt_ms=cluster_avg_rtt,
            targets_profiled=len(rtts),
        )


# -----------------------------------------------------------------------------
# CPU service
# Mirrors CPURepresentationService.groovy
# -----------------------------------------------------------------------------

class CPURepresentationService:
    def __init__(
        self,
        process_executor_helper_service: ProcessExecutorHelperService,
        config: ProfilerBenchmarkConfig,
    ) -> None:
        self.process_executor_helper_service = process_executor_helper_service
        self.config = config

    def create_cpu_representation(self) -> CPURepresentation:
        logger.info("In create_cpu_representation()")

        if not self.config.enable_cpu_metadata:
            logger.info("CPU metadata collection disabled")

            cpu = CPURepresentation()

            if self.config.enable_cpu_st_benchmark:
                cpu.cpu_speed_st_events_per_second = self.test_cpu_st()

            if self.config.enable_cpu_mt_benchmark:
                cpu.cpu_speed_mt_events_per_second = self.test_cpu_mt(1)

            return cpu

        sout = self.process_executor_helper_service.execute_process("lscpu", 5000)

        if not sout:
            raise ProcessErrorException("lscpu produced no output")

        return self.map_lscpu_to_cpu_representation(sout)

    def map_lscpu_to_cpu_representation(self, lscpu_output: str) -> CPURepresentation:
        logger.info("Mapping lscpu output to CPURepresentation")

        cpu = CPURepresentation()

        for line in lscpu_output.splitlines():
            if "Architecture:" in line:
                cpu.architecture = line.split(":", 1)[1].strip()
            elif (
                "CPU(s):" in line
                and "On-line" not in line
                and "NUMA" not in line
            ):
                cpu.cpus = int(line.split(":", 1)[1].strip())
            elif "Thread(s) per core:" in line:
                cpu.thread_per_core = line.split(":", 1)[1].strip()
            elif "Core(s) per socket:" in line:
                cpu.cores_per_socket = line.split(":", 1)[1].strip()
            elif "Socket(s):" in line:
                cpu.sockets = line.split(":", 1)[1].strip()
            elif "Model name:" in line:
                cpu.model_name = line.split(":", 1)[1].strip()
            elif "L1d cache:" in line:
                cpu.l1d_cache = UnitConverter.convert_unit_string_to_bytes(
                    line.split(":", 1)[1].strip()
                )
            elif "L1i cache:" in line:
                cpu.l1i_cache = UnitConverter.convert_unit_string_to_bytes(
                    line.split(":", 1)[1].strip()
                )
            elif "L2 cache:" in line:
                cpu.l2_cache = UnitConverter.convert_unit_string_to_bytes(
                    line.split(":", 1)[1].strip()
                )
            elif "L3 cache:" in line:
                cpu.l3_cache = UnitConverter.convert_unit_string_to_bytes(
                    line.split(":", 1)[1].strip()
                )

        if self.config.enable_cpu_st_benchmark:
            cpu.cpu_speed_st_events_per_second = self.test_cpu_st()
        else:
            logger.info("CPU single-thread benchmark disabled")

        if self.config.enable_cpu_mt_benchmark:
            cpu.cpu_speed_mt_events_per_second = self.test_cpu_mt(cpu.cpus or 1)
        else:
            logger.info("CPU multi-thread benchmark disabled")

        return cpu

    def test_cpu_st(self) -> Optional[float]:
        if not self.config.enable_cpu_st_benchmark:
            return None

        logger.info("Testing CPU single-thread speed")

        sout = self.process_executor_helper_service.execute_process(
            "sysbench cpu --num-threads=1 --cpu-max-prime=20000 run",
            20000,
        )

        if not sout:
            raise ProcessErrorException("sysbench single-thread produced no output")

        for line in sout.splitlines():
            if "events per second:" in line.lower():
                return float(line.split(":", 1)[1].strip())

        return None

    def test_cpu_mt(self, number_cpus: int) -> Optional[float]:
        if not self.config.enable_cpu_mt_benchmark:
            return None

        logger.info("Testing CPU multi-thread speed")

        sout = self.process_executor_helper_service.execute_process(
            f"sysbench cpu --num-threads={number_cpus} --cpu-max-prime=20000 run",
            20000,
        )

        if not sout:
            raise ProcessErrorException("sysbench multi-thread produced no output")

        for line in sout.splitlines():
            if "events per second:" in line.lower():
                return float(line.split(":", 1)[1].strip())

        return None


# -----------------------------------------------------------------------------
# RAM service
# Mirrors RAMRepresentationService.groovy
# -----------------------------------------------------------------------------

class RAMRepresentationService:
    def __init__(
        self,
        process_executor_helper_service: ProcessExecutorHelperService,
        config: ProfilerBenchmarkConfig,
    ) -> None:
        self.process_executor_helper_service = process_executor_helper_service
        self.config = config

    def create_ram_representation(self) -> RAMRepresentation:
        logger.info("In create_ram_representation()")

        ram_speed = None
        total_ram_bytes = None

        if self.config.enable_ram_speed_benchmark:
            try:
                ram_speed = self.test_ram_speed()
            except Exception as e:
                logger.warning("RAM speed benchmark failed: %s", e)
        else:
            logger.info("RAM speed benchmark disabled")

        if self.config.enable_ram_metadata:
            try:
                total_ram_bytes = self.get_total_ram_bytes()
            except Exception as e:
                logger.warning("Reading total RAM failed: %s", e)
        else:
            logger.info("RAM metadata collection disabled")

        return RAMRepresentation(
            ram_speed=ram_speed,
            total_ram_bytes=total_ram_bytes,
            rammodule=[],
        )

    def test_ram_speed(self) -> Optional[float]:
        if not self.config.enable_ram_speed_benchmark:
            return None

        logger.info("Testing RAM speed")

        sout = self.process_executor_helper_service.execute_process(
            "sysbench --test=memory --memory-block-size=64M --memory-total-size=64G --num-threads=1 run",
            15000,
        )

        if not sout:
            raise ProcessErrorException("sysbench memory test produced no output")

        for line in sout.splitlines():
            if "transferred" in line.lower():
                part = line.split("(", 1)[1].strip().rstrip(")")
                return UnitConverter.convert_unit_string_to_gb(part)

        raise ProcessErrorException("Could not parse RAM speed from sysbench output")

    def get_total_ram_bytes(self) -> Optional[int]:
        if not self.config.enable_ram_metadata:
            return None

        logger.info("Reading total RAM from /proc/meminfo")

        with open("/proc/meminfo", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    parts = line.split()
                    mem_kb = int(parts[1])
                    return mem_kb * 1024

        raise ProcessErrorException("MemTotal not found in /proc/meminfo")


# -----------------------------------------------------------------------------
# IO service
# Mirrors IORepresentationService.groovy
# -----------------------------------------------------------------------------

class IORepresentationService:
    def __init__(
        self,
        process_executor_helper_service: ProcessExecutorHelperService,
        config: ProfilerBenchmarkConfig,
    ) -> None:
        self.process_executor_helper_service = process_executor_helper_service
        self.config = config

    def create_io_representation(self) -> IORepresentation:
        logger.info("In create_io_representation()")

        io_rep = IORepresentation()

        if not self.config.enable_io_benchmark:
            logger.info("IO benchmark disabled")
            return io_rep

        try:
            ceph_dir = "/mnt/iceberg-ssb-1tb/profiling"

            ceph_seq = None
            ceph_rand = None

            if self.config.enable_ceph_sequential_read:
                ceph_seq = self.read_io_specs_sequ(
                    ceph_dir,
                    size="1G",
                    job_prefix="ceph_seqrw",
                )
            else:
                logger.info("Ceph sequential read benchmark disabled")

            if self.config.enable_ceph_random_read:
                ceph_rand = self.read_io_specs_rand(
                    ceph_dir,
                    size="250M",
                    job_prefix="ceph_randrw",
                )
            else:
                logger.info("Ceph random read benchmark disabled")

            self.map_fio_to_io_representation(
                ceph_seq,
                ceph_rand,
                io_rep,
                prefix="ceph",
            )

        except Exception as e:
            logger.warning("Ceph/shared IO profiling failed: %s", e)

        return io_rep

    @staticmethod
    def _fio_bw_to_mb(bw_bytes_per_s: Optional[float]) -> Optional[float]:
        if bw_bytes_per_s is None:
            return None
        return round(float(bw_bytes_per_s) / 1_000_000, 2)

    @staticmethod
    def _fio_lat_to_us(read_section: dict) -> Optional[float]:
        """
        Prefer clat mean if present. fio JSON may report latency in ns/us/ms buckets.
        Convert to microseconds.
        """
        for key, scale in (
            ("clat_ns", 1 / 1000.0),
            ("clat_us", 1.0),
            ("clat_ms", 1000.0),
        ):
            block = read_section.get(key)
            if isinstance(block, dict) and block.get("mean") is not None:
                return round(float(block["mean"]) * scale, 3)
        return None

    def map_fio_to_io_representation(
        self,
        io_sequ: Optional[str],
        io_rand: Optional[str],
        io_rep: IORepresentation,
        prefix: str,
    ) -> None:
        logger.info("Mapping fio output to IORepresentation for prefix=%s", prefix)

        if io_sequ is not None:
            seq_obj = json.loads(io_sequ)
            seq_read = seq_obj["jobs"][0]["read"]

            setattr(io_rep, f"{prefix}_sequ_read_iops", float(seq_read.get("iops", 0.0)))
            setattr(io_rep, f"{prefix}_sequ_read_bw", self._fio_bw_to_mb(seq_read.get("bw_bytes")))
            setattr(io_rep, f"{prefix}_sequ_read_lat_us", self._fio_lat_to_us(seq_read))

        if io_rand is not None:
            rand_obj = json.loads(io_rand)
            rand_read = rand_obj["jobs"][0]["read"]

            setattr(io_rep, f"{prefix}_rand_read_iops", float(rand_read.get("iops", 0.0)))
            setattr(io_rep, f"{prefix}_rand_read_bw", self._fio_bw_to_mb(rand_read.get("bw_bytes")))
            setattr(io_rep, f"{prefix}_rand_read_lat_us", self._fio_lat_to_us(rand_read))

    def read_io_specs_sequ(self, fio_work_dir: str, size: str, job_prefix: str) -> str:
        logger.info("Testing IO sequential read in %s", fio_work_dir)

        os.makedirs(fio_work_dir, exist_ok=True)

        node_name = os.getenv("MY_NODE_NAME", "unknown-node")
        fio_file = f"{fio_work_dir}/{job_prefix}_{node_name}.dat"

        sout = self.process_executor_helper_service.execute_process(
            f"fio --name={job_prefix} --filename={fio_file} --rw=read --direct=1 "
            f"--ioengine=libaio --bs=1M --iodepth=64 --size={size} --output-format=json",
            240000,
        )

        if not sout:
            raise ProcessErrorException("fio sequential test produced no output")

        return sout

    def read_io_specs_rand(self, fio_work_dir: str, size: str, job_prefix: str) -> str:
        logger.info("Testing IO random read in %s", fio_work_dir)

        os.makedirs(fio_work_dir, exist_ok=True)

        node_name = os.getenv("MY_NODE_NAME", "unknown-node")
        fio_file = f"{fio_work_dir}/{job_prefix}_{node_name}.dat"

        sout = self.process_executor_helper_service.execute_process(
            f"fio --name={job_prefix} --filename={fio_file} --rw=randread --direct=1 "
            f"--ioengine=libaio --bs=128k --iodepth=64 --size={size} --randrepeat=1 "
            "--output-format=json",
            240000,
        )

        if not sout:
            raise ProcessErrorException("fio random test produced no output")

        return sout


# -----------------------------------------------------------------------------
# Node profiler service
# Mirrors NodeProfilerService.groovy
# -----------------------------------------------------------------------------

class NodeProfilerService:
    def __init__(
        self,
        node_representation_repository: NodeRepresentationRepository,
        cpu_representation_service: CPURepresentationService,
        ram_representation_service: RAMRepresentationService,
        io_representation_service: IORepresentationService,
        process_executor_helper_service: ProcessExecutorHelperService,
        network_representation_service: NetworkRepresentationService,
    ) -> None:
        self.node_representation_repository = node_representation_repository
        self.cpu_representation_service = cpu_representation_service
        self.ram_representation_service = ram_representation_service
        self.io_representation_service = io_representation_service
        self.network_representation_service = network_representation_service
        self.process_executor_helper_service = process_executor_helper_service

    def get_node_name(self) -> Optional[str]:
        logger.info("Getting Kubernetes node name")
        return os.environ.get("MY_NODE_NAME")

    def get_pod_name(self) -> Optional[str]:
        logger.info("Getting Kubernetes pod name")
        return os.environ.get("MY_POD_NAME")

    def gather_node_hardware_information(self) -> NodeRepresentation:
        logger.info("Start collection hardware information")

        node_ip = self.get_node_ip().strip()
        node_name = self.get_node_name()
        pod_name = self.get_pod_name()

        profile_launched_at = os.getenv("PROFILE_LAUNCHED_AT")
        query_id = os.getenv("PROFILE_QUERY_ID")
        profile_type = os.getenv("PROFILE_PHASE")

        existing = self.node_representation_repository.find_by_id(node_ip)

        if existing is not None:
            logger.info("Information for this IP address already exists. Updating")

            existing.node_name = node_name
            existing.pod_name = pod_name
            existing.query_id = query_id
            existing.profile_type = profile_type
            existing.profile_launched_at = profile_launched_at

            existing.cpu.update_cpu(
                self.cpu_representation_service.create_cpu_representation()
            )
            existing.ram.update_ram(
                self.ram_representation_service.create_ram_representation()
            )
            existing.network.update_network(
                self.network_representation_service.create_network_representation()
            )
            existing.io.update_io(
                self.io_representation_service.create_io_representation()
            )

            node_representation = existing

        else:
            logger.info("Collecting information for a new IP address")

            node_representation = NodeRepresentation(
                node_ip=node_ip,
                node_name=node_name,
                pod_name=pod_name,
                query_id=query_id,
                profile_type=profile_type,
                profile_launched_at=profile_launched_at,
                cpu=self.cpu_representation_service.create_cpu_representation(),
                ram=self.ram_representation_service.create_ram_representation(),
                network=self.network_representation_service.create_network_representation(),
                io=self.io_representation_service.create_io_representation(),
            )

        node_representation.last_modified_date = datetime.utcnow()

        logger.info("Saving NodeRepresentation to repository")
        rep = self.node_representation_repository.save(node_representation)
        logger.info("Saved successfully NodeRepresentation: %s", rep)

        return rep

    def get_node_ip(self) -> str:
        logger.info("Getting node IP")

        try:
            out = self.process_executor_helper_service.execute_process(
                "hostname -i",
                5000,
            )
            if out and out.strip():
                return out.strip().split()[0]
        except Exception as e:
            logger.warning("hostname -i failed: %s", e)

        try:
            return socket.gethostbyname(socket.gethostname())
        except Exception as e:
            logger.warning("socket hostname lookup failed: %s", e)

        logger.warning("Falling back to unknown node IP")
        return "unknown"


# -----------------------------------------------------------------------------
# Example usage
# -----------------------------------------------------------------------------

if __name__ == "__main__":
    repo = NodeRepresentationRepository()
    executor = ProcessExecutorHelperService()
    config = BENCHMARK_CONFIG

    cpu_service = CPURepresentationService(executor, config)
    ram_service = RAMRepresentationService(executor, config)
    io_service = IORepresentationService(executor, config)
    network_service = NetworkRepresentationService(executor, config)

    profiler = NodeProfilerService(
        node_representation_repository=repo,
        cpu_representation_service=cpu_service,
        ram_representation_service=ram_service,
        io_representation_service=io_service,
        network_representation_service=network_service,
        process_executor_helper_service=executor,
    )

    results_dir = os.getenv(
        "PROFILE_OUT_DIR",
        "/mnt/primary/Main/profile_cluster/results",
    )
    os.makedirs(results_dir, exist_ok=True)

    node_name = os.getenv("MY_NODE_NAME", "unknown-node")
    safe_node_name = node_name.replace("/", "_")

    try:
        node_profile = profiler.gather_node_hardware_information()

        append_node_representation_to_csv(
            node_profile,
            Path(results_dir, f"{safe_node_name}_node_profiles.csv").resolve(),
        )

        print(node_profile)

    except Exception as e:
        logger.exception("Profiling failed: %s", e)
        raise