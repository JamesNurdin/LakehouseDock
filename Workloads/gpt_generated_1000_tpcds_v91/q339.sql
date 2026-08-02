WITH cs_base AS (
  SELECT
    CAST(cs.cs_order_number AS BIGINT) AS order_id,
    cs.cs_ext_sales_price AS amount,
    cs.cs_quantity AS quantity,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    'Sale' AS transaction_type,
    la.avg_sales_price,
    cr.cr_return_amount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  CROSS JOIN LATERAL (
    SELECT avg(cs2.cs_ext_sales_price) AS avg_sales_price
    FROM catalog_sales cs2
    WHERE cs2.cs_call_center_sk = cs.cs_call_center_sk
  ) AS la
  WHERE d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND cc.cc_state = 'CA'
    AND cp.cp_type = 'Promotion'
    AND hd.hd_vehicle_count >= 2
),
store_ret AS (
  SELECT
    CAST(sr.sr_ticket_number AS BIGINT) AS order_id,
    CAST(sr.sr_return_amt AS DECIMAL(7,2)) AS amount,
    sr.sr_return_quantity AS quantity,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    'StoreReturn' AS transaction_type,
    NULL AS avg_sales_price
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE sr.sr_return_amt > 500
    AND d.d_year = 2001
    AND hd.hd_dep_count >= 1
),
final_union AS (
  SELECT order_id, amount, quantity, year, month_seq, transaction_type, avg_sales_price
  FROM cs_base
  UNION ALL
  SELECT order_id, amount, quantity, year, month_seq, transaction_type, avg_sales_price
  FROM store_ret
)
SELECT
  order_id,
  transaction_type,
  amount,
  quantity,
  year,
  month_seq,
  avg_sales_price,
  ROW_NUMBER() OVER (PARTITION BY transaction_type ORDER BY amount DESC) AS rn,
  RANK() OVER (ORDER BY amount DESC) AS amount_rank,
  CASE
    WHEN amount > 10000 THEN 'Very High'
    WHEN amount > 5000 THEN 'High'
    WHEN amount > 1000 THEN 'Medium'
    ELSE 'Low'
  END AS amount_category
FROM final_union fu
WHERE NOT EXISTS (
  SELECT 1
  FROM catalog_returns cr
  WHERE cr.cr_order_number = fu.order_id
)
ORDER BY amount DESC, transaction_type
LIMIT 100
