WITH returns_data AS (
  SELECT
    cr.cr_order_number,
    d.d_date AS event_date,
    ca.ca_city AS city,
    CASE WHEN cr.cr_return_amount > 500 THEN 'High' ELSE 'Low' END AS amount_category,
    cr.cr_return_amount AS amount
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND cr.cr_return_amount IS NOT NULL
),
sales_data AS (
  SELECT
    cs.cs_order_number AS cr_order_number,
    d.d_date AS event_date,
    ca.ca_city AS city,
    CASE WHEN cs.cs_net_paid > 500 THEN 'High' ELSE 'Low' END AS amount_category,
    cs.cs_net_paid AS amount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
  JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND NOT EXISTS (
      SELECT 1 FROM catalog_returns cr
      WHERE cr.cr_order_number = cs.cs_order_number
    )
)
SELECT *
FROM returns_data
UNION ALL
SELECT *
FROM sales_data
ORDER BY cr_order_number, event_date DESC
LIMIT 100
