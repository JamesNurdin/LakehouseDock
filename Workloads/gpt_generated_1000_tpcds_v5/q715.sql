WITH base_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_qty,
        AVG(ws.ws_list_price) AS avg_list_price,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
    FROM tpcds.web_sales ws
    WHERE ws.ws_list_price > 100
      AND ws.ws_ext_discount_amt BETWEEN 0 AND 200
      AND ws.ws_quantity >= 1
    GROUP BY ws.ws_web_site_sk, ws.ws_ship_mode_sk, ws.ws_web_page_sk, ws.ws_sold_date_sk
    HAVING SUM(ws.ws_net_profit) > 500
)
SELECT
    bs.ws_web_site_sk,
    bs.ws_ship_mode_sk,
    sm.sm_type,
    sm.sm_carrier,
    bs.total_profit,
    bs.total_qty,
    bs.avg_list_price,
    ROW_NUMBER() OVER (PARTITION BY bs.ws_web_site_sk ORDER BY bs.total_profit DESC) AS profit_rank,
    CASE WHEN bs.avg_list_price > 150 THEN 'HIGH' ELSE 'LOW' END AS price_category,
    (SELECT COUNT(*) FROM tpcds.web_sales ws2 WHERE ws2.ws_web_site_sk = bs.ws_web_site_sk) AS site_order_count
FROM base_sales bs
JOIN tpcds.ship_mode sm
  ON bs.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_site wsit
  ON bs.ws_web_site_sk = wsit.web_site_sk
JOIN tpcds.web_page wp
  ON bs.ws_web_page_sk = wp.wp_web_page_sk
WHERE wsit.web_rec_start_date >= DATE '1999-01-01'
  AND wsit.web_county IN ('Bronx County', 'Maverick County', 'San Miguel County')
  AND wp.wp_max_ad_count >= 2
  AND sm.sm_carrier LIKE 'U%'
ORDER BY bs.total_profit DESC
LIMIT 100
