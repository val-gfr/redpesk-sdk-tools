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

import argparse

class ci_report:
    def __init__(self,path):
        self.__path=path
        self.__dico_res={}
        self.__report_path=None
        self.__error=""

    def generate(self):
        self.__check_log()
        self.__generate_log()

    def set_report_path(self, report_path):
        self.__report_path=report_path

    def __find_error(self, path):
        result=False
        with open(path) as f:
            for line in f:
                #Not the best way to validate a log, it's a first draft, needs improvement.
                if "You can log in it with" in line:
                    result=True
                    break
        if not result:
            self.__error="<error></error>"

    def __check_log(self):
        is_ok=self.__find_error(self.__path)
        self.__dico_res[self.__path]=is_ok

    def __generate_log(self):
        report_log='''<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
<testsuite>
<testcase classname='%s' file='run_localbuilder_ci.sh' name='test_localbuilder.%s.error'>
%s
</testcase>
</testsuite>
</testsuites>''' % ("f37","f37", self.__error)

        if self.__report_path is not None:
            file = open(self.__report_path,"w+")
            file.write(report_log)

def main():
    parser = argparse.ArgumentParser(description='Process report(s).')
    parser.add_argument('path', metavar='path', type=str, help='log path')
    parser.add_argument("-r", "--report-path", metavar='report_path', type=str, help="Generate report file")
    args = parser.parse_args()
    if args.path:
        report=ci_report(args.path)
        if args.report_path:
            report.set_report_path(args.report_path)
        report.generate()
    else:
        exit(1)

if __name__ == "__main__":
   main()