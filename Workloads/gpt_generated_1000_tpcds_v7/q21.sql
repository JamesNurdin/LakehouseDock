WITH cs_agg AS (
    SELECT
        cs_call_center_sk,
        cs_ship_mode_sk,
        SUM(cs_net_profit) AS cs_total_profit,
        COUNT(*) AS cs_orders
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450815 AND 2450840
      AND cs_net_paid > 1000
      AND cs_quantity > 0
      AND cs_ext_discount_amt < 5000
      AND cs_list_price > 0
    GROUP BY cs_call_center_sk, cs_ship_mode_sk
),
ws_agg AS (
    SELECT
        ws_ship_mode_sk,
        SUM(ws_net_profit) AS ws_total_profit,
        COUNT(*) AS ws_orders
    FROM web_sales
    WHERE ws_ext_discount_amt < 3000
      AND ws_quantity > 0
      AND ws_sold_date_sk BETWEEN 2450815 AND 2450840
      AND ws_net_paid > 500
      AND ws_list_price > 0
    GROUP BY ws_ship_mode_sk
)
SELECT
    cc.cc_name,
    sm.sm_type,
    ca.cs_total_profit,
    wa.ws_total_profit,
    (ca.cs_total_profit + wa.ws_total_profit) AS combined_profit,
    RANK() OVER (ORDER BY (ca.cs_total_profit + wa.ws_total_profit) DESC) AS profit_rank,
    CASE
        WHEN ca.cs_total_profit > wa.ws_total_profit THEN 'Catalog higher'
        WHEN ca.cs_total_profit < wa.ws_total_profit THEN 'Web higher'
        ELSE 'Equal'
    END AS profit_source,
    (SELECT AVG(cs_net_profit) FROM catalog_sales) AS avg_cs_profit
FROM cs_agg ca
JOIN call_center cc
    ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN ws_agg wa
    ON sm.sm_ship_mode_sk = wa.ws_ship_mode_sk
WHERE cc.cc_mkt_class LIKE 'Major%'
  AND cc.cc_suite_number = 'Suite 340'
  AND sm.sm_carrier = 'UPS'
  AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
  AND NOT EXISTS (
        SELECT 1 FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
          AND cs2.cs_quantity = 0
    )
ORDER BY combined_profit DESC
LIMIT 100
