WITH sales_by_warehouse AS (
    SELECT
        cs.cs_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_paid) AS total_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 0
    GROUP BY cs.cs_warehouse_sk, w.w_warehouse_name, w.w_state
)
SELECT
    cs_warehouse_sk,
    w_warehouse_name,
    w_state,
    total_sales,
    total_paid,
    total_profit,
    total_quantity,
    avg_discount,
    order_count,
    total_profit / total_sales AS profit_margin
FROM sales_by_warehouse
ORDER BY profit_margin DESC
LIMIT 10
