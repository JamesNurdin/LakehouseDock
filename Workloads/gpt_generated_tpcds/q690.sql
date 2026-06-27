WITH sales_by_center AS (
    SELECT
        c.cc_call_center_id,
        c.cc_name,
        c.cc_state,
        c.cc_country,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN call_center c
        ON cs.cs_call_center_sk = c.cc_call_center_sk
    WHERE c.cc_state = 'CA'
    GROUP BY c.cc_call_center_id, c.cc_name, c.cc_state, c.cc_country
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_state,
    cc_country,
    total_sales,
    total_profit,
    avg_discount,
    distinct_orders,
    total_quantity,
    total_profit / NULLIF(total_sales, 0) AS profit_margin
FROM sales_by_center
ORDER BY total_profit DESC
LIMIT 10
