WITH sales AS (
  SELECT
    i.i_category AS i_category,
    d_sales.d_year AS d_year,
    d_sales.d_month_seq AS d_month_seq,
    sum(ss.ss_ext_sales_price) AS total_sales,
    sum(ss.ss_net_profit) AS total_profit,
    count(*) AS sales_transactions
  FROM store_sales ss
  JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  WHERE d_sales.d_year = 2000
  GROUP BY i.i_category, d_sales.d_year, d_sales.d_month_seq
),
store_returns_agg AS (
  SELECT
    i.i_category AS i_category,
    d_returns.d_year AS d_year,
    d_returns.d_month_seq AS d_month_seq,
    sum(sr.sr_return_amt_inc_tax) AS total_return_amount,
    sum(sr.sr_net_loss) AS total_return_loss,
    count(*) AS return_transactions
  FROM store_returns sr
  JOIN store_sales ss
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  JOIN date_dim d_returns
    ON sr.sr_returned_date_sk = d_returns.d_date_sk
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  WHERE d_returns.d_year = 2000
  GROUP BY i.i_category, d_returns.d_year, d_returns.d_month_seq
),
catalog_returns_agg AS (
  SELECT
    i.i_category AS i_category,
    d_cr.d_year AS d_year,
    d_cr.d_month_seq AS d_month_seq,
    sum(cr.cr_return_amount) AS total_catalog_return_amount,
    sum(cr.cr_net_loss) AS total_catalog_return_loss,
    count(*) AS catalog_return_transactions
  FROM catalog_returns cr
  JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE d_cr.d_year = 2000
  GROUP BY i.i_category, d_cr.d_year, d_cr.d_month_seq
),
inventory_changes AS (
  SELECT
    i.i_category AS i_category,
    d_inv.d_year AS d_year,
    d_inv.d_month_seq AS d_month_seq,
    sum(inv.inv_quantity_on_hand) AS total_quantity_on_hand
  FROM inventory inv
  JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
  JOIN item i
    ON inv.inv_item_sk = i.i_item_sk
  JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE d_inv.d_year = 2000
  GROUP BY i.i_category, d_inv.d_year, d_inv.d_month_seq
)
SELECT
  s.i_category,
  s.d_year,
  s.d_month_seq,
  s.total_sales,
  s.total_profit,
  r.total_return_amount,
  r.total_return_loss,
  cr.total_catalog_return_amount,
  cr.total_catalog_return_loss,
  inv.total_quantity_on_hand
FROM sales s
LEFT JOIN store_returns_agg r
  ON s.i_category = r.i_category
 AND s.d_year = r.d_year
 AND s.d_month_seq = r.d_month_seq
LEFT JOIN catalog_returns_agg cr
  ON s.i_category = cr.i_category
 AND s.d_year = cr.d_year
 AND s.d_month_seq = cr.d_month_seq
LEFT JOIN inventory_changes inv
  ON s.i_category = inv.i_category
 AND s.d_year = inv.d_year
 AND s.d_month_seq = inv.d_month_seq
ORDER BY s.i_category, s.d_year, s.d_month_seq
