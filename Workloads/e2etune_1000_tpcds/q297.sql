WITH sales_agg AS (
    SELECT
        wsite.web_name AS web_site_name,
        ws.ws_ship_mode_sk,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(bhd.hd_vehicle_count) AS avg_bill_vehicle_cnt,
        AVG(shd.hd_vehicle_count) AS avg_ship_vehicle_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics bhd ON ws.ws_bill_hdemo_sk = bhd.hd_demo_sk
    JOIN household_demographics shd ON ws.ws_ship_hdemo_sk = shd.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
      AND i.i_category IN ('Books', 'Electronics', 'Clothing')
      AND sm.sm_type = 'AIR'
    GROUP BY wsite.web_name, ws.ws_ship_mode_sk, i.i_category
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    web_site_name,
    ws_ship_mode_sk,
    i_category,
    total_net_profit,
    avg_discount,
    distinct_customers,
    total_quantity,
    avg_bill_vehicle_cnt,
    avg_ship_vehicle_cnt,
    RANK() OVER (PARTITION BY web_site_name, ws_ship_mode_sk ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY web_site_name, ws_ship_mode_sk, profit_rank
LIMIT 10
