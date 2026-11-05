# Báo cáo Lab 7 — Triển khai CI

## 1. Mục tiêu và thành phần

Tự động lấy mã Java từ GitHub, biên dịch, kiểm thử, phân tích chất lượng, đóng gói và lưu artifact. Jenkins điều phối pipeline; Maven build/test/package; JUnit 5 kiểm thử Calculator; JaCoCo tạo coverage; SonarQube phân tích tĩnh; Nexus lưu JAR/POM của phiên bản SNAPSHOT.

Calculator giữ đúng năm phép toán trong đề: add, subtract, multiply, divide và isPositive. Sáu test của tài liệu kiểm tra số dương/âm/0, kết quả phân số và ngoại lệ chia cho 0. Các phép toán int tuân theo ngữ nghĩa int của Java; bài không mở rộng xử lý tràn số.

## 2. Luồng pipeline

| Stage | Thực hiện | Đầu ra / điều kiện |
|---|---|---|
| Checkout | checkout scm | Source đúng repo/branch |
| Build | mvn clean compile | Bytecode Java release 17 |
| Test | mvn test | 6 tests, JUnit XML, JaCoCo XML/HTML |
| SonarQube Analysis | mvn sonar:sonar | Scan và Quality Gate; thất bại chặn phát hành |
| Package & Archive | mvn package -DskipTests, archiveArtifacts | JAR và báo cáo coverage lưu tại Jenkins |
| Publish to Nexus | mvn deploy:deploy-file + pomFile | JAR/POM SNAPSHOT vào maven-snapshots |

Test reports được thu ở post always của Test để vẫn xem được khi có test thất bại. Maven trả nonzero sẽ làm pipeline dừng; allowEmptyResults chỉ tránh lỗi phụ khi không kịp tạo XML, không biến lệnh Maven thất bại thành pass. Package bỏ chạy lại test vì Test đã là điều kiện bắt buộc trước đó.

GitHub webhook yêu cầu endpoint truy cập được từ GitHub. Poll SCM là phương án thay thế về cơ chế, không được báo cáo là webhook. JAR này là thư viện Calculator, chưa phải dịch vụ HTTP như Lab 8.

## 3. Bảo quản cấu hình và khả năng chạy lại

Token Sonar và mật khẩu Nexus nằm trong Jenkins Credentials. Managed settings XML chỉ đọc biến môi trường. Khóa/ID cấu hình được cố định trong bảng README. Script cleanup giữ volumes, tránh mất cấu hình sau mỗi lần thực hành.

Maven, JUnit và các Maven plugin được chỉ định phiên bản. Maven Wrapper tải Maven, không thay JDK. Image Jenkins LTS, Nexus latest, Sonar community và plugin Jenkins vẫn là các nhãn cập nhật; khi cần tái lập chính xác môi trường đã chạy, lưu `docker image inspect` (RepoDigests) và danh sách phiên bản plugin thực tế sau khi cài. Không tuyên bố đây là stack đã pin toàn bộ dependency.

## 4. Điều chỉnh những điểm không thống nhất trong đề

| Nội dung gốc | Cách thực hiện trong gói |
|---|---|
| Hướng dẫn tạo maven-releases nhưng pipeline dùng SNAPSHOT | Dùng thống nhất maven-snapshots |
| Ví dụ Nexus đường dẫn version 1.0.0 | Đúng version 1.0.0-SNAPSHOT, có thể có timestamp trong tên file |
| Copy Jenkinsfile vào sample-java-app ở đoạn sau | Một Jenkinsfile ở gốc; Script Path Jenkinsfile |
| Maven Wrapper được nhắc nhưng chưa có tệp | Bổ sung wrapper chính thức, vẫn yêu cầu JDK |
| Post success mới thu JUnit | Thu ở always, kể cả test thất bại |
| Coverage chưa có cấu hình | Bổ sung JaCoCo trước Sonar scan |
| localhost cho webhook GitHub | Dùng URL tunnel/public thật hoặc giải thích polling |
| Poll SCM mỗi 5 phút được mô tả như build định kỳ | Chỉ kiểm tra thay đổi; build khi phát hiện thay đổi |
| Mount Docker socket dù CI chỉ chạy Maven | Không mount socket; Jenkins có Maven sẵn |
| Jenkins cổng 8080 có thể trùng Lab 8 | Lab 7 mặc định 8090; nội bộ vẫn 8080 |

## 5. Đối chiếu rubric

| Tiêu chí | Điểm | Tệp / minh chứng cần có |
|---|---:|---|
| Docker Stack | 15% | docker-compose.yml, ảnh 01 |
| Java/Maven + 6 tests | 10% | pom.xml, Calculator/CalculatorTest, evidence |
| Jenkinsfile >=4 stages | 20% | Jenkinsfile đầy đủ 6 stages |
| Job + GitHub | 15% | Cấu hình job và ảnh checkout thành công |
| Build + Test | 15% | Console Output, JUnit 6/6 |
| Package + Archive | 10% | JAR trong Jenkins Artifacts |
| Publish Nexus | 10% | JAR/POM trong maven-snapshots |
| Dọn dẹp | 5% | down và kiểm tra container |

Mã nguồn/cấu hình đã chuẩn bị không đồng nghĩa toàn bộ rubric đã đạt. Trạng thái kiểm chứng nằm ở evidence/VERIFICATION.md; phần Docker/Jenkins/Nexus/Sonar/Webhook cần chạy trên máy sinh viên và chụp ảnh thật.

## 6. Nguồn đối chiếu

- Lab7_HuongDan.md do người dùng cung cấp, sao chép vào docs/Lab7_HuongDan_Goc.md. Ảnh ci_3.png/ci_4.png không được đính kèm trong đầu vào.
- https://maven.apache.org/tools/wrapper/
- https://maven.apache.org/plugins/maven-deploy-plugin/deploy-file-mojo.html
- https://help.sonatype.com/en/maven-repositories.html
- https://docs.sonarsource.com/sonarqube-community-build/analyzing-source-code/ci-integration/overview
- https://docs.sonarsource.com/sonarqube-community-build/analyzing-source-code/scanners/sonarscanner-for-maven
- https://www.jenkins.io/doc/pipeline/steps/sonar/
- https://plugins.jenkins.io/github/
