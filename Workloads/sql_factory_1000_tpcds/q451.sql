SELECT cc.cc_call_center_sk,
       cc.cc_call_center_id,
       d_open.d_date AS open_date,
       CASE WHEN cc.cc_employees < 50 THEN 'Small'
            WHEN cc.cc_employees BETWEEN 50 AND 200 THEN 'Medium'
            ELSE 'Large' END AS size_category,
       date_diff('day', d_open.d_date, COALESCE(d_closed.d_date, CURRENT_DATE)) AS days_active,
       SUM(inv.inv_quantity_on_hand) AS total_inventory_on_open_date,
       AVG(inv.inv_quantity_on_hand) AS avg_inventory_per_warehouse,
       DENSE_RANK() OVER (ORDER BY cc.cc_employees DESC) AS employee_rank
FROM call_center cc
LEFT JOIN date_dim d_open
       ON cc.cc_open_date_sk = d_open.d_date_sk
LEFT JOIN date_dim d_closed
       ON cc.cc_closed_date_sk = d_closed.d_date_sk
LEFT JOIN inventory inv
       ON inv.inv_date_sk = d_open.d_date_sk
GROUP BY cc.cc_call_center_sk,
         cc.cc_call_center_id,
         d_open.d_date,
         cc.cc_employees,
         d_closed.d_date
ORDER BY employee_rank
LIMIT 100
