WITH sales AS (
  SELECT
    cs.cs_call_center_sk,
    cs.cs_item_sk,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
    SUM(cs.cs_quantity) AS total_quantity
  FROM catalog_sales cs
  WHERE cs.cs_sold_date_sk BETWEEN 19980101 AND 19981231
  GROUP BY cs.cs_call_center_sk, cs.cs_item_sk
),
returns AS (
  SELECT
    wr.wr_item_sk,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(wr.wr_return_quantity) AS total_return_qty
  FROM web_returns wr
  WHERE wr.wr_returned_date_sk BETWEEN 19980101 AND 19981231
  GROUP BY wr.wr_item_sk
)
SELECT
  cc.cc_state,
  i.i_category,
  SUM(s.total_sales) AS gross_sales,
  SUM(COALESCE(r.total_returns, 0)) AS total_returns,
  SUM(s.total_sales) - SUM(COALESCE(r.total_returns, 0)) AS net_sales,
  RANK() OVER (PARTITION BY cc.cc_state ORDER BY SUM(s.total_sales) - SUM(COALESCE(r.total_returns, 0)) DESC) AS category_rank
FROM sales s
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
LEFT JOIN returns r ON s.cs_item_sk = r.wr_item_sk
WHERE cc.cc_employees > 2000000
  AND i.i_color = 'Red'
GROUP BY cc.cc_state, i.i_category
ORDER BY net_sales DESC
LIMIT 50
