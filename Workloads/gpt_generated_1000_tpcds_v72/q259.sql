WITH
  store_aggs AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_item_desc,
      SUM(ss.ss_net_paid) AS total_store_sales
    FROM item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = i.i_item_sk
          AND cr.cr_fee > 5
      )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc
  ),
  web_aggs AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_item_desc,
      SUM(ws.ws_net_paid) AS total_web_sales
    FROM item i
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc
  )
SELECT
  item_id,
  item_desc,
  channel,
  total_sales,
  max_loss
FROM (
  SELECT
    sa.i_item_id   AS item_id,
    sa.i_item_desc AS item_desc,
    'store'        AS channel,
    sa.total_store_sales AS total_sales,
    lr.max_loss
  FROM store_aggs sa
  CROSS JOIN LATERAL (
    SELECT MAX(sr.sr_net_loss) AS max_loss
    FROM store_returns sr
    WHERE sr.sr_item_sk = sa.i_item_sk
  ) lr

  UNION ALL

  SELECT
    wa.i_item_id   AS item_id,
    wa.i_item_desc AS item_desc,
    'web'          AS channel,
    wa.total_web_sales AS total_sales,
    lr.max_loss
  FROM web_aggs wa
  CROSS JOIN LATERAL (
    SELECT MAX(sr.sr_net_loss) AS max_loss
    FROM store_returns sr
    WHERE sr.sr_item_sk = wa.i_item_sk
  ) lr
) combined
ORDER BY total_sales DESC
LIMIT 100
