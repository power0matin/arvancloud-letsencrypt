<div dir="rtl" align="right">

<h1 dir="rtl" align="right">راهنمای فارسی ساخت کلید API آروان‌کلاد</h1>

<div dir="ltr" align="center">
<!-- repo-badges:start -->
<p align="center">
  <a href="https://hits.sh/github.com/power0matin/arvancloud-letsencrypt/"><img src="https://hits.sh/github.com/power0matin/arvancloud-letsencrypt.svg?style=flat-square&amp;label=Views&amp;labelColor=18181B&amp;color=0EA5E9&amp;logo=github" alt="Repository Views"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/stargazers"><img src="https://img.shields.io/github/stars/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Stars&amp;labelColor=18181B&amp;color=F59E0B&amp;logo=github&amp;logoColor=white" alt="GitHub Stars"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/forks"><img src="https://img.shields.io/github/forks/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Forks&amp;labelColor=18181B&amp;color=6366F1&amp;logo=github&amp;logoColor=white" alt="GitHub Forks"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/issues"><img src="https://img.shields.io/github/issues/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Issues&amp;labelColor=18181B&amp;color=22C55E&amp;logo=github&amp;logoColor=white" alt="GitHub Issues"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=License&amp;labelColor=18181B&amp;color=EF4444&amp;logo=github&amp;logoColor=white" alt="GitHub License"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/actions/workflows/lint.yml"><img src="https://github.com/power0matin/arvancloud-letsencrypt/actions/workflows/lint.yml/badge.svg?branch=main" alt="Shell checks"/></a>
</p>
<!-- repo-badges:end -->
</div>

<p dir="rtl" align="right">این راهنما برای تنظیم دسترسی لازم جهت صدور گواهی <span dir="ltr">Let's Encrypt</span> از طریق <span dir="ltr">DNS-01</span> است.</p>

<h2 dir="rtl" align="right">پیوندهای رسمی و مستقیم</h2>

<ul dir="rtl" align="right">
  <li><a href="https://panel.arvancloud.ir/profile/iam/machine-users">پنل آروان‌کلاد — بخش ماشین‌کاربرها (Machine Users)</a></li>
  <li><a href="https://docs.arvancloud.ir/fa/developer-tools/api/api-key/">مستندات رسمی ساخت و دریافت کلید API</a></li>
  <li><a href="https://docs.arvancloud.ir/fa/accounts/iam/policies/">مستندات رسمی قوانین دسترسی IAM</a></li>
</ul>

<h2 dir="rtl" align="right">این خطا چه معنی دارد؟</h2>

<p dir="rtl" align="right">اگر نصب‌کننده این پیام را نشان داد، یعنی به API آروان‌کلاد وصل شده اما زون DNS موردنظر را در فهرست قابل‌دسترسی این کلید پیدا نکرده است:</p>

<pre dir="ltr" align="left"><code>The ArvanCloud key can reach the API but cannot see the requested DNS zone.</code></pre>

<p dir="rtl" align="right"><strong>نکته:</strong> ساختن کلید به‌تنهایی کافی نیست. باید برای ماشین‌کاربر، قانون دسترسی مناسب تعریف شود و دامنه در همان حساب یا میزکاری وجود داشته باشد که کلید از آن ساخته شده است.</p>

<h2 dir="rtl" align="right">۱. ساخت کلید</h2>

<ol dir="rtl" align="right">
  <li>وارد <a href="https://panel.arvancloud.ir/profile/iam/machine-users">صفحهٔ ماشین‌کاربرها</a> شوید. اگر پیوند مستقیم صفحه را باز نکرد، از منوی تنظیمات وارد بخش <span dir="ltr">IAM</span> و سپس <span dir="ltr">Machine Users</span> شوید.</li>
  <li>یک ماشین‌کاربر جدید ایجاد کنید و کلید دسترسی آن را بسازید.</li>
  <li>کلید تولیدشده را همان لحظه کپی کنید و در محل امن نگه دارید. کلید را در چت، اسکرین‌شات یا گزارش عمومی منتشر نکنید.</li>
</ol>

<h2 dir="rtl" align="right">۲. دادن مجوزهای DNS</h2>

<ol dir="rtl" align="right">
  <li>از بخش تنظیمات، صفحهٔ <span dir="ltr">IAM → Access Policies</span> یا مدیریت قوانین دسترسی را باز کنید.</li>
  <li>ماشین‌کاربری را که ساخته‌اید به قانون دسترسی اضافه کنید.</li>
  <li>منبع یا میزکاری را انتخاب کنید که زون DNS دامنهٔ شما در آن قرار دارد.</li>
  <li>مجوز لازم برای مشاهدهٔ زون و خواندن، ساختن و حذف رکوردهای DNS را به آن بدهید. برای اعتبارسنجی گواهی، ابزار باید بتواند رکورد موقت <span dir="ltr">TXT</span> با نام <code dir="ltr">_acme-challenge</code> را مدیریت کند.</li>
  <li>قانون را ذخیره کنید و مطمئن شوید به همان ماشین‌کاربر و منبع صحیح اعمال شده است. دسترسی را تا جای ممکن محدود نگه دارید و بدون نیاز، دسترسی مدیر کل ندهید.</li>
</ol>

<p dir="rtl" align="right">اگر کلید پذیرفته نشود یا زون در دسترس نباشد، نصب‌کننده به‌جای شروع دوبارهٔ مراحل، از شما می‌خواهد کلید اصلاح‌شده را در ورودی مخفی وارد کنید. دامنه و گزینه‌هایی که قبلاً انتخاب کرده‌اید حفظ می‌شوند. برای لغو، ورودی کلید را خالی بگذارید.</p>

<h2 dir="rtl" align="right">۳. اگر دامنه هنوز شناسایی نمی‌شود</h2>

<ul dir="rtl" align="right">
  <li>بررسی کنید زون DNS دامنه در پنل آروان‌کلاد وجود داشته باشد؛ ثبت دامنه به‌تنهایی کافی نیست.</li>
  <li>بررسی کنید زون و کلید در همان حساب یا میزکاری باشند.</li>
  <li>قانون دسترسی را ذخیره کنید و مطمئن شوید ماشین‌کاربر به آن اضافه شده است.</li>
  <li>نصب‌کننده را دوباره اجرا کنید و کلید کامل را در ورودی مخفی وارد کنید. ابزار مقدار خام کلید یا مقدار دارای پیشوند <code dir="ltr">Apikey </code> را می‌پذیرد.</li>
</ul>

<h2 dir="rtl" align="right">۴. اجرای نصب‌کننده</h2>

<p dir="rtl" align="right">پس از اصلاح دسترسی‌ها، دستور زیر را روی سرور اجرا کنید. نصب‌کننده منوی تعاملی را باز می‌کند. پیش از اجرای هر اسکریپت راه‌دور با دسترسی مدیر، محتوای آن را بررسی کنید.</p>

<pre dir="ltr" align="left"><code>curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/latest/install.sh | sudo bash</code></pre>

<p dir="rtl" align="right">این دستور از شاخهٔ متحرک <code dir="ltr">latest</code> استفاده می‌کند. پس از انتشار موفق نسخهٔ جدید، گردش‌کار انتشار این شاخه را به‌روزرسانی می‌کند. برای نصب نسخه‌ای ثابت، به‌جای <code dir="ltr">latest</code> تگ نسخهٔ موردنظر را قرار دهید.</p>

<p dir="rtl" align="right">سپس گزینهٔ <code dir="ltr">1</code> را انتخاب و کلید را در ورودی مخفی وارد کنید.</p>

<hr>

<p dir="rtl" align="right">مخزن پروژه: <a href="https://github.com/power0matin/arvancloud-letsencrypt">ArvanCloud Let's Encrypt در GitHub</a></p>
<p dir="rtl" align="right"><a href="./README.md">بازگشت به README انگلیسی</a></p>


<hr>
<h2 dir="rtl" align="right">تماس</h2>
<p dir="rtl" align="right"><strong><span dir="ltr">Matin Shahabadi</span></strong></p>
<ul dir="rtl" align="right">
  <li>وب‌سایت: <a href="https://matinshahabadi.ir"><span dir="ltr">matinshahabadi.ir</span></a></li>
  <li>ایمیل: <a href="mailto:me@matinshahabadi.ir"><span dir="ltr">me@matinshahabadi.ir</span></a></li>
  <li>گیت‌هاب: <a href="https://github.com/power0matin"><span dir="ltr">power0matin</span></a></li>
  <li>لینکدین: <a href="https://www.linkedin.com/in/matin-shahabadi"><span dir="ltr">matin-shahabadi</span></a></li>
</ul>

<p dir="rtl" align="center">
  <b>اگر این پروژه برایتان مفید بود، با دادن ستاره از آن حمایت کنید!</b><br>
  <sub>حمایت شما به ادامهٔ توسعهٔ پروژه کمک می‌کند و باعث می‌شود دیگران راحت‌تر آن را پیدا کنند.</sub>
</p>

<div dir="ltr" align="center">
<!-- Star history widget -->
<p align="center">
  <a href="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history?repo_id=1361637812" target="_blank" style="display: block" align="center">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=1361637812&amp;image_size=auto&amp;color_scheme=dark" width="721" height="auto">
      <img alt="تاریخچه ستاره‌های مخزن power0matin/arvancloud-letsencrypt" src="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=1361637812&amp;image_size=auto&amp;color_scheme=light" width="721" height="auto">
    </picture>
  </a>
</p>
<!-- Made with [OSS Insight](https://ossinsight.io/) -->
</div>

<p dir="rtl" align="center">ساخته‌شده توسط <a href="https://github.com/power0matin"><span dir="ltr">power0matin</span></a></p>

</div>
