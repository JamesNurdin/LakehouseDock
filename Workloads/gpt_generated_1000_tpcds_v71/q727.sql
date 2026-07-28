WITH
  sr_detail AS (
    SELECT
      s.s_store_name AS store_name,
      r.r_reason_desc AS store_reason,
      i.i_current_price AS item_price,
      i.i_manufact_id AS manufact_id,
      sr.sr_net_loss,
      sr.sr_return_quantity
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    -- duplicate joins for the same keys using different aliases
    JOIN item i_a ON sr.sr_item_sk = i_a.i_item_sk
    JOIN reason r_a ON sr.sr_reason_sk = r_a.r_reason_sk
    JOIN store s_a ON sr.sr_store_sk = s_a.s_store_sk
    JOIN item i_b ON sr.sr_item_sk = i_b.i_item_sk
    JOIN reason r_b ON sr.sr_reason_sk = r_b.r_reason_sk
    JOIN store s_b ON sr.sr_store_sk = s_b.s_store_sk
  ),
  wr_detail AS (
    SELECT
      w.r_reason_desc AS web_reason,
      i2.i_current_price AS web_item_price,
      i2.i_manufact_id AS web_manufact_id,
      wr.wr_net_loss,
      wr.wr_return_quantity
    FROM web_returns wr
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    JOIN reason w ON wr.wr_reason_sk = w.r_reason_sk
    -- duplicate joins for the same keys using different aliases
    JOIN item i2_a ON wr.wr_item_sk = i2_a.i_item_sk
    JOIN reason w_a ON wr.wr_reason_sk = w_a.r_reason_sk
    JOIN item i2_b ON wr.wr_item_sk = i2_b.i_item_sk
    JOIN reason w_b ON wr.wr_reason_sk = w_b.r_reason_sk
  )
SELECT
  reason_desc,
  channel,
  COUNT(*) AS return_cnt,
  SUM(net_loss) AS total_net_loss,
  AVG(item_price) AS avg_item_price,
  COUNT(DISTINCT manufact_id) AS distinct_manufacturers
FROM (
  SELECT
    store_name,
    store_reason AS reason_desc,
    'store' AS channel,
    sr_net_loss AS net_loss,
    item_price,
    manufact_id
  FROM sr_detail
  UNION ALL
  SELECT
    NULL AS store_name,
    web_reason AS reason_desc,
    'web' AS channel,
    wr_net_loss AS net_loss,
    web_item_price AS item_price,
    web_manufact_id AS manufact_id
  FROM wr_detail
) AS combined
GROUP BY reason_desc, channel
ORDER BY total_net_loss DESC
LIMIT 100
