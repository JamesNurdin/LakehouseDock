SELECT source,
       warehouse_name,
       warehouse_sq_ft,
       total_net_paid,
       avg_net_profit,
       size_ratio,
       larger_warehouse_count
FROM (
    SELECT 'catalog' AS source,
           w.w_warehouse_name AS warehouse_name,
           w.w_warehouse_sq_ft AS warehouse_sq_ft,
           SUM(cs.cs_net_paid) AS total_net_paid,
           AVG(cs.cs_net_profit) AS avg_net_profit,
           w.w_warehouse_sq_ft / (
               SELECT MAX(w2.w_warehouse_sq_ft)
               FROM warehouse w2
           ) AS size_ratio,
           lw.larger_warehouse_count
    FROM catalog_sales cs
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS larger_warehouse_count
        FROM warehouse w2
        WHERE w2.w_warehouse_sq_ft > w.w_warehouse_sq_ft
    ) lw
    WHERE td.t_meal_time = 'dinner'
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = cs.cs_bill_hdemo_sk
            AND hd.hd_vehicle_count >= 2
      )
    GROUP BY w.w_warehouse_name,
             w.w_warehouse_sq_ft,
             lw.larger_warehouse_count
    UNION ALL
    SELECT 'web' AS source,
           w.w_warehouse_name AS warehouse_name,
           w.w_warehouse_sq_ft AS warehouse_sq_ft,
           SUM(ws.ws_net_paid) AS total_net_paid,
           AVG(ws.ws_net_profit) AS avg_net_profit,
           w.w_warehouse_sq_ft / (
               SELECT MAX(w2.w_warehouse_sq_ft)
               FROM warehouse w2
           ) AS size_ratio,
           lw.larger_warehouse_count
    FROM web_sales ws
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS larger_warehouse_count
        FROM warehouse w2
        WHERE w2.w_warehouse_sq_ft > w.w_warehouse_sq_ft
    ) lw
    WHERE td.t_meal_time = 'dinner'
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = ws.ws_bill_hdemo_sk
            AND hd.hd_vehicle_count >= 2
      )
    GROUP BY w.w_warehouse_name,
             w.w_warehouse_sq_ft,
             lw.larger_warehouse_count
) AS combined
ORDER BY source,
         total_net_paid DESC
