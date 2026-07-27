WITH cs AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship > 1000
),
ws AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship,
        ws.ws_web_page_sk
    FROM web_sales ws
    WHERE ws.ws_net_paid_inc_ship > 500
)
SELECT
    d_cs.d_year,
    hd.hd_buy_potential,
    COALESCE(wp.wp_type, 'UNKNOWN') AS page_type,
    SUM(cs.cs_net_paid_inc_ship) AS total_catalog_sales,
    SUM(ws.ws_net_paid_inc_ship) AS total_web_sales,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    MIN(cs.cs_net_paid_inc_ship) AS min_catalog_sale,
    MAX(ws.ws_net_paid_inc_ship) AS max_web_sale
FROM cs
JOIN date_dim d_cs
  ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN ws
  ON cs.cs_bill_hdemo_sk = ws.ws_bill_hdemo_sk
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim d_wp
  ON wp.wp_creation_date_sk = d_wp.d_date_sk
WHERE d_cs.d_year = 2000
  AND hd.hd_vehicle_count > 1
  AND (d_wp.d_year = 2000 OR d_wp.d_year IS NULL)
  AND wp.wp_rec_end_date > DATE '2000-01-01'
GROUP BY d_cs.d_year,
         hd.hd_buy_potential,
         COALESCE(wp.wp_type, 'UNKNOWN')
ORDER BY total_catalog_sales DESC
LIMIT 100
