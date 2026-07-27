WITH filtered_ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ship_mode_sk,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_web_page_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_sales_price > 100.00
      AND ws.ws_ext_discount_amt < 300.00
      AND ws.ws_quantity >= 2
      AND ws.ws_ship_mode_sk IS NOT NULL
),
avg_ws_discount AS (
    SELECT sm.sm_ship_mode_sk,
           AVG(fw.ws_ext_discount_amt) AS avg_discount
    FROM filtered_ws fw
    JOIN ship_mode sm ON fw.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_sk
)
SELECT
    cp.cp_department,
    sm.sm_carrier,
    hd.hd_buy_potential,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(cs.cs_net_profit) AS catalog_total_profit,
    AVG(cs.cs_sales_price) AS catalog_avg_sales_price,
    SUM(fw.ws_net_profit) AS web_total_profit,
    AVG(fw.ws_sales_price) AS web_avg_sales_price,
    MIN(cs.cs_ext_discount_amt) AS catalog_min_discount,
    MAX(cs.cs_ext_discount_amt) AS catalog_max_discount
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN filtered_ws fw
  ON fw.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
  ON fw.ws_web_page_sk = wp.wp_web_page_sk
JOIN avg_ws_discount awd
  ON sm.sm_ship_mode_sk = awd.sm_ship_mode_sk
WHERE cp.cp_department = 'Electronics'
  AND cp.cp_type = 'Catalog'
  AND sm.sm_type = 'AIR'
  AND hd.hd_buy_potential = '>10000'
  AND hd.hd_vehicle_count >= 2
  AND cs.cs_quantity >= 2
  AND cs.cs_ext_discount_amt > awd.avg_discount
GROUP BY
    cp.cp_department,
    sm.sm_carrier,
    hd.hd_buy_potential,
    wp.wp_type
ORDER BY catalog_total_profit DESC
LIMIT 100
