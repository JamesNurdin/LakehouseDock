WITH sales_agg AS (
  SELECT
    d_sales.d_year,
    d_sales.d_moy,
    i.i_category,
    p.p_channel_email,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost,
    SUM(cs.cs_ext_sales_price) AS total_sales_price
  FROM catalog_sales cs
  JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
  JOIN time_dim t_sales
    ON cs.cs_sold_time_sk = t_sales.t_time_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  WHERE d_sales.d_year = 2001
    AND d_sales.d_weekend = 'Y'
    AND p.p_channel_email = 'Y'
    AND cs.cs_ext_discount_amt > 500
    AND t_sales.t_hour BETWEEN 9 AND 17
    AND d_sales.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  GROUP BY d_sales.d_year, d_sales.d_moy, i.i_category, p.p_channel_email
),

returns_agg AS (
  SELECT
    d_returns.d_year,
    d_returns.d_moy,
    i.i_category,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_qty
  FROM web_returns wr
  JOIN date_dim d_returns
    ON wr.wr_returned_date_sk = d_returns.d_date_sk
  JOIN time_dim t_returns
    ON wr.wr_returned_time_sk = t_returns.t_time_sk
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  WHERE d_returns.d_year = 2001
    AND d_returns.d_weekend = 'Y'
    AND t_returns.t_hour BETWEEN 9 AND 17
  GROUP BY d_returns.d_year, d_returns.d_moy, i.i_category
)

SELECT
  s.d_year,
  s.d_moy,
  s.i_category,
  s.p_channel_email,
  s.total_net_profit,
  s.total_discount,
  s.total_quantity,
  s.orders,
  s.avg_wholesale_cost,
  s.total_sales_price,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.total_return_qty, 0) AS total_return_qty,
  s.total_net_profit - COALESCE(r.total_return_amount, 0) AS net_profit_after_returns,
  CASE WHEN s.total_quantity > 0 THEN (s.total_net_profit - COALESCE(r.total_return_amount, 0)) / s.total_quantity ELSE 0 END AS profit_per_unit
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
  AND s.d_moy = r.d_moy
  AND s.i_category = r.i_category
ORDER BY s.d_year, s.d_moy, s.i_category, s.total_net_profit DESC
LIMIT 100
