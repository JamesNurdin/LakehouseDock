WITH cat_agg AS (
    SELECT w.w_warehouse_id,
           t.t_hour,
           SUM(cs.cs_net_paid) AS total_net_paid,
           COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY w.w_warehouse_id, t.t_hour
    HAVING SUM(cs.cs_net_paid) > 1000
),
web_agg AS (
    SELECT w.w_warehouse_id,
           t.t_hour,
           SUM(ws.ws_net_paid) AS total_net_paid,
           COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY w.w_warehouse_id, t.t_hour
    HAVING SUM(ws.ws_net_paid) > 1000
),
diff_keys AS (
    SELECT w_warehouse_id, t_hour
    FROM cat_agg
    EXCEPT
    SELECT w_warehouse_id, t_hour
    FROM web_agg
)
SELECT ca.w_warehouse_id,
       ca.t_hour,
       ca.total_net_paid,
       ca.order_cnt,
       (SELECT SUM(cs3.cs_net_paid)
        FROM catalog_sales cs3
        WHERE cs3.cs_warehouse_sk = w.w_warehouse_sk) AS total_warehouse_sales_all_time
FROM cat_agg ca
JOIN diff_keys dk ON ca.w_warehouse_id = dk.w_warehouse_id
                 AND ca.t_hour = dk.t_hour
JOIN warehouse w ON ca.w_warehouse_id = w.w_warehouse_id
ORDER BY ca.total_net_paid DESC
LIMIT 100
