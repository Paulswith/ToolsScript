# -*- coding:utf-8 -*-


import os,zipfile


#settings
_will_replace_str =  ''
_replace_to_str = ''
gb_current_path = os.getcwd()
gb_current_file_list = os.listdir(os.getcwd())
component_path = lambda first,last:os.path.join(first,last)


def get_path_allfile(target_path):
    '''
    绝对路径, 返回相对路径的全部子目录
    例如传入/a/b/c
    返回 [c/XXX,c/dXX/xXX]
    :param target_path:<str>必须是绝对路径
    :return: <list> 携带所有相对路径的子路径
    '''
    save_path = []
    for parent_file, dire_list, all_file_list in os.walk(target_path):
        for file in all_file_list:
            abs_file_path = os.path.join(parent_file, file)
            save_path.append(abs_file_path.replace(str(gb_current_path), ''))   #把父目录去除,踩过的坑是必须包含当前路径名
    print '[{a}] have [{b}] items'.format(a=target_path,b=len(save_path))
    return save_path

def make_zip_write_file(zip_target_file, will_zip_file_list):
    '''
    生成zip文件,并将传入数组相对路径的全部,写入到zip
    :param zip_target_file: type<str> 目标.zip文件
    :param will_zip_file_list:<list> 相对路径下全部文件
    '''
    if not isinstance(will_zip_file_list,list):
        return
    if '.zip' not in str(zip_target_file):  #加下后缀
        zip_target_file = '{}.zip'.format(zip_target_file)
    zip_instance = zipfile.ZipFile(zip_target_file, 'w')
    for write_file in will_zip_file_list:
        file = write_file.strip(os.path.sep)
        print 'make zip [{itemFile}] -> [{targetZip}]'.format(itemFile=file,targetZip=zip_target_file)
        zip_instance.write(file)
    zip_instance.close()


if __name__ == '__main__':
    for each_dir in gb_current_file_list:
        if _will_replace_str in each_dir:
            new_dir_name = each_dir.replace(_will_replace_str,_replace_to_str)
            os.rename(each_dir,new_dir_name)
            #需设置的zip内容
            abs_path = component_path(gb_current_path,new_dir_name)
            need_zip_file_list = get_path_allfile(abs_path)
            make_zip_write_file(new_dir_name,need_zip_file_list)
