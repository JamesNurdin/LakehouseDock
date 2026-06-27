WITH warehouse_sales AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        w.w_city,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        w.w_city
)
SELECT
    w_warehouse_id,
    w_warehouse_name,
    w_state,
    w_city,
    total_quantity,
    total_sales,
    total_discount,
    total_net_paid,
    total_net_profit,
    (total_net_profit / NULLIF(total_net_paid, 0)) AS profit_margin,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM warehouse_sales
WHERE total_net_profit > 0
ORDER BY profit_rank
LIMIT 10
