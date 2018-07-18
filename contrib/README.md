# hibenchmarks contrib

## Building .deb packages

The `contrib/debian/` directory contains basic rules to build a
Debian package.  It has been tested on Debian Jessie and Wheezy,
but should work, possibly with minor changes, if you have other
dpkg-based systems such as Ubuntu or Mint.

To build hibenchmarks for a Debian Jessie system, the debian directory
has to be available in the root of the hibenchmarks source. The easiest
way to do this is with a symlink:

    ~/hibenchmarks$ ln -s contrib/debian

Then build the debian package:

    ~/hibenchmarks$ dpkg-buildpackage -us -uc -rfakeroot

This should give a package that can be installed in the parent
directory, which you can install manually with dpkg.

    ~/hibenchmarks$ ls ../*.deb
    ../hibenchmarks_1.0.0_amd64.deb
    ~/hibenchmarks$ sudo dpkg -i ../hibenchmarks_1.0.0_amd64.deb


### Building for a Debian system without systemd

The included packaging is designed for modern Debian systems that
are based on systemd. To build non-systemd packages (for example,
for Debian wheezy), you will need to make a couple of minor
updates first.

* edit `contrib/debian/rules` and adjust the `dh` rule near the
  top to remove systemd (see comments in that file).

* rename `contrib/debian/control.wheezy` to `contrib/debian/control`.

* change `control.wheezy from contrib/Makefile* to control`.

* uncomment `EXTRA_OPTS="-P /var/run/hibenchmarks.pid"` in
 `contrib/debian/hibenchmarks.default`

* edit `contrib/debian/hibenchmarks.init` and change `PIDFILE` to
  `/var/run/hibenchmarks.pid`

* remove `dpkg-statoverride --update --add --force root hibenchmarks 0775 /var/lib/hibenchmarks/registry` from
  `contrib/debian/hibenchmarks.postinst.in`. If you are going to handle the unique id file differently.

Then proceed as the main instructions above.

### Reinstalling hibenchmarks

The recommended way to upgrade hibenchmarks packages built from this
source is to remove the current package from your system, then
install the new package. Upgrading on wheezy is known to not
work cleanly; Jessie may behave as expected.
