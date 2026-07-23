WITH agg_sales AS (
    SELECT
        sm.sm_ship_mode_id AS sm_ship_mode_id,
        sm.sm_carrier AS sm_carrier,
        dd.d_year AS d_year,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN date_dim ship_dd ON cs.cs_ship_date_sk = ship_dd.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE dd.d_year = 2001
      AND ship_dd.d_dow IN (1, 2, 3)
      AND sm.sm_carrier IN ('BARIAN', 'PRIVATECARRIER')
      AND cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_quantity BETWEEN 1 AND 10
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier, dd.d_year
)
SELECT
    sm_ship_mode_id,
    sm_carrier,
    SUM(total_net_paid) AS grand_total_net_paid,
    AVG(total_net_paid) AS avg_yearly_net_paid,
    SUM(total_quantity) AS grand_total_quantity,
    (SUM(total_net_paid) / (SELECT SUM(total_net_paid) FROM agg_sales) ) * 100 AS pct_of_total_net_paid
FROM agg_sales
WHERE total_quantity > 0
GROUP BY sm_ship_mode_id, sm_carrier
HAVING SUM(total_net_paid) > (SELECT AVG(total_net_paid) FROM agg_sales)
ORDER BY grand_total_net_paid DESC
