SELECT entity_name,
       entity_type,
       total_amount
FROM (
  SELECT w.w_warehouse_name AS entity_name,
         'WAREHOUSE_SALES' AS entity_type,
         SUM(cs.cs_net_paid_inc_ship) AS total_amount
  FROM catalog_sales cs
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE d.d_year = 2022
    AND w.w_zip = '33604'
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY w.w_warehouse_name

  UNION ALL

  SELECT s.s_store_name AS entity_name,
         'STORE_RETURNS' AS entity_type,
         SUM(sr.sr_return_amt_inc_tax) AS total_amount
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  WHERE d.d_year = 2022
    AND s.s_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY s.s_store_name
) AS combined
ORDER BY total_amount DESC
