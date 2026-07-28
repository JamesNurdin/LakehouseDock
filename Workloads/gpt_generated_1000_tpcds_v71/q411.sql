/*
  Goal: Compare daytime (9 am‑5 pm) sales revenue and return amounts for California locations.
  The query aggregates net paid sales and returned amount by hour of day, categorizes the totals
  as High/Low using a CASE expression, and combines the two result sets with UNION ALL.
  Final rows are ordered by hour and by metric type (sales then returns).
*/
WITH sales AS (
    SELECT
        td.t_hour AS hour_of_day,
        'sales' AS metric_type,
        SUM(cs.cs_net_paid_inc_ship) AS total_amount,
        CASE WHEN SUM(cs.cs_net_paid_inc_ship) > 5000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY td.t_hour
),
returns AS (
    SELECT
        td.t_hour AS hour_of_day,
        'returns' AS metric_type,
        SUM(wr.wr_return_amt_inc_tax) AS total_amount,
        CASE WHEN SUM(wr.wr_return_amt_inc_tax) > 1000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY td.t_hour
)
SELECT hour_of_day,
       metric_type,
       total_amount,
       amount_category
FROM sales
UNION ALL
SELECT hour_of_day,
       metric_type,
       total_amount,
       amount_category
FROM returns
ORDER BY hour_of_day,
         metric_type
