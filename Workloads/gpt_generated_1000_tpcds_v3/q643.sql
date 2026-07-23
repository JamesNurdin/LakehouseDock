WITH
  sales AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      cc.cc_name,
      cc.cc_state,
      SUM(ss.ss_net_paid) AS total_sales,
      SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND cd.cd_gender = 'M'
    GROUP BY d.d_year, d.d_month_seq, cc.cc_name, cc.cc_state
  ),
  returns AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      cc.cc_name,
      cc.cc_state,
      SUM(wr.wr_net_loss) AS total_returns,
      SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_id = 'AAAAAAAABBAAAAAA'
      AND cc.cc_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq, cc.cc_name, cc.cc_state
  ),
  inventory_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      w.w_warehouse_name,
      w.w_state AS warehouse_state,
      AVG(i.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq, w.w_warehouse_name, w.w_state
  )
SELECT
  s.cc_name,
  s.cc_state,
  i.w_warehouse_name,
  i.warehouse_state,
  s.d_year,
  s.d_month_seq,
  s.total_sales,
  r.total_returns,
  (s.total_sales - COALESCE(r.total_returns, 0)) AS net_amount,
  i.avg_inventory_qty,
  ROW_NUMBER() OVER (PARTITION BY s.cc_name ORDER BY (s.total_sales - COALESCE(r.total_returns, 0)) DESC) AS profit_rank
FROM sales s
LEFT JOIN returns r
  ON r.d_year = s.d_year
  AND r.d_month_seq = s.d_month_seq
  AND r.cc_name = s.cc_name
  AND r.cc_state = s.cc_state
LEFT JOIN inventory_agg i
  ON i.d_year = s.d_year
  AND i.d_month_seq = s.d_month_seq
ORDER BY net_amount DESC
LIMIT 100
