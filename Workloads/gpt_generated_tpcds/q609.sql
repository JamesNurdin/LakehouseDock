WITH sales_agg AS (
  SELECT
    cc.cc_call_center_id,
    w.w_warehouse_name,
    date_dim.d_year,
    date_dim.d_month_seq,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_discount
  FROM catalog_sales cs
  JOIN date_dim ON cs.cs_sold_date_sk = date_dim.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE date_dim.d_year = 2001
  GROUP BY cc.cc_call_center_id, w.w_warehouse_name, date_dim.d_year, date_dim.d_month_seq
),
returns_agg AS (
  SELECT
    cc.cc_call_center_id,
    w.w_warehouse_name,
    date_dim.d_year,
    date_dim.d_month_seq,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_quantity) AS total_return_quantity
  FROM catalog_returns cr
  JOIN date_dim ON cr.cr_returned_date_sk = date_dim.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE date_dim.d_year = 2001
  GROUP BY cc.cc_call_center_id, w.w_warehouse_name, date_dim.d_year, date_dim.d_month_seq
)
SELECT
  s.cc_call_center_id,
  s.w_warehouse_name,
  s.d_year,
  s.d_month_seq,
  s.total_sales,
  s.total_profit,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
  s.num_orders,
  COALESCE(r.num_returns, 0) AS num_returns,
  s.total_quantity,
  COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
  s.avg_discount
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.cc_call_center_id = r.cc_call_center_id
  AND s.w_warehouse_name = r.w_warehouse_name
  AND s.d_year = r.d_year
  AND s.d_month_seq = r.d_month_seq
ORDER BY s.total_sales DESC
LIMIT 20
