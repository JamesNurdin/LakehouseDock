WITH sales_a AS (
    SELECT
        cc.cc_call_center_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        'A' AS src
    FROM call_center cc
    RIGHT OUTER JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_ext_tax > 50
      AND cc.cc_mkt_class LIKE '%Major%'
    GROUP BY cc.cc_call_center_id
),
sales_b AS (
    SELECT
        cc.cc_call_center_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        'B' AS src
    FROM call_center cc
    RIGHT OUTER JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_ext_wholesale_cost > 1500
      AND cc.cc_hours = '8AM-4PM'
    GROUP BY cc.cc_call_center_id
),
combined AS (
    SELECT * FROM sales_a
    UNION ALL
    SELECT * FROM sales_b
)
SELECT
    combined.cc_call_center_id,
    combined.total_sales,
    combined.total_profit,
    combined.order_cnt,
    combined.src,
    ROW_NUMBER() OVER (PARTITION BY combined.cc_call_center_id ORDER BY combined.total_sales DESC) AS sales_rank
FROM combined
ORDER BY combined.total_sales DESC
LIMIT 100
