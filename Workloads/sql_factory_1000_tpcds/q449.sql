WITH daily_stats AS (
    SELECT d.d_date,
           SUM(inv.inv_quantity_on_hand) AS total_inventory,
           SUM(cc.cc_employees) AS active_employees
    FROM date_dim d
    LEFT JOIN inventory inv
           ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
           ON cc.cc_open_date_sk <= d.d_date_sk
              AND (cc.cc_closed_date_sk IS NULL OR cc.cc_closed_date_sk >= d.d_date_sk)
    GROUP BY d.d_date
)
SELECT d_date,
       total_inventory,
       active_employees,
       SUM(total_inventory) OVER (ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_inventory,
       RANK() OVER (ORDER BY total_inventory DESC) AS inventory_rank,
       CASE WHEN total_inventory > 1000 THEN 'high_inventory' ELSE 'normal_inventory' END AS inventory_level_flag
FROM daily_stats
ORDER BY d_date
LIMIT 30
