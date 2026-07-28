WITH large_m AS (
    SELECT
        cc.cc_division_name AS division_name,
        'large_M' AS segment,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_class = 'large'
      AND cd.cd_marital_status = 'M'
    GROUP BY cc.cc_division_name
),
small_high_buy AS (
    SELECT
        cc.cc_division_name AS division_name,
        'small_high_buy' AS segment,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_class = 'small'
      AND hd.hd_buy_potential = '>10000'
    GROUP BY cc.cc_division_name
)
SELECT division_name, segment, total_net_profit, order_count
FROM large_m
UNION ALL
SELECT division_name, segment, total_net_profit, order_count
FROM small_high_buy
ORDER BY total_net_profit DESC
LIMIT 10
