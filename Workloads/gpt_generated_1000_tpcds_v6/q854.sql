WITH sales_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        d.d_weekend,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ext_list_price > 5000
      AND cs.cs_ext_tax > 0
      AND w.w_gmt_offset = -5.00
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_weekend
)
SELECT
    s.w_warehouse_id,
    s.w_warehouse_name,
    s.d_weekend,
    s.total_net_paid,
    s.total_sales_price,
    s.orders_cnt,
    AVG(s.total_net_paid) OVER (PARTITION BY s.w_warehouse_id) AS avg_net_paid_per_warehouse,
    RANK() OVER (ORDER BY s.total_net_paid DESC) AS sales_rank,
    (SELECT MAX(cs2.cs_net_profit) FROM catalog_sales cs2) AS max_net_profit_overall
FROM sales_agg s
WHERE s.total_sales_price > (
        SELECT AVG(cs3.cs_ext_sales_price)
        FROM catalog_sales cs3
        WHERE cs3.cs_ext_list_price > 5000
    )
ORDER BY s.total_net_paid DESC
LIMIT 100
