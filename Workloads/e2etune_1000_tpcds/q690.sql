SELECT
    w.w_warehouse_name,
    d.d_year,
    t.t_hour,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(r.total_return_amount), 0) AS total_return_amount,
    SUM(cs.cs_net_profit) - COALESCE(SUM(r.total_return_amount), 0) AS net_profit_after_returns,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    MAX(inv.avg_quantity_on_hand) AS avg_inventory_on_hand
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN (
    SELECT i.inv_date_sk,
           i.inv_warehouse_sk,
           AVG(i.inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM inventory i
    GROUP BY i.inv_date_sk, i.inv_warehouse_sk
) inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN (
    SELECT rd.d_date_sk,
           rt.t_time_sk,
           SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN date_dim rd
        ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN time_dim rt
        ON sr.sr_return_time_sk = rt.t_time_sk
    GROUP BY rd.d_date_sk, rt.t_time_sk
) r
    ON r.d_date_sk = d.d_date_sk
   AND r.t_time_sk = t.t_time_sk
WHERE d.d_year = 2002
  AND w.w_country = 'United States'
GROUP BY w.w_warehouse_name, d.d_year, t.t_hour
HAVING SUM(cs.cs_quantity) > 100
ORDER BY net_profit_after_returns DESC
LIMIT 20
