WITH agg_sales AS (
    SELECT
        w.w_warehouse_id,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_list_price) AS avg_list_price,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_ship_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca
        ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND w.w_state IN ('CA', 'TX', 'NY', 'WA', 'FL')
      AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
      AND cs.cs_list_price > 50
      AND cs.cs_quantity > 1
    GROUP BY w.w_warehouse_id, d.d_year, d.d_month_seq
)
SELECT
    DISTINCT a.w_warehouse_id,
    a.d_year,
    a.d_month_seq,
    a.total_net_profit,
    a.total_sales,
    a.avg_list_price,
    a.distinct_orders,
    (
        SELECT AVG(a2.total_net_profit)
        FROM agg_sales a2
        WHERE a2.d_year = a.d_year AND a2.d_month_seq = a.d_month_seq
    ) AS avg_month_profit,
    RANK() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.total_net_profit DESC) AS profit_rank,
    SUM(a.total_sales) OVER (
        PARTITION BY a.d_year
        ORDER BY a.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_year_to_month
FROM agg_sales a
WHERE a.total_net_profit > (
    SELECT AVG(a3.total_net_profit)
    FROM agg_sales a3
    WHERE a3.d_year = a.d_year AND a3.d_month_seq = a.d_month_seq
)
ORDER BY a.d_year, a.d_month_seq, profit_rank
LIMIT 100
