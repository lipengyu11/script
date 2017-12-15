#!/usr/bin/env python

# -*- coding: utf-8 -*-


import os

def dispalyBackendMsg(filename):
    backendList = []
    with open(filename,'r') as f:
        for i in f:
            if i.startswith("backend"):
                backendList.append(i.split()[1])
        return backendList


        







if __name__=='__main__':
     print displayBackenMsg('haproxy')
    #print displayServerMsg('www.baidu.com','haproxy')
   # print backup('haproxy','ha1')





