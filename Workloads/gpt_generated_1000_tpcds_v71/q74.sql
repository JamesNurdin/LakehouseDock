WITH base AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_hdemo_sk,
    ss.ss_net_paid,
    d.d_year,
    t.t_hour,
    i.i_item_id,
    i.i_category,
    i.i_category_id,
    i.i_manufact_id,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cp.cp_catalog_page_sk,
    cp.cp_catalog_number,
    cr.cr_return_amount,
    cr.cr_return_amt_inc_tax,
    wr.wr_return_amt_inc_tax
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
  JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   AND cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_item_sk = i.i_item_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
  WHERE d.d_year = 2001
    AND i.i_category_id = 4
    AND ib.ib_upper_bound <= 100000
    AND t.t_hour BETWEEN 9 AND 17
)
SELECT
  d_year,
  i_item_id,
  i_category,
  hd_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  cp_catalog_number,
  SUM(ss_net_paid) AS total_sales,
  SUM(cr_return_amount) AS total_catalog_returns,
  SUM(wr_return_amt_inc_tax) AS total_web_returns,
  (
    SELECT AVG(wr2.wr_return_amt_inc_tax)
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = base.ss_item_sk
  ) AS avg_item_web_return,
  CASE
    WHEN SUM(wr_return_amt_inc_tax) > 1.5 * (
          SELECT AVG(wr3.wr_return_amt_inc_tax)
          FROM web_returns wr3
          WHERE wr3.wr_item_sk = base.ss_item_sk
        ) THEN 'High'
    ELSE 'Normal'
  END AS web_return_flag,
  ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM base
GROUP BY
  d_year,
  i_item_id,
  i_category,
  hd_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  cp_catalog_number,
  ss_store_sk,
  ss_item_sk
HAVING SUM(ss_net_paid) > 10000
ORDER BY total_sales DESC, sales_rank
LIMIT 100
