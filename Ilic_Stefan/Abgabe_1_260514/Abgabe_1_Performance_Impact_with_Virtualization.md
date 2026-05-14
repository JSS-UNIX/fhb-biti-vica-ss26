# Performance Impact with Virtualization

## Was ist Performance Impact with Virtualization?

Virtualisierung beschreibt die Technik, physische Hardwareressourcen durch eine Software-Schicht — den sogenannten **Hypervisor** — in mehrere logische Einheiten aufzuteilen. Jede dieser Einheiten, als **Virtuelle Maschine (VM)** bezeichnet, verhält sich aus Sicht des Betriebssystems wie echte physische Hardware. Diese Abstraktionsschicht bringt jedoch zwangsläufig einen **Leistungsverlust** mit sich, da CPU-Befehle, Speicherzugriffe und I/O-Operationen nicht mehr direkt auf der Hardware ausgeführt werden, sondern durch den Hypervisor vermittelt oder übersetzt werden müssen. Dieser Overhead — also der Mehraufwand durch Virtualisierung — wird als **Performance Impact** bezeichnet.

## Kontext und Einsatzgebiet

Virtualisierung ist heute in nahezu jedem Unternehmensrechenzentrum und bei allen großen Cloud-Anbietern (AWS, Azure, Google Cloud) der Standard. Server-Virtualisierung ermöglicht eine bessere Auslastung teurer Hardware, vereinfacht Backup und Disaster Recovery und erhöht die Flexibilität bei der Ressourcenzuteilung. Gleichzeitig setzen Entwickler Desktop-Virtualisierung (z.B. VirtualBox) für Tests und Entwicklungsumgebungen ein.

Da Anwendungen auf VMs dieselbe Leistung erwarten wie auf physischer Hardware, ist das Verständnis des Performance Impacts entscheidend — besonders bei **latenzempfindlichen Workloads** wie Datenbanken, HPC (High Performance Computing) oder Echtzeit-Systemen.

## Technische Funktionsweise

### Hypervisor-Typen

```
┌─────────────────────────────────────┐
│  Typ 1 — Bare-Metal Hypervisor      │
│  VM1 │ VM2 │ VM3                    │
│  ──────────────────                 │
│  Hypervisor (ESXi, Hyper-V, KVM)    │
│  ──────────────────                 │
│  Physische Hardware                 │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Typ 2 — Hosted Hypervisor          │
│  VM1 │ VM2                          │
│  ──────────────────                 │
│  Hypervisor (VirtualBox, VMware WS) │
│  ──────────────────                 │
│  Host-Betriebssystem                │
│  ──────────────────                 │
│  Physische Hardware                 │
└─────────────────────────────────────┘
```

Typ-1-Hypervisoren laufen direkt auf der Hardware und haben deutlich geringeren Overhead als Typ-2-Hypervisoren, die ein Host-OS als Zwischenschicht besitzen.

### CPU-Overhead

Moderne CPUs besitzen Hardware-Unterstützung für Virtualisierung: **Intel VT-x** (Virtualization Technology) und **AMD-V**. Diese erlauben es dem Hypervisor, privilegierte CPU-Instruktionen der VM direkt auf der Hardware auszuführen (sog. *Hardware-assisted Virtualization*), ohne diese aufwändig in Software emulieren zu müssen. Ohne diese Unterstützung — bei reiner Software-Emulation — kann der CPU-Overhead 20–40 % betragen, mit Hardware-Unterstützung reduziert er sich typischerweise auf **1–5 %**.

### Memory-Overhead

Die Speicherverwaltung ist eine der größten Quellen für Performance-Einbußen. Der Hypervisor muss eine zweistufige Adressübersetzung durchführen: von der virtuellen Adresse der VM über eine „Guest Physical Address" zur tatsächlichen Host-Adresse. Moderne CPUs lösen das mit **Extended Page Tables (EPT)** bei Intel bzw. **Nested Page Tables (NPT)** bei AMD, was den Overhead erheblich reduziert. Ohne diese Hardware-Unterstützung musste der Hypervisor sogenannte *Shadow Page Tables* im Software-Verfahren verwalten — ein sehr teurer Prozess.

Zusätzlich verursachen Techniken wie **Memory Ballooning** (dynamische Zuteilung von RAM zwischen VMs) und **Memory Deduplication** (Zusammenführen identischer Speicherseiten) Laufzeit-Overhead.

### I/O-Overhead

Festplatten- und Netzwerkzugriffe müssen ebenfalls durch den Hypervisor geleitet werden. Bei vollständiger Emulation (z.B. emulierte IDE-Festplatte) ist dieser Overhead sehr hoch. **Paravirtualisierung** löst dieses Problem: Die VM kennt ihre virtuelle Natur und verwendet optimierte Treiber (z.B. **VirtIO** unter KVM/QEMU), die direkt mit dem Hypervisor kommunizieren. Damit nähert sich die I/O-Leistung der nativen Hardware-Leistung an.

## Vergleich: Bare-Metal vs. VM vs. Container

| Merkmal | Bare-Metal | Virtuelle Maschine | Container (Docker) |
|---|---|---|---|
| CPU-Overhead | keiner | 1–5 % (HW-assist) | ~1 % |
| Memory-Overhead | keiner | mittel (EPT/NPT) | minimal |
| I/O-Overhead | keiner | niedrig (VirtIO) | sehr niedrig |
| Isolation | — | stark (eigener Kernel) | schwach (geteilter Kernel) |
| Startzeit | Minuten | Sekunden–Minuten | Millisekunden |
| Portabilität | gering | mittel | sehr hoch |

## Gängige Produkte, Tools und Hersteller

| Kategorie | Produkt / Tool | Hersteller |
|---|---|---|
| Typ-1 Hypervisor | VMware ESXi / vSphere | Broadcom (ehem. VMware) |
| Typ-1 Hypervisor | Microsoft Hyper-V | Microsoft |
| Typ-1 Hypervisor | KVM (Kernel-based VM) | Open Source (Linux) |
| Typ-1 Hypervisor | Xen | Open Source / Citrix |
| Typ-2 Hypervisor | Oracle VirtualBox | Oracle |
| Typ-2 Hypervisor | VMware Workstation | Broadcom |
| Paravirt. Treiber | VirtIO | Open Source (OASIS) |
| Performance-Monitoring | vSphere Performance Charts | Broadcom |
| Performance-Monitoring | Prometheus + Grafana | Open Source |
| Benchmarking | SPECvirt, Phoronix Test Suite | SPEC, Open Source |

## Reale Anwendungsbeispiele

- **AWS EC2:** Nutzt KVM-basierte Hypervisoren (seit Nitro System) mit Hardware-Offloading auf dedizierte Chips — Overhead nahezu eliminiert
- **Gaming-VMs:** Bei GPU-Passthrough (VFIO unter Linux/KVM) kann eine VM nahezu native Grafik-Performance erreichen
- **Datenbanken auf VMs:** Latenz-sensitiv — deshalb setzen Unternehmen auf Paravirtualisierung + dedizierte Ressourcen statt Overcommitting

## Quellen

- Intel. (2023). *Intel Virtualization Technology (VT-x) Overview*. https://www.intel.com/content/www/us/en/virtualization/virtualization-technology/intel-virtualization-technology.html
- Popek, G. J., & Goldberg, R. P. (1974). *Formal Requirements for Virtualizable Third Generation Architectures*. Communications of the ACM, 17(7), 412–421.
- Red Hat. (2024). *Understanding KVM and QEMU*. https://www.redhat.com/en/topics/virtualization/what-is-KVM
- VMware. (2023). *vSphere Resource Management Guide*. https://docs.vmware.com/en/VMware-vSphere/
- Amazon Web Services. (2023). *AWS Nitro System*. https://aws.amazon.com/ec2/nitro/
