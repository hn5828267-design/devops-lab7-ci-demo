# Tự động kích hoạt Jenkins khi push GitHub

## 1. Điều kiện

- Job dùng Pipeline script from SCM, repo và branch đúng.
- Đã Build Now ít nhất một lần để job lưu trigger từ `triggers { githubPush() }`.
- Trong Configure → Build Triggers, kiểm tra GitHub hook trigger for GITScm polling đã bật.
- Jenkins đang chạy, có ít nhất một executor cho bài lab; GitHub có thể gọi được endpoint webhook.

## 2. Localhost không phải URL webhook công khai

GitHub gửi HTTP từ server GitHub, nên `http://localhost:8090/github-webhook/` không trỏ đến máy bạn. Để demo có thể dùng ngrok đã cài và đã xác thực bằng tài khoản của bạn:

```powershell
ngrok http 8090
```

Nếu bạn đổi cổng Jenkins trong .env thì đổi số cổng ở đây. Ngrok có thể yêu cầu đăng ký/authtoken; cấu hình theo hướng dẫn tài khoản ngrok, không ghi token vào repo. Giữ terminal này mở. Sao chép URL HTTPS mà ngrok cấp, không dùng URL ví dụ trong tài liệu làm URL thật.

Tunnel tạo đường truy cập Internet tới Jenkins trong lúc mở; giữ xác thực Jenkins bật và chỉ mở khi thực hành. Không public Nexus/SonarQube để phục vụ webhook này.

## 3. Tạo webhook GitHub

Repo → Settings → Webhooks → Add webhook:

- Payload URL: `https://DIA_CHI_NGROK_THAT/github-webhook/` (có dấu / cuối).
- Content type: application/json.
- Events: Just the push event.
- Active: bật.
- Nếu cấu hình shared secret: cấu hình cùng secret tại mục GitHub webhook secret tương ứng của Jenkins GitHub plugin, lưu bằng Secret text credential. Không chỉ đặt secret một phía rồi coi là đã xác minh.

Lưu. Trong Recent Deliveries, kiểm tra response 2xx. Sau đó sửa README, commit và push:

```powershell
git add README.md
git commit -m "Verify GitHub webhook trigger"
git push
```

README phải thực sự có thay đổi trước khi commit. Chờ build tự xuất hiện; Console Output/cause cần thể hiện sự kiện GitHub push. Chụp cả delivery và build cause. Chỉ có HTTP 2xx chưa chứng minh đúng job đã build.

Sau demo: Ctrl+C dừng tunnel; vô hiệu hóa/xóa webhook lab khi không dùng nữa. URL tunnel thay đổi thì cập nhật Payload URL.

## 4. Phương án Poll SCM

Nếu chưa có đường truy cập từ GitHub, có thể thay dòng trigger trong Jenkinsfile bằng:

```groovy
triggers { pollSCM('H/5 * * * *') }
```

Commit/push rồi chạy Build Now một lần để nạp cấu hình mới. Jenkins sẽ kiểm tra thay đổi theo lịch; chỉ build khi SCM có thay đổi. Đây là polling, không phải webhook, phải ghi đúng khi báo cáo. Không cần bật đồng thời cả hai cho bài demo.

Nguồn: https://plugins.jenkins.io/github/ và https://ngrok.com/docs/gateway/endpoints/http
