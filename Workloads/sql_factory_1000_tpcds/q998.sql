WITH ship_sales AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    ds_ship.d_date AS ship_date,
    ds_sales.d_date AS sales_date,
    DATE_DIFF('day', ds_sales.d_date, ds_ship.d_date) AS ship_sales_lag,
    CASE
      WHEN DATE_DIFF('day', ds_sales.d_date, ds_ship.d_date) > 30 THEN 'Long Delay'
      ELSE 'Normal'
    END AS delay_category
  FROM customer c
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN date_dim ds_ship ON c.c_first_shipto_date_sk = ds_ship.d_date_sk
  JOIN date_dim ds_sales ON c.c_first_sales_date_sk = ds_sales.d_date_sk
)
SELECT
  c_customer_id,
  c_first_name,
  c_last_name,
  ca_state,
  ship_date,
  sales_date,
  ship_sales_lag,
  delay_category,
  ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ship_sales_lag DESC) AS lag_rank_state
FROM ship_sales
WHERE delay_category = 'Long Delay'
ORDER BY ca_state, lag_rank_state
