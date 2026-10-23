<div dir="rtl" align="right">

<h1 dir="rtl" align="right">ArvanCloud Let's Encrypt — صدور و تمدید گواهی SSL Wildcard</h1>

<div dir="ltr" align="center">
<p align="center">
  <a href="https://hits.sh/github.com/power0matin/arvancloud-letsencrypt/"><img src="https://hits.sh/github.com/power0matin/arvancloud-letsencrypt.svg?style=flat-square&amp;label=Views&amp;labelColor=18181B&amp;color=0EA5E9&amp;logo=github" alt="Repository views"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/stargazers"><img src="https://img.shields.io/github/stars/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Stars&amp;labelColor=18181B&amp;color=F59E0B&amp;logo=github&amp;logoColor=white" alt="GitHub stars"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/forks"><img src="https://img.shields.io/github/forks/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Forks&amp;labelColor=18181B&amp;color=6366F1&amp;logo=github&amp;logoColor=white" alt="GitHub forks"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/issues"><img src="https://img.shields.io/github/issues/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Issues&amp;labelColor=18181B&amp;color=22C55E&amp;logo=github&amp;logoColor=white" alt="GitHub issues"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/releases"><img src="https://img.shields.io/github/v/release/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Latest%20release&amp;labelColor=18181B&amp;color=0EA5E9" alt="Latest release"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt"><img src="https://img.shields.io/github/license/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=License&amp;labelColor=18181B&amp;color=EF4444&amp;logo=github&amp;logoColor=white" alt="GPL-3.0-or-later license"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/actions/workflows/lint.yml"><img src="https://github.com/power0matin/arvancloud-letsencrypt/actions/workflows/lint.yml/badge.svg?branch=main" alt="Shell checks"/></a>
</p>
</div>

<p dir="rtl" align="right">این پروژه ابزاری مبتنی بر <span dir="ltr">Bash</span> برای صدور و تمدید خودکار گواهی‌های <span dir="ltr">Let's Encrypt Wildcard SSL/TLS</span> با اعتبارسنجی <span dir="ltr">DNS-01</span> از طریق API آروان‌کلاد است. ابزار با <span dir="ltr">acme.sh</span> کار می‌کند و هم منوی تعاملی دارد و هم دستورهای خط فرمان.</p>
<p dir="rtl" align="center"><a href="./README.md">English documentation</a></p>

<h2 dir="rtl" align="right">امکانات</h2>
<ul dir="rtl" align="right">
  <li>صدور گواهی برای دامنه اصلی و تمام زیردامنه‌ها؛ مانند <code dir="ltr">example.com</code> و <code dir="ltr">*.example.com</code>.</li>
  <li>مدیریت رکورد موقت <code dir="ltr">TXT</code> با نام <code dir="ltr">_acme-challenge</code> از طریق API آروان‌کلاد.</li>
  <li>نصب گواهی در مسیر دلخواه و اجرای دستور reload پس از نصب موفق.</li>
  <li>پشتیبانی اختیاری از مسیرهای گواهی سازگار با <code dir="ltr">x-ui</code>.</li>
  <li>ثبت گواهی در <code dir="ltr">acme.sh</code> برای تمدید زمان‌بندی‌شده.</li>
  <li>منوی ترمینال برای فهرست گواهی‌ها، بررسی اعتبار، مشاهدهٔ لاگ‌ها و عیب‌یابی.</li>
  <li>ورود مخفی کلید API و اصلاح کلید/دسترسی DNS بدون ورود مجدد دامنه و گزینه‌ها.</li>
</ul>

<h2 dir="rtl" align="right">شروع سریع</h2>
<p dir="rtl" align="right">روی سرور Debian یا Ubuntu با دسترسی مدیر اجرا کنید. این دستور منوی تعاملی را باز می‌کند:</p>
<pre dir="ltr" align="left"><code>curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/latest/install.sh | sudo bash</code></pre>
<p dir="rtl" align="right">پیش از اجرای اسکریپت راه‌دور با دسترسی مدیر، محتوای آن را بررسی کنید:</p>
<pre dir="ltr" align="left"><code>curl -fsSLo install.sh https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/latest/install.sh
less install.sh
bash install.sh</code></pre>
<p dir="rtl" align="right">شاخهٔ <code dir="ltr">latest</code> کانال متحرک نصب است. برای نصب نسخهٔ ثابت، به‌جای آن از تگ انتشار استفاده کنید؛ مثلاً <code dir="ltr">v1.1.1</code>.</p>

<h2 dir="rtl" align="right">پیش‌نیازها</h2>
<ul dir="rtl" align="right">
  <li>سرور Debian یا Ubuntu با دسترسی <code dir="ltr">root</code> یا <code dir="ltr">sudo</code>.</li>
  <li>دامنه‌ای که زون DNS آن در آروان‌کلاد مدیریت می‌شود.</li>
  <li>کلید API با مجوز مشاهدهٔ زون و ایجاد، فهرست‌کردن و حذف رکوردهای DNS.</li>
  <li>دسترسی خروجی HTTPS به API آروان‌کلاد و سرویس صدور گواهی.</li>
</ul>
<p dir="rtl" align="right">برای اعتبارسنجی DNS-01 بازبودن پورت ۸۰ لازم نیست. پیش‌نیازهای سیستمی در صورت نیاز با <code dir="ltr">apt-get</code> نصب می‌شوند؛ اگر <code dir="ltr">acme.sh</code> نصب نباشد، نصب‌کننده آن را از upstream دریافت می‌کند.</p>

<h2 dir="rtl" align="right">ساخت کلید API و تنظیم DNS</h2>
<p dir="rtl" align="right">ساخت کلید به‌تنهایی کافی نیست؛ ماشین‌کاربر باید دسترسی مناسب به زون داشته باشد. پیوندهای رسمی:</p>
<ul dir="rtl" align="right">
  <li><a href="https://panel.arvancloud.ir/profile/iam/machine-users">پنل آروان‌کلاد — IAM / Machine Users</a></li>
  <li><a href="https://docs.arvancloud.ir/fa/developer-tools/api/api-key/">راهنمای ساخت کلید API</a></li>
  <li><a href="https://docs.arvancloud.ir/fa/accounts/iam/policies/">مستندات قوانین دسترسی IAM</a></li>
</ul>
<ol dir="rtl" align="right">
  <li>در تنظیمات پنل، بخش <span dir="ltr">IAM → Machine Users</span> یک ماشین‌کاربر بسازید.</li>
  <li>کلید را همان لحظه کپی و در محل امن نگهداری کنید. آن را در مخزن، چت یا گزارش عمومی قرار ندهید.</li>
  <li>در بخش <span dir="ltr">Access Policies</span> مجوز لازم را به همان ماشین‌کاربر و زون DNS بدهید.</li>
  <li>مطمئن شوید کلید و زون در یک حساب یا workspace هستند و مجوز مشاهدهٔ زون و مدیریت رکوردهای DNS اعمال شده است. دسترسی را تا حد ممکن محدود نگه دارید.</li>
  <li>نصب‌کننده کلید را به‌صورت مخفی دریافت می‌کند؛ مقدار خام یا مقدار دارای پیشوند <code dir="ltr">Apikey </code> پذیرفته می‌شود.</li>
</ol>

<h3 dir="rtl" align="right">اگر زون DNS شناسایی نمی‌شود</h3>
<p dir="rtl" align="right">پیام زیر یعنی API در دسترس است، اما کلید نمی‌تواند زون انتخاب‌شده را ببیند:</p>
<pre dir="ltr" align="left"><code>The ArvanCloud key can reach the API but cannot see the requested DNS zone.</code></pre>
<ul dir="rtl" align="right">
  <li>وجود زون DNS را در همان حساب آروان‌کلاد بررسی کنید؛ ثبت دامنه به‌تنهایی کافی نیست.</li>
  <li>قانون دسترسی را ذخیره کنید و مطمئن شوید ماشین‌کاربر به آن اضافه شده است.</li>
  <li>در صورت خطای دسترسی، نصب‌کننده کلید جایگزین را در ورودی مخفی می‌گیرد؛ نیازی به واردکردن دوبارهٔ دامنه و گزینه‌ها نیست. برای لغو، ورودی را خالی بگذارید.</li>
</ul>

<h2 dir="rtl" align="right">منوی تعاملی</h2>
<ol dir="rtl" align="right">
  <li>صدور و نصب گواهی Wildcard.</li>
  <li>فهرست گواهی‌های ثبت‌شده در <code dir="ltr">acme.sh</code>.</li>
  <li>بررسی صادرکننده، اعتبار، SANها و پوشش نام میزبان.</li>
  <li>اجرای بررسی عادی تمدید.</li>
  <li>نمایش لاگ‌های اخیر.</li>
  <li>بررسی پیش‌نیازهای محلی و تنظیم تمدید.</li>
</ol>

<h2 dir="rtl" align="right">استفاده از خط فرمان (CLI)</h2>
<p dir="rtl" align="right">ابتدا اسکریپت را دریافت و بررسی کنید:</p>
<pre dir="ltr" align="left"><code>curl -fsSLo install.sh https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/latest/install.sh
less install.sh</code></pre>
<p dir="rtl" align="right">پس از بررسی، برای صدور گواهی یا استفاده از گزینه‌های مدیریتی:</p>
<pre dir="ltr" align="left"><code>sudo bash install.sh --domain example.com
sudo bash install.sh --domain example.com --install-dir /root/cert/example.com --reload-cmd 'systemctl reload nginx'
sudo bash install.sh --domain example.com --x-ui
sudo bash install.sh --domain example.com --background

sudo bash install.sh --list
sudo bash install.sh --info example.com
sudo bash install.sh --renew
sudo bash install.sh --logs
sudo bash install.sh --check
sudo bash install.sh --help</code></pre>
<p dir="rtl" align="right"><code dir="ltr">--renew</code> بررسی عادی تمدید را اجرا می‌کند و به‌معنای اجبار به صدور مجدد همهٔ گواهی‌ها نیست. از <code dir="ltr">--force</code> فقط برای سفارش صدور جدید و عمدی استفاده کنید.</p>

<h2 dir="rtl" align="right">مسیر فایل‌های گواهی</h2>
<p dir="rtl" align="right">مسیر پیش‌فرض همهٔ حالت‌های نصب <code dir="ltr">/root/cert/DOMAIN/</code> است. پس از نصب موفق، اسکریپت مسیر پوشه و مسیر کامل هر فایل گواهی را به کاربر نمایش می‌دهد. گزینهٔ <code dir="ltr">--install-dir</code> برای تعیین مسیر دلخواه است:</p>
<table dir="ltr" align="left"><thead><tr><th>File</th><th>Purpose</th></tr></thead><tbody>
<tr><td><code>cert.pem</code></td><td>گواهی اصلی</td></tr>
<tr><td><code>chain.pem</code></td><td>گواهی‌های میانی</td></tr>
<tr><td><code>fullchain.pem</code></td><td>گواهی اصلی به‌همراه زنجیره</td></tr>
<tr><td><code>privkey.pem</code></td><td>کلید خصوصی؛ دسترسی فایل 600</td></tr>
</tbody></table>
<p dir="rtl" align="right">گزینهٔ <code dir="ltr">--x-ui</code> بررسی می‌کند x-ui نصب باشد و پس از نصب موفق دستور <code dir="ltr">x-ui restart</code> را اجرا می‌کند. این گزینه تنظیمات یا پایگاه دادهٔ x-ui را تغییر نمی‌دهد. در صورت استفاده از <code dir="ltr">--install-dir</code> سفارشی، سرویس را برای استفاده از همان مسیر تنظیم کنید.</p>

<h2 dir="rtl" align="right">تمدید، امنیت و لاگ‌ها</h2>
<p dir="rtl" align="right">گواهی در <code dir="ltr">acme.sh</code> ثبت می‌شود و وظیفهٔ تمدید زمان‌بندی‌شده بررسی می‌شود. برای بررسی وضعیت، از گزینه‌های <code dir="ltr">--list</code> و <code dir="ltr">--info</code> استفاده کنید. اگر زمان تمدید نرسیده باشد، بررسی عادی ممکن است سفارش جدیدی ایجاد نکند؛ این رفتار به‌تنهایی نشانهٔ خرابی نصب نیست.</p>
<ul dir="rtl" align="right">
  <li>از کلید با حداقل مجوز لازم استفاده کنید؛ کلید برای تمدیدهای آینده در پیکربندی acme.sh نگهداری می‌شود.</li>
  <li>مسیر <code dir="ltr">/root/.acme.sh/</code> و فایل <code dir="ltr">account.conf</code> را خصوصی نگه دارید.</li>
  <li>لاگ‌ها در <code dir="ltr">/var/log/arvancloud-letsencrypt/</code> ذخیره می‌شوند؛ قبل از اشتراک‌گذاری، اطلاعات حساس را حذف کنید.</li>
  <li>هرگز کلید API، کلید خصوصی یا لاگ بررسی‌نشده را در issue عمومی منتشر نکنید. کلید افشاشده را فوراً لغو یا تعویض کنید.</li>
</ul>

<h2 dir="rtl" align="right">عیب‌یابی</h2>
<ul dir="rtl" align="right">
  <li><strong>HTTP 401 یا 403:</strong> اعتبار کلید و قوانین IAM را بررسی کنید.</li>
  <li><strong>زون قابل مشاهده نیست:</strong> وجود زون در همان حساب و دسترسی ماشین‌کاربر به رکوردهای DNS را بررسی کنید.</li>
  <li><strong>صدور ناموفق است:</strong> فایل <code dir="ltr">/var/log/arvancloud-letsencrypt/acme-issue.log</code> را بررسی کنید و اطلاعات حساس را حذف کنید.</li>
  <li><strong>قطع SSH:</strong> از گزینهٔ <code dir="ltr">--background</code> استفاده و لاگ را با <code dir="ltr">sudo tail -f /var/log/arvancloud-letsencrypt/acme-issue.log</code> دنبال کنید.</li>
  <li><strong>رکورد TXT باقی مانده است:</strong> قبل از حذف دستی مطمئن شوید عملیات صدور دیگری برای دامنه در حال اجرا نیست.</li>
</ul>

<h2 dir="rtl" align="right">توسعه و انتشار</h2>
<p dir="rtl" align="right">CI نحو اسکریپت‌ها، ShellCheck و یکسان‌بودن پلاگین تعبیه‌شده در <code dir="ltr">core.sh</code> با فایل <code dir="ltr">src/dns_arvan.sh</code> را بررسی می‌کند.</p>
<pre dir="ltr" align="left"><code>bash -n install.sh
bash -n menu.sh
bash -n core.sh
sh -n src/dns_arvan.sh
shellcheck install.sh menu.sh core.sh src/dns_arvan.sh</code></pre>
<p dir="rtl" align="right">نسخه‌های منتشرشده در صفحهٔ <a href="https://github.com/power0matin/arvancloud-letsencrypt/releases">Releases</a> قرار دارند. عنوان Release فقط شمارهٔ نسخه است؛ نام پروژه و توضیحات تغییرات در بدنهٔ Release می‌آیند. مجوز پروژه <span dir="ltr">GPL-3.0-or-later</span> است؛ متن کامل در <a href="./LICENSE">LICENSE</a> قرار دارد.</p>

<h2 dir="rtl" align="right">تماس و پشتیبانی</h2>
<ul dir="rtl" align="right">
  <li>وب‌سایت: <a href="https://matinshahabadi.ir">matinshahabadi.ir</a></li>
  <li>ایمیل: <a href="mailto:me@matinshahabadi.ir">me@matinshahabadi.ir</a></li>
  <li>گیت‌هاب: <a href="https://github.com/power0matin">power0matin</a></li>
  <li>گزارش مشکل: <a href="https://github.com/power0matin/arvancloud-letsencrypt/issues">Issues</a></li>
</ul>
<p dir="rtl" align="center"><b>اگر پروژه برایتان مفید بود، با دادن ستاره از آن حمایت کنید.</b></p>
<div dir="ltr" align="center"><a href="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history?repo_id=1361637812" target="_blank"><img alt="Star history for power0matin/arvancloud-letsencrypt" src="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=1361637812&amp;image_size=auto&amp;color_scheme=light" width="721"></a></div>
<p dir="rtl" align="center">ساخته‌شده توسط <a href="https://github.com/power0matin">power0matin</a></p>

</div>
