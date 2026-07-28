SELECT
    cs_order_number,
    cs_net_paid,
    t_time,
    w_city,
    avg_warehouse_profit
FROM (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        t.t_time,
        w.w_city,
        (SELECT avg(cs2.cs_net_profit)
         FROM catalog_sales cs2
         WHERE cs2.cs_warehouse_sk = cs.cs_warehouse_sk) AS avg_warehouse_profit
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_purchase_estimate >= 6000
      AND w.w_street_type = 'Avenue'
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd2
          WHERE cd2.cd_demo_sk = cs.cs_ship_cdemo_sk
            AND cd2.cd_dep_college_count >= 3
      )
    UNION ALL
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        t.t_time,
        w.w_city,
        (SELECT avg(cs2.cs_net_profit)
         FROM catalog_sales cs2
         WHERE cs2.cs_warehouse_sk = cs.cs_warehouse_sk) AS avg_warehouse_profit
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND w.w_zip LIKE '3%'
      AND cd.cd_marital_status = 'M'
) AS combined
ORDER BY avg_warehouse_profit DESC, cs_order_number
LIMIT 100
