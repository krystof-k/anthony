# Anthony

Anthony ~~is~~ will be a tool to manage your drives inventory.

Now, it is just a bunch of shell scripts to easily wipe, health check and performance test your drives.

## How to

### Install dependencies

You'll need [smartmontools](https://www.smartmontools.org) (v. 7+), [jq](https://stedolan.github.io/jq/) and [fio](https://fio.readthedocs.io/en/latest/fio_doc.html) (in case you want to test performance):

```console
sudo apt install smartmontools jq fio
```

### Download shell scripts

Set up Anthony shell scripts in `./anthony` folder:

```console
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/krystof-k/anthony/main/scripts/setup.sh)" \
  && cd anthony
```

### Run the scripts

Now you can run the shell scripts:

- ```console
  sudo /bin/bash wipe.sh /dev/sda /dev/sdb
  ```

  to wipe the drives with zeros

  _⚠️ You will lose your data!_

- ```console
  sudo /bin/bash smart.sh --test /dev/sda /dev/sdb
  ```

  to run long S.M.A.R.T test on the drives and save the results to a file

- ```console
  sudo /bin/bash smart.sh /dev/sda /dev/sdb
  ```

  or just save the current S.M.A.R.T. data

- ```console
  sudo /bin/bash performance.sh /dev/sda /dev/sdb
  ```

  to run a set of performance tests on the drives and save the results to a file

  _⚠️ You will lose your data!_

- ```console
  sudo /bin/bash all.sh /dev/sda /dev/sdb
  ```

  to run all of above at once

  _⚠️ You will lose your data!_

As the script can easily run for several hours, it is meaningful to run it within a `screen`.

Then you can upload the results for example via [transfer.sh](https://transfer.sh) and save them for later:

```console
tar -czf - ./data | curl --upload-file - https://transfer.sh/anthony.tar.gz
```
