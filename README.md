# eco-server-energy-estimation
A collection of scripts to estimate the energy consumption of your server. This consists out of two projects.

## XGB
This is a service that uses the the Green Codings [Spec Power Model](https://github.com/green-coding-solutions/spec-power-model) to estimate the power usage of a computer via the cpu utilization. While being an estimate if you set the parameters correctly it is quite [accurate](https://www.green-coding.io/projects/cloud-energy/).

You can set the configuration in the xgb.conf file. For a detailed description of the values please refer to https://github.com/green-coding-solutions/spec-power-model

To install the XGB service please use the `sudo install.sh` in the `xgb` folder. This will install the tool and the service into the `/usr/local/bin/xgb` folder.

The xgb script outputs the values to std out for systemd to save them. You can view them with the `journalctl` command. This is done on purpose so you don't have files that overflow as everything will be handled through systemd.

If you want to only use the xgb service you can use the `get_values.py` script to output all the values to stdout.

You can use the auto flag in the config for the xgb model to try and find out all the values by itself. Please note that it is always better to specify the values explicitly as the energy value will be more accurate.

## CarbonDB uploader

To get the most out of this tool it makes sense to upload the energy values to some sort of backend. Of course you can use your system already in place but the Green Metrics Tool offers the CarbonDB backend which will give you a lot more information like:

- The amount of CO2 that was created by running your machine dependent on the location
- Grouping by company, project and tags
- Detailed analytics
- Exports for your carbon reporting
- No user accounts required

To use the carbonDB uploader you can call the `sudo install.sh` script in the carbondb_upload folder which will install everything to `usr/local/bin/carbondb_upload`

The config file is under `/etc/carbondb_uploader.conf`. Following key, value pairs are interpreted:

- `company_id`: A UUID that identifies your company. Like this you can search for all projects and machines in your company. You can set this id on all machines that belong to your company.
- `machine_id`: A UUID that identifies your machine. This will be set while install.
- `project_id`: A UUID that identifies the project the machine belongs to. Like this you can get statistics of a project.
- `tags`: A list in the form of `a,b,c` of tags you want to give the machine. This makes it easier to categorize machines when in the company/ project view. You might have `n` databases instances in one project. So you can assign the tag `db` to make filtering easier.
- `endpoint`: The endpoint where the data should be uploaded to. Will default to `https://metrics.green-coding.io/v1/carbondb/add`
- `db_file`: The file in which the script saves the last uploaded record. Will default to `/tmp/gmt_uploader_db`

## Script to install everything

Here is a copy paste ready script that you can copy into your shell to install everything:

```bash
cd /tmp
git clone https://github.com/green-coding-solutions/eco-server-energy-estimation.git
cd eco-server-energy-estimation
cd xgb
sudo ./install.sh
cd ..
cd carbondb_upload
sudo ./install.sh
cd ..
rm -rf eco-server-energy-estimation
```
