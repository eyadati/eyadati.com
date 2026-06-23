import sys, re, json, os, random, time
from playwright.sync_api import sync_playwright, TimeoutError as PwTimeout

DZ_STRICT = re.compile(r'(0[2-7]\d{7,9}|\+213[2-7]\d{7,9}|00213[2-7]\d{7,9})')
LOCALES = ["fr-FR", "fr-DZ", "en-US", "ar-DZ"]

def normalize(raw):
    d = re.sub(r'\D', '', raw)
    if len(d) >= 9 and len(d) <= 11 and d.startswith('0'):
        return '+213' + d[1:]
    if len(d) >= 11 and len(d) <= 13 and d.startswith('213'):
        return '+' + d
    return raw.strip()

def is_phone(s):
    return bool(re.match(r'^\+213[2-7]\d{7,9}$', s))

def extract(page):
    phones = set()
    try:
        for a in page.query_selector_all('a[href*="tel:"]'):
            href = a.get_attribute("href")
            if href:
                n = href.replace("tel:","").split("?")[0].split("&")[0]
                for m in DZ_STRICT.finditer(n):
                    phones.add(m.group(0))
    except: pass
    try:
        el = page.wait_for_selector('[data-item-id="phone"] button, [data-tooltip*="Copier"], button[aria-label*="téléphone"]', timeout=6000)
        t = el.inner_text()
        for m in DZ_STRICT.finditer(t):
            phones.add(m.group(0))
        for attr in ["data-tooltip","aria-label"]:
            v = el.get_attribute(attr)
            if v:
                for m in DZ_STRICT.finditer(v):
                    phones.add(m.group(0))
    except: pass
    try:
        for btn in page.query_selector_all("button"):
            t = btn.inner_text()
            for m in DZ_STRICT.finditer(t):
                phones.add(m.group(0))
            a = btn.get_attribute("aria-label")
            if a:
                for m in DZ_STRICT.finditer(a):
                    phones.add(m.group(0))
    except: pass
    try:
        body = page.inner_text("body")
        for m in DZ_STRICT.finditer(body):
            if len(m.group(0)) >= 10:
                phones.add(m.group(0))
    except: pass
    return phones

def main():
    name = sys.argv[1]
    url = sys.argv[2]
    try:
        with sync_playwright() as p:
            b = p.chromium.launch(headless=True, args=["--no-sandbox"])
            ua = os.environ.get("PLAYWRIGHT_UA", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126.0.0.0 Safari/537.36")
            locale = random.choice(LOCALES)
            ctx = b.new_context(
                user_agent=ua,
                locale=locale,
            )
            page = ctx.new_page()
            time.sleep(random.uniform(0.5, 1.5))
            page.goto(url, wait_until="domcontentloaded", timeout=25000)
            page.wait_for_timeout(3000)
            phones = extract(page)
            page.close()
            ctx.close()
            b.close()

            if phones:
                normalized = []
                for pn in phones:
                    n = normalize(pn)
                    if is_phone(n) and n not in normalized:
                        normalized.append(n)
                if normalized:
                    print(json.dumps({"name": name, "phone": "; ".join(normalized)}))
                    return
        print(json.dumps({"name": name, "phone": ""}))
    except Exception as e:
        print(json.dumps({"name": name, "phone": "", "error": str(e)[:80]}))

if __name__ == "__main__":
    main()
