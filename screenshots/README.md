# Ảnh nộp bài — chụp từ môi trường thực tế

Không có ảnh Docker/Jenkins/Nexus/Sonar giả lập trong gói. Thư mục evidence chứa kết quả local thực tế, không thay thế ảnh Jenkins.

| Tên ảnh | Nội dung cần hiển thị | Cách lấy |
|---|---|---|
| 01-docker-ps.png | 3 container lab7-jenkins, lab7-nexus, lab7-sonarqube Up | Terminal: docker compose ps; kiểm tra thêm web sẵn sàng |
| 02-jenkins-dashboard.png | Jenkins và tên job Lab 7 | http://localhost:8090 |
| 03-pipeline-stage-view.png | Đủ 6 stage job đầy đủ xanh | Job → Stage View |
| 04-console-output.png | Maven BUILD SUCCESS và Jenkins Finished: SUCCESS | Build → Console Output |
| 05-test-results.png | 6 test, 0 fail | Build → Test Result |
| 06-artifacts.png | JAR xuất hiện trong Artifacts | Trang build đã hoàn tất |
| 07-nexus-artifact.png | maven-snapshots/com/devops/lab7/ci-demo/1.0.0-SNAPSHOT, JAR | http://localhost:8081 → Browse |
| 08-sonarqube-dashboard.png | devops-lab7, kết quả scan/Quality Gate | http://localhost:9000 |
| 09-webhook.png (bổ sung) | Delivery thành công và build cause từ GitHub push | GitHub Webhooks + Jenkins |
| 10-cleanup.png (bổ sung) | Không còn container lab7 sau down | docker ps -a --filter name=lab7- |

Windows: Win+Shift+S → chọn vùng có nội dung → Paint Ctrl+V → lưu PNG đúng tên vào thư mục này. Không chụp token, initial password hoặc credential đang hiển thị.
