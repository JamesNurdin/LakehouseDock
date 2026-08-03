WITH high_profit AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_city,
        CASE WHEN cs.cs_coupon_amt > 500 THEN 'HIGH' ELSE 'LOW' END AS coupon_category,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY cs.cs_net_profit DESC) AS profit_rank
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_net_profit > 2000
),
low_profit AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_city,
        CASE WHEN cs.cs_coupon_amt > 500 THEN 'HIGH' ELSE 'LOW' END AS coupon_category,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY cs.cs_net_profit DESC) AS profit_rank
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_net_profit <= 2000
),
combined AS (
    SELECT * FROM high_profit
    UNION ALL
    SELECT * FROM low_profit
)
SELECT DISTINCT
    c.cc_call_center_id,
    c.cc_city,
    c.coupon_category,
    c.profit_rank,
    c.cs_net_profit,
    (
        SELECT avg(cs2.cs_net_profit)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_call_center_sk = c.cs_call_center_sk
    ) AS avg_center_profit
FROM combined c
WHERE c.cs_order_number NOT IN (
    SELECT cs3.cs_order_number
    FROM tpcds.catalog_sales cs3
    WHERE cs3.cs_coupon_amt > 4000
)
ORDER BY c.cc_call_center_id, c.profit_rank
LIMIT 100
