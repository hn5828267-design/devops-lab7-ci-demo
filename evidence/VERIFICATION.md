# Trạng thái kiểm chứng — 05/11/2026

Môi trường thực thi: Linux, OpenJDK 17.0.20, Apache Maven 3.9.9. Maven dùng cấu hình mạng riêng của môi trường kiểm thử; cấu hình đó không nằm trong gói giao cho người dùng.

| Kiểm tra | Kết quả thực tế | Minh chứng |
|---|---|---|
| Maven clean verify | BUILD SUCCESS | maven-verify.log |
| Unit tests đúng mẫu đề | 6 tests; 0 failures; 0 errors; 0 skipped | surefire-reports/ |
| JaCoCo coverage Calculator | 8/8 lines; 4/4 branches; 34/34 instructions | coverage/index.html, coverage-summary.json |
| Đóng gói JAR | Đạt; có Calculator.class, không chứa CalculatorTest.class | ../artifacts/ci-demo-1.0.0-SNAPSHOT.jar |
| Tạo Maven Wrapper chính thức | Đạt, wrapper 3.3.2 cho Maven 3.9.9 | wrapper-generation.txt |
| Chạy Maven Wrapper trên Linux | Đạt, --version trả Maven 3.9.9 | wrapper-version.txt |
| Parse YAML/XML/JSON và sh -n | Đạt | static-checks.txt |
| Docker Compose stack | Chưa chạy: môi trường không có Docker CLI/daemon | Cần thực hiện trên máy người dùng |
| Jenkinsfile trên Jenkins | Chưa thực thi hoặc validate bằng Jenkins thật | Cần cấu hình tool/credential/job rồi Build Now |
| SonarQube scan / Quality Gate | Chưa chạy server thực tế | Không đồng nhất JaCoCo local với Sonar dashboard |
| Nexus publish | Chưa chạy: chưa có Nexus và credential | Cần ảnh artifact trên Nexus |
| GitHub checkout / webhook | Chưa chạy: chưa kết nối repo/tunnel của người dùng | Cần delivery và build cause thật |
| Script PowerShell / mvnw.cmd | Chưa thực thi: môi trường không có PowerShell | Cần xác nhận trên Windows |
| Các bài mở rộng | Collection/hướng dẫn tham khảo, chưa chạy | extensions/README.md |

Coverage 100% chỉ nói về các dòng/nhánh của Calculator trong mẫu nhỏ này, không chứng minh đầy đủ mọi giá trị đầu vào hoặc tính đúng của toàn bộ hệ thống CI.

Parse YAML/XML không thay thế validate Compose/Jenkins/Nexus. Không có screenshot chứng minh các dịch vụ chưa được chạy. Chưa thể tự chấm 100% rubric.
