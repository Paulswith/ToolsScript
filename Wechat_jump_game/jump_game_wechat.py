# coding:utf-8
__author = 'dobby'

from PIL        import Image
import pylab    as pl
import time,math,os,wda


IMAGE_PLACE = '/tmp/screen.png'
each_pixel_d = 0.00190

c = wda.Client()
s = c.session('com.tencent.xin')
input("请自行切换到游戏里面的界面,回车即可开始")

def change_to_duration(position_list):
    """
    勾股定理 求d=C=开根号(A^2+B^2)
    """
    if not position_list:
        return
    x1,y1 = position_list[0]
    x2,y2 = position_list[1]
    the_d = math.sqrt(math.pow(y2 - y1, 2) + math.pow(x2 - x1, 2))
    return float('%.3f' % (the_d * each_pixel_d))

if __name__ == '__main__':
    while 1:
        x = c.screenshot(IMAGE_PLACE)
        if not os.path.exists(IMAGE_PLACE):
            continue
        # time.sleep(1)  #图片就算在了,渲染还没结束,这1秒阻塞就给了吧,或者不给,为渲染正常的以下方阴影为准
        pl.imshow(pl.array(Image.open(IMAGE_PLACE)))
        position_list = pl.ginput(2,timeout=2147483647)
        pl.ion()
        duration = change_to_duration(position_list)
        pl.ioff()
        if duration and os.path.exists(IMAGE_PLACE):
            s.tap_hold(200, 200, duration=duration)
            os.remove(IMAGE_PLACE)

