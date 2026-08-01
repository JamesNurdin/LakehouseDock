WITH sales AS (
  SELECT
    d.d_date AS transaction_date,
    i.i_category AS category,
    'sales' AS transaction_type,
    SUM(cs.cs_net_paid) AS amount,
    SUM(cs.cs_quantity) AS units
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE cc.cc_street_type = 'Court'
    AND i.i_manager_id IN (26, 41)
    AND i.i_manufact = 'antiablecally'
    AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-01-31'
  GROUP BY d.d_date, i.i_category
),
returns AS (
  SELECT
    d.d_date AS transaction_date,
    i.i_category AS category,
    'returns' AS transaction_type,
    SUM(sr.sr_net_loss) AS amount,
    SUM(sr.sr_return_quantity) AS units
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE i.i_manager_id IN (26, 41)
    AND i.i_manufact = 'antiablecally'
    AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-01-31'
  GROUP BY d.d_date, i.i_category
)
SELECT transaction_date,
       category,
       transaction_type,
       amount,
       units
FROM sales
UNION ALL
SELECT transaction_date,
       category,
       transaction_type,
       amount,
       units
FROM returns
ORDER BY transaction_date, category, transaction_type
