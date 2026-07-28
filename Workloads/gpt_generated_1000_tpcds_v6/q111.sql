WITH
  sales_agg AS (
    SELECT
      i.i_item_id AS item_id,
      td.t_hour AS hour_of_day,
      SUM(cs.cs_ext_sales_price) AS total_amount,
      COUNT(*) AS transaction_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451020 AND 2451080
    GROUP BY GROUPING SETS (
      (i.i_item_id, td.t_hour),
      (i.i_item_id),
      (td.t_hour),
      ()
    )
  ),
  returns_agg AS (
    SELECT
      i.i_item_id AS item_id,
      td.t_hour AS hour_of_day,
      SUM(cr.cr_return_amount) AS total_amount,
      COUNT(*) AS transaction_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451020 AND 2451080
    GROUP BY GROUPING SETS (
      (i.i_item_id, td.t_hour),
      (i.i_item_id),
      (td.t_hour),
      ()
    )
  )
SELECT
  'sales'   AS source,
  item_id,
  hour_of_day,
  total_amount,
  transaction_cnt
FROM sales_agg
UNION ALL
SELECT
  'returns' AS source,
  item_id,
  hour_of_day,
  total_amount,
  transaction_cnt
FROM returns_agg
ORDER BY source, item_id, hour_of_day
LIMIT 100
