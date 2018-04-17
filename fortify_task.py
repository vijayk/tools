import os
import fnmatch
import argparse
import textwrap
from shutil import copy
import relib.hwx.util as util
import logging.handlers
from fortifyapi import fortify
from relib.hwx import extract_tokens
def copy_jarfiles(dest, build_tool, comp_source_root):
    cache = ".ivy2/cache"
    lib_dir = os.path.join(comp_source_root, "build")
    cache_path = os.path.join(os.environ['HOME'], cache)
    paths = list()
    paths.append(lib_dir)
    paths.append(cache_path)
    for path in paths:
        if os.path.exists(path):
            for root, dirname, filelist in os.walk(path):
                for fname in filelist:
                    fpath = os.path.join(root, fname)
                    if fpath.endswith(".jar"):
                        copy(fpath, dest)
def run_fortify(comp_obj, base_dir, comp_source_root, conf_file,
                fortify_cmd, dry_run):
    build_dir = comp_source_root
    if comp_obj['build_tool'] == "ant":
        cp_jars_dir = os.path.join(base_dir, "jars")
        if os.path.exists(cp_jars_dir):
            util.clean_dir(cp_jars_dir)
        os.makedirs(cp_jars_dir)
        copy_jarfiles(dest=cp_jars_dir, build_tool=comp_obj['build_tool'],
                      comp_source_root=comp_obj['comp_source_root'])
    for f in fortify_cmd:
        if isinstance(fortify_cmd[f], str):
            fcmd = fortify_cmd[f]
            build_dir = comp_source_root
        if isinstance(fortify_cmd[f], list):
            fcmd, d = fortify_cmd[f]
            build_dir = os.path.join(comp_source_root, d)
        logging.info("Running command: %s" % fcmd)
        util.run_cmd(cmd=fcmd, dry_run=dry_run, cwd=build_dir)
    fpr_file_path = get_fpr_file_path(comp_source_root)
    e = extract_tokens.SecretsConf(config_file=conf_file)
    ssc_host = e.get_config_value("fortify", "HOST")
    ssc_username = e.get_config_value("fortify", "USERNAME")
    ssc_password = e.get_config_value("fortify", "PASSWORD")
    ssc_version = e.get_config_value("fortify", "CLIENT_VERSION")
    if not dry_run:
        upload_fpr(host=ssc_host, username=ssc_username, password=ssc_password,
                   verify_ssl=False, client_version=ssc_version,
                   pname=comp_obj['name'], ptemplate="HortonWorks - test3",
                   pversion=comp_obj['stack_version'], pdesc="%s component" % comp_obj['name'],
                   fprfilepath=fpr_file_path)
def get_fpr_file_path(comp_source_root):
    for root, dirname, filelist in os.walk(comp_source_root):
        for fname in filelist:
            if fnmatch.fnmatch(fname, "*.fpr"):
                fpath = os.path.join(root, fname)
                if os.path.exists(fpath):
                    return fpath
def extract_project_versions(data):
    proj_versions = dict()
    for d in data.data["data"]:
        proj_name = d["project"]["name"]
        proj_id = d["project"]["id"]
        proj_ver = d["name"]
        proj_ver_id = d["id"]
        if proj_name not in proj_versions:
            proj_versions[proj_name] = dict()
        proj_versions[proj_name][proj_ver] = proj_ver_id
        proj_versions[proj_name]["id"] = proj_id
    return proj_versions
def upload_fpr(host, username, password, verify_ssl, client_version,
               pname, ptemplate, pversion, pdesc, fprfilepath):
    fortify_obj = fortify.FortifyApi(host=host, username=username,
                                     password=password, verify_ssl=verify_ssl,
                                     client_version=client_version)
    proj_versions = {}
    p = fortify_obj.get_all_project_versions()
    if p.response_code == -1:
        logging.error("%s" % p.message)
        return
    if p.response_code == 200:
        proj_versions = extract_project_versions(data=p)
    r = "null"
    project_version_id = None
    if pname in proj_versions and pversion in proj_versions[pname]:
        project_version_id = proj_versions[pname][pversion]
    if not project_version_id:
        if pname not in proj_versions:
            app_id = "null"
        elif pversion not in proj_versions[pname]:
            app_id = proj_versions[pname]["id"]
        logging.info("Creating new project %s and version %s" % (pname,
                                                                 pversion))
        r = fortify_obj.create_application_version(
            application_name=pname, application_id=app_id,
            application_template=ptemplate, version_name=pversion,
            description=pdesc
        )
        if (r != "null") and (r.response_code in range(200, 299)):
            project_version_id = r.data["data"]["id"]
            response = fortify_obj.bulk_create_new_application_version_request(
                version_id=project_version_id, development_phase="Active",
                development_strategy="Internal", accessibility="internalnetwork",
                business_risk_ranking="High")
            if response.response_code not in range(200, 299):
                logging.error("%s" % response.message)
                return
    # logging.info("Uploading FPR file from %s" % fprfilepath)
    # if fprfilepath is not None and os.path.exists(fprfilepath):
    #     response = fortify_obj.upload_artifact_scan(
    #         file_path=fprfilepath, project_version_id=project_version_id)
    #     if response.response_code == 200:
    #         logging.info("Upload response code %s" % response.response_code)

def parse_options():
    p = argparse.ArgumentParser(
            epilog=textwrap.dedent(''' '''),
            description='This script uploads fortify scan results to SSC',
            formatter_class=argparse.RawDescriptionHelpFormatter,
            argument_default=argparse.SUPPRESS)
    p.add_argument('--dry-run', dest='dry_run', action='store_true',
                   default=False, help='Just print what will be uploaded.')
    p.add_argument('-c', '--config-file', dest="conf_file", required=False,
                   default="/Users/skrishnamoorthy/.ssh/hwx_secrets.conf",
                   help="Config file location ")
    p.add_argument('-f', '--fpr-file-path', dest="fpr_path", required=False,
                   default="",
                   help="FPR file location ")
    p.add_argument('--force', dest="force", help="force trigger the build",
                   action='store_true', default=False)
    return p.parse_args()

def main():
    # args = parse_options()
    util.setup_logging()
    # e = extract_tokens.SecretsConf(config_file=args.conf_file)
    ssc_host = ""
    ssc_username = ""
    ssc_password = ""
    ssc_version = ""
    # fortify_obj = fortify.FortifyApi(host=ssc_host, username=ssc_username,
    #                                  password=ssc_password, verify_ssl=False,
    #                                  client_version=ssc_version)
    # print(fortify_obj.get_all_project_versions())
    components = ['accumulo', 'atlas', 'avatica', 'bigtop-jsvc', 'bigtop-tomcat', 'calcite', 'calcite_hive2','cascading', 'datafu', 'druid', 'falcon', 'flume',
                  'hadoop', 'hadooplzo', 'hbase', 'hive', 'hive2', 'hue', 'kafka', 'knox', 'livy', 'mahout', 'oozie', 'microsoft-sqoop-connector', 'orc',
                  'phoenix', 'pig', 'qe-examples', 'ranger', 'shc', 'slider', 'snappy-dll', 'spark', 'spark2', 'spark_hive', 'spark_hive2', 'spark_llap', 'sqoop',
                  'storm', 'superset', 'teradata_connector', 'tez', 'tez_hive2', 'zeppelin', 'zookeeper']
    for component in components:
        upload_fpr(ssc_host,ssc_username,ssc_password, verify_ssl=False, client_version=ssc_version,
                   pname=component, ptemplate="HortonWorks - test3",
                   pversion="2.6.5.0-245", pdesc="Fenton M30", fprfilepath='')
if __name__ == '__main__':
    main()
