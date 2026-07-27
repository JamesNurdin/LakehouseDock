WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ext_list_price,
        ws.ws_ext_tax,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM tpcds.web_sales ws
    WHERE ws.ws_ext_list_price > 2000
      AND ws.ws_ext_tax < 50
)
SELECT
    ws_site.web_site_id,
    wp.wp_web_page_id,
    hd.hd_buy_potential,
    COUNT(*) AS order_cnt,
    SUM(fs.ws_net_profit) AS total_profit,
    AVG(fs.ws_ext_tax) AS avg_tax,
    MIN(fs.ws_ext_list_price) AS min_price,
    MAX(fs.ws_ext_list_price) AS max_price
FROM filtered_sales fs
JOIN tpcds.household_demographics hd
    ON fs.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_page wp
    ON fs.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site ws_site
    ON fs.ws_web_site_sk = ws_site.web_site_sk
WHERE hd.hd_vehicle_count >= 2
  AND hd.hd_buy_potential = '5001-10000'
  AND wp.wp_rec_start_date >= DATE '2000-01-01'
  AND wp.wp_type = 'home'
  AND ws_site.web_gmt_offset BETWEEN -5 AND 5
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_page wp2
        WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
          AND wp2.wp_char_count > 1000
    )
GROUP BY ws_site.web_site_id, wp.wp_web_page_id, hd.hd_buy_potential
HAVING SUM(fs.ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
