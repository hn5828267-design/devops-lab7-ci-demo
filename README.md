# Lab 7 — CI Pipeline với Jenkins, Nexus & SonarQube

**Sinh viên:** Nguyễn Văn Hoàng — **MSSV/lớp: cần bổ sung**.

JAR đã build local được đặt ở `artifacts/`; kết quả JUnit và coverage ở `evidence/`.

Bộ bài gồm Calculator Java/Maven, 6 unit tests đúng đề, JaCoCo coverage, Jenkinsfile đầy đủ 6 stages, Jenkinsfile cơ bản 4 stages, stack Docker 3 service, Maven Wrapper, script PowerShell và hướng dẫn cấu hình từ đầu. Xem `evidence/VERIFICATION.md` để phân biệt phần đã kiểm chứng và phần còn phải chạy tại máy bạn.

**Lưu ý:** đây là Java library dùng cho CI, không phải website và không có phương thức main. File JAR không chạy bằng `java -jar`; kiểm tra chức năng bằng unit tests. JAR là artifact để lưu trong Jenkins và Nexus.

## 1. Chuẩn bị và tránh xung đột với Lab 8

Giải nén rồi mở PowerShell tại thư mục chứa README này. Kiểm tra:

```powershell
docker version
docker compose version
git --version
```

Docker Desktop phải chạy Linux containers và có kết nối Internet tới Docker Hub, Maven Central, Jenkins update center. Có thể không cần cài Java/Maven trên Windows nếu dùng script test bằng Docker và build trong Jenkins; Maven Wrapper vẫn cần **JDK 17+**, không tự cài JDK.

```powershell
Copy-Item .env.example .env
notepad .env
```

Cấu hình mặc định cố ý dùng Jenkins cổng **8090** để tránh Jenkins Lab 8 trên 8080:

| Dịch vụ | URL trên máy bạn | URL bên trong mạng Docker |
|---|---|---|
| Jenkins Lab 7 | http://localhost:8090 | http://jenkins:8080 |
| Nexus | http://localhost:8081 | http://nexus:8081 |
| SonarQube | http://localhost:9000 | http://sonarqube:9000 |

Bạn có thể đổi JENKINS_PORT/NEXUS_PORT/SONAR_PORT trong `.env`. Chỉ đổi cổng bên ngoài, không đổi URL nội bộ trong Jenkinsfile. Không ghi token/password vào `.env`.

Nên dành khoảng 6–8 GB RAM cho Docker khi chạy stack này; nếu máy 8 GB tổng RAM, hãy dừng các stack khác để tránh thiếu bộ nhớ. Với Docker Desktop dùng WSL 2, giới hạn RAM có thể được quản lý bằng `.wslconfig` thay vì thanh Memory trong Resources. Không có script tự sửa cấu hình máy hoặc xóa Lab 8.

## 2. Khởi động ba dịch vụ

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start.ps1
```

Hoặc chạy trực tiếp:

```powershell
docker compose config
docker compose up -d --build
docker compose ps
```

Lần đầu mất vài phút tải images/plugins. Trạng thái Up chưa chắc web đã sẵn sàng. Kiểm tra:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
```

Script kiểm tra HTTP và trạng thái UP của SonarQube. Nếu chưa sẵn sàng, xem log rồi chạy lại sau:

```powershell
docker compose logs --tail 100 jenkins nexus sonarqube
```

Image Jenkins đã có Maven 3.9.9, JDK 21 và plugins cần dùng. CI này không cần Docker socket; không cần chmod 666 hay chạy Jenkins bằng root.

SonarQube dùng DB nhúng và tắt Elasticsearch bootstrap checks theo hướng bài lab 3 container. Đây chỉ là môi trường thực hành, không dùng production. Nếu log vẫn yêu cầu `vm.max_map_count`, xem `docs/TROUBLESHOOTING.md`.

## 3. Thiết lập Jenkins

```powershell
docker exec lab7-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Mở http://localhost:8090, nhập mật khẩu, hoàn tất wizard và tạo tài khoản quản trị với mật khẩu riêng. Không dùng mật khẩu mẫu trong đề làm mật khẩu thực tế. Jenkins URL cho thực hành local: `http://localhost:8090/`.

Plugins đã cài khi build image: Pipeline, Stage View, Git, GitHub, Credentials Binding, Config File Provider, SonarQube Scanner, JUnit, Workspace Cleanup. Không cần Nexus Platform Plugin vì publish bằng Maven; Blue Ocean không bắt buộc.

Vào **Manage Jenkins → Tools**:

| Mục | Name (đúng chữ hoa/thường) | Cấu hình |
|---|---|---|
| JDK installations | JDK21 | Bỏ Install automatically; JAVA_HOME = /opt/java/openjdk |
| Maven installations | M3 | Bỏ Install automatically; MAVEN_HOME = /opt/maven |

Nhấn Save và kiểm tra:

```powershell
docker exec lab7-jenkins java -version
docker exec lab7-jenkins mvn -version
```

## 4. Thiết lập Nexus

```powershell
docker exec lab7-nexus cat /nexus-data/admin.password
```

Mở http://localhost:8081, đăng nhập admin bằng mật khẩu trên, hoàn tất wizard và đổi mật khẩu. Anonymous access không bắt buộc cho publish có credential; có thể bật read-only để tiện xem/tải artifact trong lab.

Vào Settings → Repositories, tìm **maven-snapshots**:

- Nếu đã có: dùng lại, không tạo trùng.
- Nếu chưa có: Create repository → `maven2 (hosted)`.
- Name: `maven-snapshots`.
- Version policy: `Snapshot`.
- Layout policy: `Strict`.
- Deployment policy: `Allow redeploy` cho bài thực hành.
- Online: bật.

Dự án đang là `1.0.0-SNAPSHOT`, phải publish vào maven-snapshots. `maven-releases` chỉ dùng khi đổi sang version release, đồng thời đổi đường dẫn JAR và repository trong pipeline.

Tạo Jenkins credential: **Manage Jenkins → Credentials → System → Global → Add Credentials**:

| Trường | Giá trị |
|---|---|
| Kind | Username with password |
| Username | admin (lab local; hoặc tài khoản chỉ có quyền repo cần thiết) |
| Password | Mật khẩu Nexus vừa đặt |
| ID | nexus-credentials |

## 5. Tạo Maven Managed File

Jenkins → Manage Jenkins → Managed files → Add a new Config → **Maven settings.xml**.

- ID: **maven-settings-nexus**.
- Name: `Lab 7 Nexus settings`.
- Content: sao chép **toàn bộ nội dung** `jenkins/settings-nexus.xml`.
- Để trống phần Server Credentials mapping vì mẫu lấy username/password qua biến môi trường từ `withCredentials`.
- Save/Submit.

File mẫu chỉ có `${env.NEXUS_USERNAME}` và `${env.NEXUS_PASSWORD}`, không chứa mật khẩu thật. Server id `nexus` phải khớp `-DrepositoryId=nexus` trong Jenkinsfile.

## 6. Thiết lập SonarQube

Mở http://localhost:9000. Với volume mới, đăng nhập `admin` / `admin`, sau đó đổi mật khẩu ngay khi được yêu cầu.

1. Projects → Create project / Create locally (tên nút có thể khác theo phiên bản).
2. Project key: **devops-lab7**.
3. Display name: `DevOps Lab 7 CI Demo`.
4. Main branch: `main`; nếu được hỏi New Code, dùng lựa chọn phù hợp bài demo như Previous version.
5. My Account → Security → Generate Token. Tạo project analysis token cho devops-lab7 hoặc user token có quyền Execute Analysis trên project đó.
6. Lưu token vào Jenkins: Kind **Secret text**, ID **sonarqube-token**.

Jenkins → Manage Jenkins → System → SonarQube servers → Add:

| Trường | Giá trị |
|---|---|
| Name | SonarQube |
| Server URL | http://sonarqube:9000 |
| Server authentication token | sonarqube-token |

Tên `SonarQube` phải khớp `withSonarQubeEnv('SonarQube')`. Không dùng localhost:9000 ở đây vì localhost trong Jenkins là container Jenkins.

Jenkinsfile đầy đủ dùng `sonar.qualitygate.wait=true`: scanner chờ kết quả Quality Gate tối đa 300 giây. Quality Gate fail sẽ chặn Package/Publish. Cách này không cần webhook SonarQube → Jenkins. GitHub webhook ở mục 10 là cơ chế khác.

## 7. Kiểm thử Calculator trước

**Cách A — có JDK 17+ trên Windows, không cần cài Maven:**

```powershell
cd sample-java-app
java -version
.\mvnw.cmd -B clean verify
cd ..
```

Linux/macOS: `cd sample-java-app`, `sh ./mvnw -B clean verify`.

**Cách B — dùng Docker, không cần JDK/Maven trên Windows:**

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-in-docker.ps1
```

Kết quả mong đợi: 6 tests, failures 0, errors 0, BUILD SUCCESS.

- JAR: `sample-java-app/target/ci-demo-1.0.0-SNAPSHOT.jar`.
- JUnit XML: `sample-java-app/target/surefire-reports/`.
- Coverage HTML: `sample-java-app/target/site/jacoco/index.html`.
- Coverage XML cho SonarQube: `sample-java-app/target/site/jacoco/jacoco.xml`.

## 8. Push repository riêng lên GitHub

Tạo repo trống `devops-lab7-ci-demo`, không thêm README/gitignore từ GitHub. Tại thư mục chứa README này:

```powershell
git init
git add .
git commit -m "Complete Lab 7 CI with Jenkins Nexus and SonarQube"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/devops-lab7-ci-demo.git
git push -u origin main
```

Thay YOUR_GITHUB_USERNAME bằng tài khoản GitHub thật. Docker Hub username espresso01 của Lab 8 không được tự động coi là GitHub username. Đăng nhập GitHub bằng cơ chế Git Credential Manager hoặc GitHub PAT phù hợp nếu được hỏi.

Jenkinsfile nằm **ngay gốc repo**, cùng cấp `sample-java-app`. Không copy thêm Jenkinsfile vào sample-java-app. `.gitignore` loại target, .env, log và file settings local. Tuyệt đối không commit token.

## 9. Tạo Pipeline Job và xác minh

New Item → `DevOps-Lab7-CI-Pipeline` → Pipeline → OK.

| Trường | Giá trị |
|---|---|
| Definition | Pipeline script from SCM |
| SCM | Git |
| Repository URL | URL repo Lab 7 vừa tạo |
| Credentials | Trống nếu public; GitHub credential riêng nếu private |
| Branch Specifier | */main |
| Script Path | Jenkinsfile |

Save → Build Now. Lần chạy đầu cũng đăng ký trigger GitHub từ Jenkinsfile.

Sáu stage: **Checkout → Build → Test → SonarQube Analysis → Package & Archive → Publish to Nexus**.

Muốn kiểm tra Build/Test trước khi cấu hình Sonar/Nexus: tạo job riêng dùng Script Path **Jenkinsfile.basic** (4 stage). Job basic không thay thế bài nộp đầy đủ vì chưa scan/publish.

Sau SUCCESS:

- Jenkins build → Test Result: 6 tests pass.
- Jenkins build → Artifacts: tải JAR; báo cáo coverage cũng được archive.
- SonarQube → Projects → devops-lab7: xem kết quả phân tích và Quality Gate.
- Nexus → Browse → maven-snapshots → com → devops → lab7 → ci-demo → **1.0.0-SNAPSHOT**.

Nexus có thể hiển thị file snapshot dạng `ci-demo-1.0.0-YYYYMMDD.HHMMSS-N.jar`, kèm POM/checksum/metadata. Đây là snapshot có timestamp, không phải lỗi đổi tên. Không tìm đường dẫn release 1.0.0 như ví dụ không thống nhất trong đề.

Jenkinsfile dùng cleanWs sau build; báo cáo test/artifacts đã được Jenkins lưu trước đó. File ở workspace bị xóa không đồng nghĩa mất artifact của build.

## 10. GitHub Webhook và Poll SCM

Để hoàn thành mục tiêu auto-trigger, làm theo `docs/WEBHOOK.md` rồi push một commit mới. GitHub không thể gửi webhook đến localhost của máy bạn. Tài liệu hướng dẫn tunnel cho demo và phân biệt webhook với Poll SCM.

Nếu chưa cấu hình đường truy cập từ Internet, có thể dùng Poll SCM `H/5 * * * *` để thực hành tự động kiểm tra thay đổi. Poll SCM chỉ build khi có commit mới, không phải cứ 5 phút build một lần; đây chưa phải minh chứng GitHub webhook.

## 11. Chụp ảnh và dọn dẹp

Danh sách ảnh và vị trí chụp nằm trong `screenshots/README.md`. Chỉ chụp minh chứng từ máy đang chạy thật, không dùng log local thay ảnh Jenkins.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\cleanup.ps1
docker ps -a --filter "name=lab7-"
```

Script chỉ dừng/xóa container thuộc stack Lab 7, giữ dữ liệu volumes và không xóa Lab 8. Linux/macOS: `sh scripts/cleanup.sh`.

Nếu thực sự muốn xóa dữ liệu Jenkins/Nexus/Sonar của Lab 7:

```powershell
docker compose down -v
```

Lệnh trên xóa tài khoản, job, artifact trong Nexus và dữ liệu Sonar của stack; chỉ dùng sau khi lưu minh chứng. Cache của script test Docker nếu đã dùng có thể xóa riêng bằng `docker volume rm lab7-maven-cache` khi không còn container dùng nó. Không dùng `docker system prune` để dọn bài.

Điền họ tên/MSSV/lớp, bổ sung screenshots, nén thư mục thành `Lab7_NguyenVanHoang_MSSV_THAT.zip`. Có thể loại thư mục `sample-java-app/target` trước khi nén vì build sẽ sinh lại. Giữ wrapper `.mvn`, `mvnw`, `mvnw.cmd`.
