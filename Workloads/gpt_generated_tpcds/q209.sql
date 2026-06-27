WITH warehouse_sales AS (
    SELECT
        cs.cs_warehouse_sk,
        sum(cs.cs_ext_sales_price) AS total_sales,
        sum(cs.cs_ext_discount_amt) AS total_discount,
        sum(cs.cs_net_profit) AS total_profit,
        count(*) AS sales_count,
        avg(cs.cs_quantity) AS avg_quantity,
        avg(cs.cs_ext_discount_amt / nullif(cs.cs_ext_sales_price, 0)) AS avg_discount_rate,
        count(DISTINCT cs.cs_item_sk) AS distinct_items_sold
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    GROUP BY cs.cs_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    ws.total_sales,
    ws.total_discount,
    ws.total_profit,
    ws.sales_count,
    ws.avg_quantity,
    ws.avg_discount_rate,
    ws.distinct_items_sold,
    ws.total_profit / nullif(ws.total_sales, 0) AS profit_margin,
    rank() OVER (ORDER BY ws.total_profit DESC) AS profit_rank,
    sum(ws.total_profit) OVER (
        PARTITION BY w.w_state
        ORDER BY ws.total_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_state_profit
FROM warehouse_sales ws
JOIN warehouse w
    ON ws.cs_warehouse_sk = w.w_warehouse_sk
ORDER BY ws.total_profit DESC
LIMIT 10
