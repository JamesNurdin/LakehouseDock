WITH sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_ship_mode_sk,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt
  FROM catalog_sales cs
  WHERE cs.cs_net_paid_inc_tax > 0
),
returns AS (
  SELECT
    cr.cr_order_number,
    cr.cr_item_sk,
    cr.cr_ship_mode_sk,
    cr.cr_returned_date_sk,
    cr.cr_return_quantity,
    cr.cr_return_amt_inc_tax,
    cr.cr_net_loss
  FROM catalog_returns cr
  WHERE cr.cr_return_amt_inc_tax > 0
),
joined AS (
  SELECT
    s.cs_order_number,
    s.cs_item_sk,
    s.cs_ship_mode_sk,
    s.cs_sold_date_sk,
    s.cs_quantity,
    s.cs_net_profit,
    s.cs_ext_discount_amt,
    r.cr_return_quantity,
    r.cr_return_amt_inc_tax,
    r.cr_net_loss
  FROM sales s
  LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
    AND s.cs_item_sk = r.cr_item_sk
    AND s.cs_ship_mode_sk = r.cr_ship_mode_sk
),
grouped AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    sm.sm_type AS ship_mode_type,
    SUM(j.cs_net_profit) AS total_sales_net_profit,
    SUM(COALESCE(j.cr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(COALESCE(j.cr_net_loss, 0)) AS total_return_net_loss,
    SUM(j.cs_net_profit) - SUM(COALESCE(j.cr_return_amt_inc_tax, 0)) AS net_profit_after_returns,
    AVG(j.cs_ext_discount_amt) AS avg_discount_per_sale,
    COUNT(DISTINCT j.cs_order_number) AS distinct_orders,
    SUM(j.cs_quantity) AS total_quantity_sold
  FROM joined j
  JOIN date_dim d
    ON j.cs_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm
    ON j.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND sm.sm_type IN ('Standard', 'Express')
  GROUP BY d.d_year, d.d_month_seq, sm.sm_type
  HAVING SUM(j.cs_quantity) > 100
)
SELECT
  g.d_year,
  g.d_month_seq,
  g.ship_mode_type,
  g.total_sales_net_profit,
  g.total_return_amount,
  g.total_return_net_loss,
  g.net_profit_after_returns,
  g.avg_discount_per_sale,
  g.distinct_orders,
  RANK() OVER (PARTITION BY g.d_year ORDER BY g.net_profit_after_returns DESC) AS profit_rank
FROM grouped g
ORDER BY g.d_year, g.d_month_seq, g.net_profit_after_returns DESC
LIMIT 100
