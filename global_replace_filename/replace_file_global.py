# -*- coding:utf-8 -*-
__author = 'dobby'

import os


wanna_replace_word = 'jpg'
replace_to_word = 'png'
original_file = os.path.join(os.getcwd())

walk_all = os.walk(original_file)
for abs_path_header,dir_name,file_name in walk_all:
    for sub_file_name in file_name:
        new_replace_name = sub_file_name.replace(wanna_replace_word, replace_to_word)
        wanna_replace_absPath = os.path.join(abs_path_header, sub_file_name)
        after_replace_absPath = os.path.join(abs_path_header, new_replace_name)
        print 'rename [{a}] =>> [{b}]'.format(a=wanna_replace_absPath,b=after_replace_absPath)
        os.rename(wanna_replace_absPath, after_replace_absPath)
