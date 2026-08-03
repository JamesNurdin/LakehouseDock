WITH cs_time AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_wholesale_cost,
        cs.cs_net_paid_inc_ship,
        td.t_time,
        td.t_am_pm,
        td.t_hour
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_quantity >= 2
      AND cs.cs_ext_wholesale_cost BETWEEN 400 AND 2000
      AND td.t_time = 12
      AND td.t_am_pm = 'PM'
      AND cs.cs_net_paid_inc_ship > 1000
)
SELECT
    cs_time.cs_sold_date_sk AS sold_date_sk,
    cs_time.t_hour,
    CASE WHEN ws.ws_list_price > 150 THEN 'High' ELSE 'Low' END AS price_category,
    SUM(cs_time.cs_net_paid_inc_ship) AS total_net_paid_inc_ship,
    AVG(ws.ws_net_paid) AS avg_ws_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(wr.wr_return_amt) AS min_return_amt,
    MAX(cs_time.cs_ext_wholesale_cost) AS max_wholesale_cost
FROM cs_time
FULL OUTER JOIN web_sales ws
    ON cs_time.cs_sold_time_sk = ws.ws_sold_time_sk
LEFT JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
WHERE ws.ws_ext_ship_cost < 500
  AND ws.ws_list_price BETWEEN 50 AND 200
  AND (wr.wr_return_quantity = 1 OR wr.wr_return_quantity IS NULL)
  AND cs_time.cs_ext_wholesale_cost > (
        SELECT MIN(cs_ext_wholesale_cost)
        FROM catalog_sales
        WHERE cs_quantity = 1
    )
  AND EXISTS (
        SELECT 1
        FROM time_dim td2
        WHERE td2.t_hour = cs_time.t_hour
          AND td2.t_am_pm = cs_time.t_am_pm
    )
GROUP BY cs_time.cs_sold_date_sk,
         cs_time.t_hour,
         CASE WHEN ws.ws_list_price > 150 THEN 'High' ELSE 'Low' END
ORDER BY total_net_paid_inc_ship DESC
LIMIT 100
