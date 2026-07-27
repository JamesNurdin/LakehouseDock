WITH sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    sm.sm_ship_mode_id,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND i.i_manufact_id IN (264, 214)
    AND sm.sm_type = 'AIR'
    AND ca.ca_state = 'CA'
    AND t.t_hour BETWEEN 8 AND 12
    AND cs.cs_quantity > 1
  GROUP BY d.d_year, i.i_category, sm.sm_ship_mode_id
),

returns_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    CAST(NULL AS varchar) AS sm_ship_mode_id,
    SUM(wr.wr_return_amt) AS total_returns,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT wr.wr_order_number) AS returns_cnt
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_manufact_id = 264
    AND r.r_reason_desc = 'Customer not satisfied'
    AND ca.ca_country = 'United States'
    AND t.t_hour BETWEEN 9 AND 15
    AND inv.inv_quantity_on_hand > 500
  GROUP BY d.d_year, i.i_category
),

combined AS (
  SELECT
    d_year,
    i_category,
    sm_ship_mode_id,
    total_sales AS total_amount,
    avg_discount,
    orders_cnt,
    'sales' AS source_type
  FROM sales_agg
  UNION ALL
  SELECT
    d_year,
    i_category,
    sm_ship_mode_id,
    total_returns AS total_amount,
    avg_return_tax,
    returns_cnt,
    'returns' AS source_type
  FROM returns_agg
)

SELECT DISTINCT
  d_year,
  i_category,
  sm_ship_mode_id,
  source_type,
  total_amount
FROM combined
ORDER BY total_amount DESC
LIMIT 100
