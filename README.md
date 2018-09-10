# yum repo local mirror

## 快速开始

```sh
# rpm data folder
data_path="${HOME}/data/yum-mirror"

# you server ip or domain
SERVER_NAME=http://yum-repo.example.com

docker run -v ${data_path}:/mirror --name yum-mirror -p 8080:8080 -d klzsysy/yum-mirror
# view repo index and client repo file
open ${SERVER_NAME}:8080
```

## 变更

在原基础上:
- 封装nginx作http服务，默认端口8080
- 更换国内源
- 添加定时运行
- 修改挂载路径
- 修改权限，以便在无root环境运行
- 兼容openshift无特权运行
- 生成客户端repo文件

快速一键部署本地yum mirror (*^▽^*)

## 新增变量

- `DAYS_SYNC_TIME` 每天同步的时间 `小时-分钟`， 默认  `01-10`
- `WEEK_SYNC_TIME` 每周同步的时间 1-7 1是周一， 例如 `1 2 3` 为周一到周三，默认每天`all`
- `HTTP_PORT` 默认8080
- `SERVER_NAME` 用于生成客户端repo文件的baseurl地址，是部署服务器IP或指向该服务器的域名

## 配置

- [config.yaml](config/yumfile.conf) ， 挂载路径 `/go/src/yum-mirror/config.yaml`
- data挂载点 `/data`