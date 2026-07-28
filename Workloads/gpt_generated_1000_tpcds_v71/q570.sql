WITH store_agg AS (
  SELECT
    sr.sr_item_sk,
    d_s.d_year,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(sr.sr_return_quantity) AS store_return_qty
  FROM store_returns sr
  JOIN date_dim d_s ON sr.sr_returned_date_sk = d_s.d_date_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d_s.d_year = 2000
    AND d_s.d_current_month = 'Y'
    AND r.r_reason_desc IN ('Damaged', 'Defective')
    AND sr.sr_return_amt > 0
    AND sr.sr_return_quantity > 1
  GROUP BY sr.sr_item_sk, d_s.d_year
),
web_agg AS (
  SELECT
    wr.wr_item_sk,
    d_w.d_year,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(wr.wr_return_quantity) AS web_return_qty
  FROM web_returns wr
  JOIN date_dim d_w ON wr.wr_returned_date_sk = d_w.d_date_sk
  JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
  WHERE d_w.d_year = 2000
    AND d_w.d_current_month = 'Y'
    AND r2.r_reason_desc IN ('Damaged', 'Defective')
    AND wr.wr_return_amt > 0
    AND wr.wr_return_quantity > 1
  GROUP BY wr.wr_item_sk, d_w.d_year
),
combined AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
    COALESCE(sa.store_return_qty, 0) + COALESCE(wa.web_return_qty, 0) AS total_return_qty,
    d.d_year,
    cc.cc_name,
    cc.cc_state
  FROM item i
  LEFT JOIN store_agg sa ON i.i_item_sk = sa.sr_item_sk
  LEFT JOIN web_agg wa ON i.i_item_sk = wa.wr_item_sk
  LEFT JOIN (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2000 AND d_current_month = 'Y'
    ORDER BY d_date_sk DESC
    LIMIT 1
  ) d ON 1 = 1
  LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
  WHERE i.i_current_price > 20.00
    AND cc.cc_state = 'CA'
    AND EXISTS (
      SELECT 1
      FROM web_returns wr2
      JOIN reason r3 ON wr2.wr_reason_sk = r3.r_reason_sk
      WHERE wr2.wr_item_sk = i.i_item_sk
        AND r3.r_reason_desc = 'Damaged'
    )
)
SELECT
  i_item_id,
  i_product_name,
  i_current_price,
  total_net_loss,
  total_return_qty,
  d_year,
  cc_name,
  cc_state,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM combined
WHERE total_net_loss > 0
ORDER BY loss_rank
LIMIT 100
