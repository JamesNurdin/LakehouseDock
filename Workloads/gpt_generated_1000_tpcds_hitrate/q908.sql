WITH store_ret AS (
  SELECT
    d.d_date AS return_date,
    i.i_item_id,
    i.i_product_name,
    sr.sr_return_amt AS sr_return_amt,
    sr.sr_net_loss AS sr_net_loss,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    lt.item_return_cnt
  FROM store_returns sr
  FULL OUTER JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  LEFT JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN LATERAL (
    SELECT count(*) AS item_return_cnt
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = sr.sr_item_sk
  ) lt ON true
  WHERE d.d_year = 2000
    AND EXISTS (
      SELECT 1 FROM inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_quantity_on_hand > 0
    )
),
web_ret AS (
  SELECT
    d.d_date AS return_date,
    i.i_item_id,
    i.i_product_name,
    wr.wr_return_amt AS wr_return_amt,
    wr.wr_net_loss AS wr_net_loss,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    lt.item_return_cnt
  FROM web_returns wr
  FULL OUTER JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  LEFT JOIN household_demographics hd
    ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN LATERAL (
    SELECT count(*) AS item_return_cnt
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = wr.wr_item_sk
  ) lt ON true
  WHERE d.d_year = 2000
    AND EXISTS (
      SELECT 1 FROM inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_quantity_on_hand > 0
    )
)
SELECT
  return_date,
  i_item_id,
  i_product_name,
  return_amt,
  net_loss,
  ib_lower_bound,
  ib_upper_bound,
  item_return_cnt,
  source
FROM (
  SELECT
    return_date,
    i_item_id,
    i_product_name,
    sr_return_amt AS return_amt,
    sr_net_loss AS net_loss,
    ib_lower_bound,
    ib_upper_bound,
    item_return_cnt,
    'store' AS source
  FROM store_ret
  UNION ALL
  SELECT
    return_date,
    i_item_id,
    i_product_name,
    wr_return_amt AS return_amt,
    wr_net_loss AS net_loss,
    ib_lower_bound,
    ib_upper_bound,
    item_return_cnt,
    'web' AS source
  FROM web_ret
) combined
ORDER BY return_amt DESC
OFFSET 0
LIMIT 100
