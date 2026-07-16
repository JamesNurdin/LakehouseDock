WITH sales_filtered AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_sold_date_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ship_customer_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_tax
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_ext_tax > 20.00
      AND cs.cs_net_paid_inc_ship_tax > 500
      AND t.t_shift = 'Evening'
),
agg_sales AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        d.d_moy AS month,
        hd.hd_vehicle_count,
        COUNT(DISTINCT sf.cs_ship_customer_sk) AS distinct_customers,
        SUM(sf.cs_quantity) AS total_quantity,
        SUM(sf.cs_net_paid_inc_ship_tax) AS total_net_paid,
        AVG(sf.cs_net_profit) AS avg_net_profit
    FROM sales_filtered sf
    JOIN warehouse w ON sf.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON sf.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sf.cs_ship_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        w.w_warehouse_name,
        d.d_year,
        d.d_moy,
        hd.hd_vehicle_count
)
SELECT
    a.w_warehouse_name,
    a.d_year,
    a.month,
    a.hd_vehicle_count,
    a.distinct_customers,
    a.total_quantity,
    a.total_net_paid,
    a.avg_net_profit,
    RANK() OVER (PARTITION BY a.d_year, a.month ORDER BY a.total_net_paid DESC) AS warehouse_rank_by_net_paid
FROM agg_sales a
ORDER BY a.d_year, a.month, warehouse_rank_by_net_paid
