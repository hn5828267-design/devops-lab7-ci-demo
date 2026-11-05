# Xử lý lỗi Lab 7

| Biểu hiện | Kiểm tra / cách xử lý |
|---|---|
| docker compose không nhận diện | Kiểm tra Docker Desktop và `docker compose version`, dùng Compose V2 |
| Docker daemon không kết nối | Mở Docker Desktop, đợi Engine, kiểm tra `docker version` có Server |
| Port already allocated | Đổi host port trong .env; Lab 7 mặc định Jenkins 8090 để tránh Lab 8 8080 |
| Container name already in use | Kiểm tra container cùng tên bằng docker ps -a; không xóa container đang cần dùng trước khi xác định nó thuộc bài nào |
| Image pull: lookup registry-1.docker.io no such host | Lỗi DNS/mạng giống lỗi đã gặp ở Lab 8; kiểm tra nslookup, Internet/proxy, thử lại sau khi Docker Desktop có mạng |
| Failed to download plugin/dependency | Kiểm tra Maven Central/Jenkins update center, DNS/proxy; không sửa code Calculator để xử lý lỗi tải dependency |
| Nexus chưa có admin.password | Chờ startup, xem docker logs lab7-nexus; file có thể đã bị xóa sau lần đổi mật khẩu đầu, dùng mật khẩu đã đặt |
| Maven M3 / JDK21 not found | Tạo đúng tên trong Manage Jenkins → Tools, trỏ /opt/maven và /opt/java/openjdk, bỏ auto install |
| mvnw.cmd không chạy | Mở PowerShell tại sample-java-app, dùng .\mvnw.cmd; cần JDK17+ và JAVA_HOME đúng |
| Java release version 17 not supported | JDK local quá cũ; dùng JDK17+ hoặc script test-in-docker.ps1 |
| Script Path không tìm thấy | Dùng Jenkinsfile ở gốc repo, không dùng sample-java-app/Jenkinsfile |
| withSonarQubeEnv không tồn tại | Thiếu plugin SonarQube Scanner for Jenkins (id sonar) |
| No SonarQube installation named SonarQube | Manage Jenkins → System → SonarQube servers, đặt đúng Name SonarQube |
| Sonar connection refused | Kiểm tra Sonar UP; dùng http://sonarqube:9000 từ Jenkins, không dùng localhost |
| Sonar unauthorized | Token hết hạn/sai project/thiếu Execute Analysis; cập nhật Secret text sonarqube-token |
| Quality Gate failed | Mở Sonar project xem điều kiện không đạt; sửa nguyên nhân và chạy lại, không đổi thành skip rồi báo pass |
| Quality Gate timeout | Kiểm tra Background Tasks và tài nguyên Sonar; mặc định chờ 300 giây |
| Coverage trống | Test phải chạy trước scan; kiểm tra target/site/jacoco/jacoco.xml tồn tại |
| Nexus 401 | Sai nexus-credentials; Managed File phải đọc NEXUS_USERNAME/NEXUS_PASSWORD |
| Nexus 403 | Tài khoản chưa có quyền add/edit/read/browse trên repo đích |
| Nexus 400 version policy | Version SNAPSHOT phải vào maven-snapshots, không vào maven-releases |
| Cannot redeploy | Kiểm tra policy repo snapshot; dùng snapshot mới hoặc cho phép redeploy trong lab |
| Managed file not found | Tạo đúng ID maven-settings-nexus, sao chép settings XML trong gói |
| Pipeline queue mãi | Kiểm tra executor/node online; built-in node có >=1 executor cho lab local |
| Webhook có delivery nhưng không build | Repo/branch phải khớp job, đã chạy lần đầu, trigger bật, commit thực sự thay đổi |
| java -jar báo no main manifest | JAR Calculator là library theo đề, kiểm thử bằng Maven/JUnit, không phải ứng dụng web/chạy main |

## SonarQube / RAM / Elasticsearch

Stack ba service dùng tài nguyên đáng kể. Nếu container restart liên tục, xem logs để phân biệt thiếu RAM, cấu hình kernel và lỗi volume. Đừng dùng down -v như cách sửa lỗi đầu tiên vì sẽ mất dữ liệu.

```powershell
docker stats --no-stream
docker compose logs --tail 100 sonarqube nexus
```

Nếu log cụ thể yêu cầu vm.max_map_count >= 524288, trên WSL2 có distro docker-desktop bạn có thể kiểm tra/đặt:

```powershell
wsl -d docker-desktop -u root sysctl vm.max_map_count
wsl -d docker-desktop -u root sysctl -w vm.max_map_count=524288
docker compose restart sonarqube
```

Lệnh thay đổi tham số kernel của VM Docker, có thể cần đặt lại sau restart; nếu distro docker-desktop không tồn tại hoặc backend khác, dùng cấu hình phù hợp backend, không tạo distro giả. Linux host dùng `sudo sysctl -w vm.max_map_count=524288` khi log yêu cầu.

Nguồn: https://hub.docker.com/_/sonarqube/ và https://docs.sonarsource.com/sonarqube-community-build/server-installation/from-docker-image/set-up-and-start-container
