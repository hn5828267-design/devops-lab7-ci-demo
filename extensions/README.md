# Bài mở rộng — hướng dẫn tùy chọn, không tính là đã chạy

## 1. Postman/Newman

Calculator là thư viện, không có API. Bộ collection đi kèm kiểm tra `/health` của ứng dụng Lab 8 đang chạy qua Nginx cổng 8088 (theo cấu hình đã hướng dẫn), không giả định Calculator có endpoint.

Tại thư mục gốc Lab 7, PowerShell:

```powershell
$collectionPath = (Resolve-Path '.\extensions\postman').Path
docker run --rm --mount "type=bind,source=$collectionPath,target=/etc/newman" postman/newman:alpine run collection.json --reporters cli,junit --reporter-junit-export /etc/newman/results.xml
```

Nếu Lab8 dùng cổng khác, thêm `--env-var "baseUrl=http://host.docker.internal:CONG_THAT"`. Cần Lab8 đang chạy; kết quả XML ghi tại extensions/postman/results.xml. Để chạy trong Jenkins, cần agent có Node/Newman và kết nối endpoint; dùng `newman run ... --reporter-junit-export newman/results.xml`, rồi `junit 'newman/*.xml'` trong post always. Image Jenkins hiện tại không cài Node/Newman vì đây là phần mở rộng.

## 2. Parallel Stages

Không chạy `mvn test` và Sonar cùng ghi target trên một workspace. Nếu thực hành song song, cho hai nhánh checkout vào hai thư mục riêng (vd dir('unit-work') và dir('scan-work')). Nhánh unit chạy clean test và xuất JUnit; nhánh scan chạy clean verify sonar:sonar để có bytecode/coverage của riêng nó. Cách này có chi phí build/test lặp lại nhưng tránh race. Không chạy clean của nhánh này xóa target của nhánh kia.

## 3. Multibranch Pipeline

Cài GitHub Branch Source plugin, tạo Multibranch Pipeline → Branch Sources → GitHub repo → Script Path Jenkinsfile. Quét branch có Jenkinsfile. SonarQube Community có giới hạn khả năng phân tích branch tùy phiên bản; không mặc nhiên dùng một projectKey cho mọi branch.

Để demo nhiều branch mà chưa cấu hình Sonar branch support, dùng Script Path Jenkinsfile.basic. Nếu mở rộng full publish, đặt version/repository/projectKey riêng theo branch phù hợp và không cấp secret publish cho PR không tin cậy.

## 4. Email failure

Cài Email Extension plugin; cấu hình SMTP trong Manage Jenkins → System và credential SMTP. Chỉ sau khi đã chọn người nhận, thêm vào post failure:

```groovy
emailext(
    to: 'DIA_CHI_NHAN_THAT',
    subject: "Lab7 FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
    body: "Xem build: ${env.BUILD_URL}"
)
```

Đây chỉ là mẫu, chưa cấu hình SMTP và chưa gửi email nào.

## 5. Docker Build & Push và nối Lab 8

Lab7 tạo JAR Calculator dạng thư viện, Lab8 tạo image cho Node.js app. Không đổi Dockerfile Node.js của Lab8 sang copy JAR rồi kỳ vọng chạy được.

- Nếu giữ Lab7 Calculator: cần thêm main/service thực tế và tests trước khi đóng gói executable image.
- Nếu dùng sample Node.js thống nhất: Jenkinsfile.cicd của Lab8 đã chạy CI Node rồi Docker build/push/deploy.
- Nếu dùng Java thống nhất: bổ sung ứng dụng Java chạy được, image JRE, agent có Docker CLI/daemon access và credential registry. Jenkins Lab7 hiện tại không mount Docker socket.

Phần này là phương án mở rộng, chưa cung cấp hoặc tuyên bố đã triển khai một dịch vụ Java ngoài phạm vi đề.
