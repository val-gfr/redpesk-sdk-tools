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
    def __init__(self,path_list):
        self.__path_list=path_list
        self.__dico_res={}
        self.__report_path=None

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
        return result


    def __check_log(self):
        for path in self.__path_list:
            is_ok=self.__find_error(path)
            self.__dico_res[path]=is_ok

    def __generate_log(self):
        report_log=""
        global_result="PASSED"
        size_line=73
        sep_line="_"*size_line+"\n"
        report_log+=sep_line
        for path in self.__dico_res:
            is_ok=self.__dico_res[path]
            if not is_ok:
                global_result="FAILED"
            report="|\t%s\t|\t%s\t|" % (path, "PASSED" if is_ok else "FAILED")
            report_log+=report+"\n"
        report_log+=sep_line
        report="|\tGlobal result\t\t\t\t\t|\t%s\t|" % (global_result)
        report_log+=report+"\n"
        report_log+=sep_line
        if self.__report_path is not None:
            file = open(self.__report_path,"w+")
            file.write(report_log)

def main():
    parser = argparse.ArgumentParser(description='Process report(s).')
    parser.add_argument('path', metavar='path', type=str, nargs='+', help='log path')
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