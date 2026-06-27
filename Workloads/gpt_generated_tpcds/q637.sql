WITH sales_summary AS (
    SELECT
        cs_call_center_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        AVG(cs_quantity) AS avg_quantity
    FROM catalog_sales
    WHERE cs_quantity > 0
    GROUP BY cs_call_center_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    ss.total_sales,
    ss.total_discount,
    ss.total_profit,
    ss.order_count,
    ss.avg_quantity,
    (ss.total_discount / NULLIF(ss.total_sales, 0)) AS discount_rate,
    ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
FROM sales_summary ss
JOIN call_center cc
    ON ss.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_state = 'CA'
ORDER BY ss.total_sales DESC
LIMIT 20
