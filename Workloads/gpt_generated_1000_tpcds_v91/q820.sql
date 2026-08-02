WITH high_tax_sales AS (
    SELECT
        cc.cc_city AS city,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_net_profit) AS total_net_profit,
        count(*) AS order_count
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_ext_tax > 50
        AND cs.cs_ext_wholesale_cost > 2000
        AND cs.cs_call_center_sk IN (
            SELECT cc2.cc_call_center_sk
            FROM call_center cc2
            WHERE cc2.cc_company = 4
        )
        AND NOT EXISTS (
            SELECT 1
            FROM call_center cc_ex
            WHERE cc_ex.cc_call_center_sk = cs.cs_call_center_sk
              AND cc_ex.cc_tax_percentage > 5
        )
    GROUP BY cc.cc_city
),
low_tax_sales AS (
    SELECT
        cc.cc_city AS city,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_net_profit) AS total_net_profit,
        count(*) AS order_count
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_ext_tax <= 50
        AND cs.cs_ext_wholesale_cost <= 500
        AND cc.cc_state = 'TX'
        AND cs.cs_call_center_sk IN (
            SELECT cc2.cc_call_center_sk
            FROM call_center cc2
            WHERE cc2.cc_company = 4
        )
        AND NOT EXISTS (
            SELECT 1
            FROM call_center cc_ex
            WHERE cc_ex.cc_call_center_sk = cs.cs_call_center_sk
              AND cc_ex.cc_gmt_offset > 0
        )
    GROUP BY cc.cc_city
)
SELECT city, total_net_paid, total_net_profit, order_count
FROM high_tax_sales
UNION ALL
SELECT city, total_net_paid, total_net_profit, order_count
FROM low_tax_sales
LIMIT 100
