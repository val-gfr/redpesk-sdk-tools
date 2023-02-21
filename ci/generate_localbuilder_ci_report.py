#!/usr/bin/python3
###########################################################################
# Copyright (C) 2021 IoT.bzh
#
# Authors:   Ronan Le Martret <ronan.lemartret@iot.bzh>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###########################################################################

import os
import argparse
import re

class ci_report:
    def __init__(self,path, report_path=None, os_tag=None):
        self.__path=path
        self.__report_path=report_path
        self.__os_tag=os_tag
        self.__list_test_case=[]

    def generate(self):
        self.__check_log()
        self.__generate_log()

    def set_report_path(self, report_path):
        self.__report_path=report_path

    def set_os_tag(self, os_tag):
        self.__os_tag=os_tag

    def __filter_string_4_xml(self, line):
        #line=line.replace('"','&quot;')
        #line=line.replace("'",'&apos;')
        line=line.replace('<','&lt;')
        line=line.replace('>','&gt;')
        #line=line.replace('&','&amp;')
        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
        return ansi_escape.sub('', line)

    def __find_install_error(self, path):
        result=False
        result_tag="error"
        install_error=""
        install_log=""
        with open(path)  as f:
            for line in f:
                install_log+=self.__filter_string_4_xml(line)
                #Not the best way to validate a log, it's a first draft, needs improvement.
                if "You can log in it with" in line:
                    result=True
                    result_tag="success"
                    break
        if not result:
            install_error="\n<error>%s</error>\n" % (install_log)
        
        test_case_install='''
    \n<testcase classname='%s' file='run_localbuilder_ci.sh' name='localbuilder_installation.%s'>%s</testcase>
''' % (self.__os_tag, self.__os_tag, install_error)

        self.__list_test_case.append(test_case_install)

    def __check_log(self):
        if os.path.exists(self.__path):
            self.__find_install_error(self.__path)
        else:
            install_error="\n<error>The log file %s has not been generated</error>\n" % self.__path
            result_tag="error"
            test_case_install='''
        \n<testcase classname='%s' file='run_localbuilder_ci.sh' name='localbuilder_installation.%s.%s'>%s</testcase>
    ''' % (self.__os_tag, self.__os_tag, result_tag, install_error)
            self.__list_test_case.append(test_case_install)

    def __generate_log(self):
        report_log='''<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
<testsuite>'''

        for test_case in self.__list_test_case:
            report_log+="%s\n" % (test_case)

        report_log+='''</testsuite>
</testsuites>'''

        if self.__report_path is not None:
            file = open(self.__report_path,"w+")
            file.write(report_log)

def main():
    parser = argparse.ArgumentParser(description='Process report(s).')
    parser.add_argument("-p", "--install-log-path"       , metavar='install_log_path'       , type=str, help='log path')
    parser.add_argument("-r", "--report-path", metavar='report_path', type=str, help="Generate report file")
    parser.add_argument("-t", "--os-tag"     , metavar='os_tag'     , type=str, help="OS tag")
    args = parser.parse_args()
    if args.install_log_path:
        report=ci_report(args.install_log_path)
        if args.report_path:
            report.set_report_path(args.report_path)
        if args.os_tag:
            report.set_os_tag(args.os_tag)
        report.generate()
    else:
        exit(1)

if __name__ == "__main__":
   main()