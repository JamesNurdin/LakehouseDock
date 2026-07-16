WITH catalog AS (
  SELECT
    cr.cr_returned_date_sk AS date_sk,
    cr.cr_item_sk AS item_sk,
    cr.cr_refunded_hdemo_sk AS hd_demo_sk,
    cr.cr_net_loss AS net_loss,
    cr.cr_return_quantity AS return_qty,
    cr.cr_return_amount AS return_amt,
    cr.cr_return_amt_inc_tax AS return_amt_inc_tax,
    cr.cr_return_tax AS return_tax,
    cr.cr_fee AS fee,
    cr.cr_store_credit AS store_credit,
    cr.cr_refunded_cash AS refunded_cash
  FROM catalog_returns cr
  WHERE cr.cr_returned_date_sk IS NOT NULL
),
web AS (
  SELECT
    wr.wr_returned_date_sk AS date_sk,
    wr.wr_item_sk AS item_sk,
    wr.wr_refunded_hdemo_sk AS hd_demo_sk,
    wr.wr_net_loss AS net_loss,
    wr.wr_return_quantity AS return_qty,
    wr.wr_return_amt AS return_amt,
    wr.wr_return_amt_inc_tax AS return_amt_inc_tax,
    wr.wr_return_tax AS return_tax,
    wr.wr_fee AS fee,
    wr.wr_account_credit AS store_credit,
    wr.wr_refunded_cash AS refunded_cash
  FROM web_returns wr
  WHERE wr.wr_returned_date_sk IS NOT NULL
),
combined AS (
  SELECT * FROM catalog
  UNION ALL
  SELECT * FROM web
)
SELECT
  d.d_year,
  d.d_quarter_seq,
  i.i_category,
  hd.hd_income_band_sk,
  SUM(c.net_loss) AS total_net_loss,
  SUM(c.return_amt_inc_tax) AS total_return_amount_inc_tax,
  SUM(c.return_qty) AS total_return_qty,
  COUNT(*) AS num_returns,
  RANK() OVER (PARTITION BY d.d_year, d.d_quarter_seq, hd.hd_income_band_sk ORDER BY SUM(c.net_loss) DESC) AS category_rank
FROM combined c
JOIN date_dim d ON c.date_sk = d.d_date_sk
JOIN item i ON c.item_sk = i.i_item_sk
JOIN household_demographics hd ON c.hd_demo_sk = hd.hd_demo_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND i.i_category IS NOT NULL
  AND hd.hd_income_band_sk IS NOT NULL
GROUP BY d.d_year, d.d_quarter_seq, i.i_category, hd.hd_income_band_sk
HAVING SUM(c.net_loss) > 0
ORDER BY d.d_year, d.d_quarter_seq, total_net_loss DESC
LIMIT 200
