WITH
  cr AS (
    SELECT
      cr_returned_date_sk,
      cr_item_sk,
      cr_refunded_customer_sk,
      cr_returning_customer_sk,
      cr_catalog_page_sk,
      cr_return_quantity,
      cr_return_amount,
      cr_net_loss
    FROM catalog_returns
  ),
  wr AS (
    SELECT
      wr_returned_date_sk,
      wr_item_sk,
      wr_refunded_customer_sk,
      wr_returning_customer_sk,
      wr_return_quantity,
      wr_return_amt,
      wr_net_loss
    FROM web_returns
  )
SELECT
  d_year,
  d_month_seq,
  total_catalog_net_loss,
  total_web_net_loss,
  distinct_catalog_items,
  distinct_web_items,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_net_loss DESC) AS catalog_loss_rank
FROM (
  SELECT
    d1.d_year,
    d1.d_month_seq,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_catalog_items,
    COUNT(DISTINCT wr.wr_item_sk) AS distinct_web_items
  FROM cr
  JOIN date_dim d1 ON cr.cr_returned_date_sk = d1.d_date_sk
  JOIN item i1 ON cr.cr_item_sk = i1.i_item_sk
  JOIN customer cust_ref ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
  JOIN customer cust_ret ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
  JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = d1.d_date_sk
  JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
  JOIN customer cust_wr_ref ON wr.wr_refunded_customer_sk = cust_wr_ref.c_customer_sk
  JOIN customer cust_wr_ret ON wr.wr_returning_customer_sk = cust_wr_ret.c_customer_sk
  WHERE d1.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  GROUP BY d1.d_year, d1.d_month_seq
) agg
ORDER BY d_year, d_month_seq
