WITH returns_by_day AS (
  SELECT
    d.d_date AS return_date,
    r.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    CASE
      WHEN regexp_like(r.r_reason_desc, '^Customer.*') THEN 'Customer'
      ELSE 'Other'
    END AS reason_category
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_date, r.r_reason_desc,
    CASE WHEN regexp_like(r.r_reason_desc, '^Customer.*') THEN 'Customer' ELSE 'Other' END
),
sales_by_day AS (
  SELECT
    d.d_date AS sale_date,
    ws.ws_web_site_sk,
    ws.ws_web_page_sk,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CONCAT(CAST(ws.ws_order_number AS VARCHAR), '-', CAST(ws.ws_quantity AS VARCHAR)) AS order_key,
    SUBSTRING(wp.wp_url, 1, 20) AS url_prefix
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year = 2001
    AND regexp_like(wp.wp_url, '^https?://.*\\.com')
    AND wp.wp_url LIKE '%/search%'
  GROUP BY d.d_date, ws.ws_web_site_sk, ws.ws_web_page_sk, ws.ws_order_number, ws.ws_quantity, wp.wp_url
)
SELECT
  rbd.return_date,
  rbd.reason_category,
  rbd.return_cnt,
  rbd.total_return_amount,
  sbd.sale_date,
  sbd.total_sales,
  sbd.total_profit,
  sbd.url_prefix,
  sbd.order_key
FROM returns_by_day rbd
JOIN sales_by_day sbd ON rbd.return_date = sbd.sale_date
ORDER BY rbd.return_date DESC
LIMIT 100
