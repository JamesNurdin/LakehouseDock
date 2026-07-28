WITH returns AS (
  SELECT
    'Return' AS segment,
    r.r_reason_desc AS description,
    i.i_category AS category,
    SUM(cr.cr_return_amount) AS total_amount,
    COUNT(*) AS transaction_count,
    CASE WHEN SUM(cr.cr_return_amount) > 200 THEN 'High' ELSE 'Low' END AS amount_category,
    ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450150
  GROUP BY GROUPING SETS (
    (r.r_reason_desc, i.i_category),
    (r.r_reason_desc),
    (i.i_category),
    ()
  )
),
sales AS (
  SELECT
    'Sale' AS segment,
    p.p_promo_name AS description,
    i.i_category AS category,
    SUM(ws.ws_ext_sales_price) AS total_amount,
    COUNT(*) AS transaction_count,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450150
  GROUP BY ROLLUP (p.p_promo_name, i.i_category)
)
SELECT *
FROM returns
UNION ALL
SELECT *
FROM sales
LIMIT 100
