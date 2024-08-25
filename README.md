# Create a windows image from an ISO on SmartOS/bhyve

Create an ISO from this repo, and upload to a node. Use your favourite ISO creation tool, If you're using genisoimage the command is. Lets assume you're uploading to /zones/stuff on the node
```
genisoimage -o ../windows-virtio.iso -J -R -m .git -m README.md .
```

Download an ISO from your Visual Studio subscription onto a node to /zones/stuff

Look here - https://my.visualstudio.com/Downloads

Run
```
export WINDOWS_INSTALL_CD=/zones/stuff/<windows-iso>
export WINDOWS_DRIVER_CD=/zones/stuff/windows-virtio.iso
```

Then create a zone to run the VM in
```
zfs create -V 80G zones/windows
```

Then create a VM
```
pfexec /usr/sbin/bhyve -c 2 -m 3G -H \
    -l com1,stdio \
    -l bootrom,/usr/share/bhyve/uefi-rom.bin \
    -s 2,ahci-cd,$WINDOWS_INSTALL_CD \
    -s 3,virtio-blk,/dev/zvol/rdsk/zones/windows \
    -s 4,ahci-cd,$WINDOWS_DRIVER_CD \
    -s 31,lpc \
    -s 28,fbuf,vga=off,tcp=0.0.0.0:5900,w=1024,h=768,wait \
    -s 29,xhci,tablet \
    windows
```

The instance will wait until VNC is connectes, ssh into the node with a tunnel, and then connect your VNC
```
ssh -L 5555:localhost:5900 <node>
```

NOTE: You need to be prepared to quickly press a key when prompted on VNC
once the instance starts in order for the Windows ISO to boot.

Now wait until bhyve terminates, which will take some time.

When bhyve terminates, run it again, but without the `WINDOWS_INSTALL_CD` line:

For Windows Server 2016 / 2019 and Windows 10:

```
pfexec /usr/sbin/bhyve -c 2 -m 3G -H \
    -l com1,stdio \
    -l bootrom,/usr/share/bhyve/uefi-rom.bin \
    -s 3,virtio-blk,/dev/zvol/rdsk/zones/windows \
    -s 4,ahci-cd,$WINDOWS_DRIVER_CD \
    -s 31,lpc \
    -s 28,fbuf,vga=off,tcp=0.0.0.0:5900,w=1024,h=768,wait \
    -s 29,xhci,tablet \
    windows
```

And wait for bhyve to terminate again. It will take a while, but not as long
as the first phase.

Now we create our image:

```
zfs send zones/windows | tee /zones/stuff/windows.zvol | digest -a sha1
zfs destroy zones/windows
/usr/sbin/bhyvectl --destroy --vm=windows
ls -l /zones/stuff/windows.zvol
```

Using the SHA1 hash and byte size from `ls -l`, create file called `windows.imgmanifest` and put the following in it

```
{
    "v": 2,
    "uuid": "738dccbc-b1b6-11e8-bd8a-ab7098639442",
    "name": "windows-installing",
    "version": "0.0.1",
    "type": "zvol",
    "os": "windows",
    "files": [ {
        "sha1": "<windows.zvol SHA1 hash>",
        "size": <file size in byves>,
        "compression": "none"
    } ]
}
```

Then:

`imgadm install -m /zones/stuff/windows.imgmanifest -f /zones/stuff/windows.zvol`

You can delete `windows.imgmanifest` and `windows.zvol` and the two ISO's.

You can now create in instance from the image.

## Update the virtio
- Download the latest stable release from https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
- mount it (lets say its on D:)
- copy the .cat, .inf and .sys files from D:\viostor\2k22\amd64 to drivers/disk/amd64
- copy the .cat, .inf and .sys files from D:\NetKVM\2k22\amd64 to drivers/network/amd64
Replace `2k22` with the version of windows you're using
