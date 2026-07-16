WITH sales_by_warehouse AS (
    SELECT
        cs_warehouse_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        AVG(cs_ext_discount_amt) AS avg_discount_amount
    FROM catalog_sales
    GROUP BY cs_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    s.total_net_paid,
    s.total_net_profit,
    s.total_quantity,
    s.distinct_orders,
    s.avg_discount_amount,
    (s.total_net_profit / NULLIF(s.total_net_paid, 0)) AS profit_margin,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_by_warehouse s
JOIN warehouse w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
ORDER BY s.total_net_profit DESC
LIMIT 10
