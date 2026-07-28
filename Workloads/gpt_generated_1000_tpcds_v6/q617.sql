WITH high_coupon_items AS (
    SELECT DISTINCT ss_item_sk
    FROM store_sales
    WHERE ss_coupon_amt > 5000
)
SELECT
    web_site.web_name,
    cd.cd_gender,
    regexp_extract(wp.wp_url, '/product/([0-9]{4})', 1) AS product_id,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM web_sales ws
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site
  ON ws.ws_web_site_sk = web_site.web_site_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE regexp_like(wp.wp_url, '/product/[0-9]{4}')
  AND web_site.web_name LIKE 'A%'
  AND ib.ib_lower_bound >= 50000
  AND ws.ws_item_sk IN (SELECT ss_item_sk FROM high_coupon_items)
GROUP BY
    web_site.web_name,
    cd.cd_gender,
    regexp_extract(wp.wp_url, '/product/([0-9]{4})', 1)
ORDER BY total_net_paid DESC
LIMIT 100
