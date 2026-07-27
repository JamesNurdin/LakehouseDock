SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_paid_inc_ship) AS avg_paid_inc_ship,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    MIN(ws.ws_list_price) AS min_list_price,
    MAX(ws.ws_list_price) AS max_list_price
FROM household_demographics hd
JOIN catalog_sales cs
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  AND cr.cr_item_sk = cs.cs_item_sk
JOIN web_sales ws
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE hd.hd_income_band_sk = 12
  AND hd.hd_dep_count >= 2
  AND cs.cs_ship_hdemo_sk = 6054
  AND cs.cs_net_paid_inc_ship > 3000
  AND wp.wp_type = 'product'
  AND ws.ws_list_price BETWEEN 50 AND 200
  AND cs.cs_net_paid_inc_ship > (
        SELECT AVG(cs2.cs_net_paid_inc_ship)
        FROM catalog_sales cs2
        WHERE cs2.cs_ship_hdemo_sk = cs.cs_ship_hdemo_sk
    )
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_hdemo_sk = hd.hd_demo_sk
          AND ws2.ws_net_profit > 1000
    )
GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_dep_count
ORDER BY total_sales DESC
LIMIT 100
