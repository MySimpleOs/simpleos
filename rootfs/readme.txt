SimpleOS initrd — the tiny filesystem loaded into memory at boot.

Everything in here is packed into build/initrd.tar at build time and
handed to the kernel as a Limine module. The kernel parses the TAR and
exposes each entry through the VFS.

Try:
  cat /etc/greeting.txt
  cat /etc/version
