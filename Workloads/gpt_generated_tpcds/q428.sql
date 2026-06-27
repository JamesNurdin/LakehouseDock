WITH sales AS (
  SELECT
    d.d_year,
    d.d_moy AS month,
    i.i_category,
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
returns AS (
  SELECT
    d.d_year,
    d.d_moy AS month,
    i.i_category,
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
)
SELECT
  s.d_year,
  s.month,
  s.i_category,
  sum(s.cs_ext_sales_price) AS total_sales,
  sum(s.cs_net_profit) AS total_profit,
  count(distinct s.cs_order_number) AS total_orders,
  sum(r.cr_return_amount) AS total_return_amount,
  sum(r.cr_net_loss) AS total_return_loss,
  count(distinct r.cr_order_number) AS total_returns,
  (count(distinct r.cr_order_number) * 100.0 / nullif(count(distinct s.cs_order_number), 0)) AS return_rate_pct
FROM sales s
LEFT JOIN returns r
  ON s.cs_order_number = r.cr_order_number
  AND s.d_year = r.d_year
  AND s.month = r.month
  AND s.i_category = r.i_category
WHERE s.d_year = 2001
GROUP BY s.d_year, s.month, s.i_category
ORDER BY s.d_year, s.month, total_sales DESC
