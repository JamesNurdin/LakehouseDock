WITH
  sampled_pages AS (
    SELECT
      wp_web_page_sk,
      wp_url,
      wp_type,
      regexp_extract(wp_url, '(https?://[^/]+)') AS domain,
      CASE WHEN regexp_like(wp_url, '\\.html$') THEN true ELSE false END AS is_html,
      CONCAT('URL:', wp_url) AS url_label,
      substr(wp_url, 1, 10) AS url_prefix
    FROM web_page
    TABLESAMPLE BERNOULLI (10)
  ),
  sales_by_page AS (
    SELECT
      sp.wp_web_page_sk,
      sp.wp_type,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      AVG(ws.ws_quantity) AS avg_quantity,
      COUNT(*) AS sales_cnt
    FROM sampled_pages sp
    JOIN web_sales ws
      ON ws.ws_web_page_sk = sp.wp_web_page_sk
    WHERE sp.wp_type LIKE 'ad%'
      AND sp.is_html = true
    GROUP BY sp.wp_web_page_sk, sp.wp_type
  ),
  high_perf AS (
    SELECT wp_web_page_sk, total_sales, total_profit
    FROM sales_by_page
    WHERE total_profit > 2000
  ),
  low_perf AS (
    SELECT wp_web_page_sk, total_sales, total_profit
    FROM sales_by_page
    WHERE total_profit < 500
  ),
  high_minus_low AS (
    SELECT wp_web_page_sk FROM high_perf
    EXCEPT
    SELECT wp_web_page_sk FROM low_perf
  ),
  ad_pages AS (
    SELECT wp_web_page_sk FROM sampled_pages WHERE wp_type LIKE 'ad%'
  ),
  html_pages AS (
    SELECT wp_web_page_sk FROM sampled_pages WHERE regexp_like(wp_url, '\\.html$')
  ),
  ad_and_html AS (
    SELECT wp_web_page_sk FROM ad_pages
    INTERSECT
    SELECT wp_web_page_sk FROM html_pages
  ),
  full_combined AS (
    SELECT
      hp.wp_web_page_sk,
      hp.total_sales,
      hp.total_profit,
      lp.total_sales AS low_total_sales,
      lp.total_profit AS low_total_profit
    FROM high_perf hp
    FULL OUTER JOIN low_perf lp
      ON hp.wp_web_page_sk = lp.wp_web_page_sk
  )
SELECT
  fc.wp_web_page_sk,
  fc.total_sales,
  fc.total_profit,
  fc.low_total_sales,
  fc.low_total_profit,
  CASE WHEN hml.wp_web_page_sk IS NOT NULL THEN true ELSE false END AS in_high_minus_low,
  CASE WHEN aah.wp_web_page_sk IS NOT NULL THEN true ELSE false END AS in_ad_and_html
FROM full_combined fc
LEFT JOIN (SELECT wp_web_page_sk FROM high_minus_low) hml
  ON fc.wp_web_page_sk = hml.wp_web_page_sk
LEFT JOIN (SELECT wp_web_page_sk FROM ad_and_html) aah
  ON fc.wp_web_page_sk = aah.wp_web_page_sk
LIMIT 100
