WITH filtered_sales AS (
    SELECT
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_list_price,
        ws.ws_ext_wholesale_cost,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_sold_date_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_ext_wholesale_cost > 1500
      AND ws.ws_list_price BETWEEN 120 AND 180
      AND ws.ws_quantity > 5
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
      AND EXISTS (
          SELECT 1
          FROM tpcds.ship_mode sm_sub
          WHERE sm_sub.sm_ship_mode_sk = ws.ws_ship_mode_sk
            AND sm_sub.sm_code = 'SEA'
      )
)
SELECT
    sm.sm_code,
    sm.sm_contract,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_list_price) AS min_list_price,
    MAX(ws.ws_list_price) AS max_list_price
FROM filtered_sales ws
JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE sm.sm_code = 'AIR'
  AND sm.sm_contract = 'qENFQ'
  AND wp.wp_max_ad_count >= 2
  AND wp.wp_autogen_flag = 'N'
GROUP BY sm.sm_code, sm.sm_contract, wp.wp_type
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
