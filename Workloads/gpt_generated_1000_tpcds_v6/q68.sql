WITH distinct_cc AS (
    SELECT DISTINCT cc_call_center_sk
    FROM call_center
    WHERE cc_class = 'large'
      AND cc_state = 'CA'
      AND cc_gmt_offset BETWEEN -5 AND -4
      AND cc_tax_percentage < 5.0
),
sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 5
      AND cs.cs_ext_sales_price > 1000
    GROUP BY cs.cs_call_center_sk, cs.cs_warehouse_sk, cs.cs_sold_date_sk
)
SELECT
    d.d_date,
    cc.cc_name,
    w.w_warehouse_name,
    sa.total_sales,
    sa.avg_profit,
    sa.distinct_orders,
    sa.total_quantity
FROM sales_agg sa
JOIN distinct_cc dc ON sa.cs_call_center_sk = dc.cc_call_center_sk
JOIN call_center cc ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON sa.cs_sold_date_sk = d.d_date_sk
WHERE w.w_state = 'TX'
ORDER BY sa.total_sales DESC
LIMIT 100
