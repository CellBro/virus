code segment
               assume cs:code
    start:     
               mov    ax,cs
               mov    ds,ax

    watch_loop:
    a:         
               mov    bp,0h
               lea    dx,[bp+offset dta]         ;置dta
               mov    ah,1ah                     ;	设置磁盘缓冲区DTA，，DS:DX=磁盘缓冲区首址
               int    21h

               lea    dx,[bp+offset filename]    ;查找第一个文件
               mov    cx,0                       ;cx:属性
               mov    ah,4eh                     ;查找第一个匹配项
               int    21h
               jc     error                      ;无匹配项直接结束
    watch:     
               lea    dx,[bp+offset dta]         ;匹配结果再磁盘缓冲区中
               add    dx,1eh                     ;文件名地址
    
               mov    ax,3d00h                   ;3d打开文件,02方式：读
               int    21h

               mov    bx,ax                      ;文件号
    
               mov    ax,4200h                   ;到文件头
               xor    cx,cx
               xor    dx,dx
               int    21h
               mov    ah,3fh                     ;读文件头,内容存到head
               mov    cx,30h                     ;读取30字节
               lea    dx,[bp+offset head]
               mov    si,dx                      ;si=offset head
               int    21h
               cmp    word ptr [si],5a4dh        ;检查是否是exe
               jnz    nextfile

               mov    ah,3eh                     ;关闭文件
               int    21h
               cmp    word ptr [si+2ah],6666h    ;检查是否已被感染
               jne    watch
               lea    dx,warnning
               mov    ah,09h
               int    21h
               call   kill
               jmp    watch_loop
kill proc
               call   locate
    locate:    
               pop    bp                         ;bp=offset locate
               sub    bp,offset locate           ;bp=0

               lea    dx,[bp+offset dta]         ;置dta
               mov    ah,1ah                     ;	设置磁盘缓冲区DTA，，DS:DX=磁盘缓冲区首址
               int    21h

               lea    dx,[bp+offset filename]    ;查找第一个文件
               mov    cx,0                       ;cx:属性
               mov    ah,4eh                     ;查找第一个匹配项
               int    21h
               jc     error                      ;无匹配项直接结束

    modify:    
               lea    dx,[bp+offset dta]         ;匹配结果再磁盘缓冲区中
               add    dx,1eh                     ;文件名地址
    
               mov    ax,3d02h                   ;3d打开文件,02方式：读写
               int    21h

               mov    bx,ax                      ;文件号
    
               mov    ax,4200h                   ;到文件头
               xor    cx,cx
               xor    dx,dx
               int    21h

               mov    ah,3fh                     ;读文件头,内容存到head
               mov    cx,30h                     ;读取30字节
               lea    dx,[bp+offset head]
               mov    si,dx                      ;si=offset head
               int    21h

               cmp    word ptr [si],5a4dh        ;检查是否是exe
               jnz    nextfile

               cmp    word ptr [si+2ah],6666h    ;检查是否已被感染
               jne    nextfile
               mov    word ptr [si+2ah],0h

               mov    ax,word ptr [si+2ch]      ;保存原程序入口;;表示14-15H: b.exe 被载入后 IP 的初值是
               mov    word ptr [si+014h],ax      ;保存信息在head

               xor    cx,cx                      ;到文件尾，病毒代码插入到尾部
               xor    dx,dx
               mov    ax,4202h
               int    21h

               mov    ax,4202h                   ;计算新文件长度,修改头
               mov    cx,0160h
               xor    dx,dx
               int    21h
               mov    cx,200h
               div    cx
               inc    ax
               mov    word ptr [si+2],dx
               mov    word ptr [si+4],ax
    
               mov    ax,4200h                   ;到文件头并改写
               xor    cx,cx
               xor    dx,dx
               int    21h
               mov    ah,40h
               mov    dx,si
               mov    cx,30h
               int    21h

    nextfile:  
               mov    ah,3eh                     ;关闭文件
               int    21h

               mov    ah,4fh                     ;查找下一个文件
               int    21h
               jc     error
               jmp    modify

    error:     
               ret
kill endp

    filename   db     "*.exe",0
    dta        db     030h dup(0)
    string     db     "I'm a kill!",13,10,'$'
    head       db     30h dup(0)
    warnning   db     "virus is detected", 0dh,0ah,24h
    theend:    
code ends
end start
