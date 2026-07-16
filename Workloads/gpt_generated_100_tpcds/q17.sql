WITH
  sales_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category,
      sm.sm_type,
      SUM(cs.cs_net_profit) AS total_sales_profit,
      SUM(cs.cs_ext_sales_price) AS total_sales_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type
  ),
  returns_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category,
      sm.sm_type,
      SUM(cr.cr_net_loss) AS total_return_loss,
      SUM(cr.cr_refunded_cash) AS total_refunded_cash
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type
  )
SELECT
  s.d_year,
  s.d_month_seq,
  s.i_category,
  s.sm_type,
  s.total_sales_profit,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
  s.total_sales_amount,
  COALESCE(r.total_refunded_cash, 0) AS total_refunded_cash
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
  AND s.d_month_seq = r.d_month_seq
  AND s.i_category = r.i_category
  AND s.sm_type = r.sm_type
ORDER BY net_profit_after_returns DESC
LIMIT 20
