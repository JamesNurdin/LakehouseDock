WITH joined_fact AS (
  SELECT
    d_ws.d_year,
    d_ws.d_month_seq,
    ws.ws_item_sk,
    ws.ws_order_number,
    ws.ws_net_paid_inc_ship_tax AS web_sales_amt,
    ss.ss_net_paid_inc_tax AS store_sales_amt,
    inv.inv_quantity_on_hand,
    ws.ws_sold_date_sk
  FROM web_sales ws
  JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
  JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN store_sales ss ON ss.ss_sold_date_sk = d_ws.d_date_sk
  JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
  JOIN customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
  JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
  JOIN inventory inv ON inv.inv_date_sk = d_ws.d_date_sk AND inv.inv_item_sk = ws.ws_item_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
  WHERE d_ws.d_year = 2001
    AND cd_bill.cd_credit_rating = 'Good'
    AND hd_bill.hd_income_band_sk BETWEEN 5 AND 15
    AND t_ws.t_hour BETWEEN 9 AND 17
)
SELECT DISTINCT
  agg.d_year,
  agg.d_month_seq,
  agg.ws_item_sk,
  SUM(agg.web_sales_amt) AS total_web_sales,
  SUM(agg.store_sales_amt) AS total_store_sales,
  SUM(agg.inv_quantity_on_hand) AS total_inventory_qty,
  (
    SELECT AVG(inv2.inv_quantity_on_hand)
    FROM inventory inv2
    WHERE inv2.inv_item_sk = agg.ws_item_sk
  ) AS avg_inventory_per_item,
  RANK() OVER (PARTITION BY agg.d_year, agg.d_month_seq ORDER BY SUM(agg.web_sales_amt) DESC) AS web_sales_rank,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM web_returns wr2
      JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
      WHERE wr2.wr_item_sk = agg.ws_item_sk
        AND r2.r_reason_desc = 'Damaged'
    ) THEN 'HasDamagedReturns'
    ELSE 'NoDamagedReturns'
  END AS damaged_return_flag
FROM joined_fact agg
GROUP BY GROUPING SETS (
  (agg.d_year, agg.d_month_seq, agg.ws_item_sk),
  (agg.d_year, agg.d_month_seq),
  (agg.d_year),
  ()
)
ORDER BY agg.d_year, agg.d_month_seq, web_sales_rank
LIMIT 100
