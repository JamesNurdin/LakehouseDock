WITH
  sampled_items AS (
    SELECT i_item_sk, i_item_id, i_units, i_manufact
    FROM tpcds.item
    TABLESAMPLE BERNOULLI (10)
  ),
  store_ret AS (
    SELECT
      'store' AS source,
      s.s_store_id AS store_id,
      CAST(NULL AS integer) AS web_site_id,
      i.i_item_id AS item_id,
      SUM(sr.sr_return_amt) AS total_return_amount,
      (
        SELECT AVG(cr.cr_return_amount)
        FROM tpcds.catalog_returns cr
        WHERE cr.cr_item_sk = i.i_item_sk
      ) AS avg_catalog_return_amount,
      CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag
    FROM tpcds.store_returns sr
    JOIN sampled_items i ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE i.i_units = 'Bundle'
      AND t.t_shift = 'first'
    GROUP BY s.s_store_id, i.i_item_id, i.i_item_sk
  ),
  web_ret AS (
    SELECT
      'web' AS source,
      CAST(NULL AS varchar) AS store_id,
      ws.ws_web_site_sk AS web_site_id,
      i.i_item_id AS item_id,
      SUM(wr.wr_return_amt) AS total_return_amount,
      (
        SELECT AVG(cr.cr_return_amount)
        FROM tpcds.catalog_returns cr
        WHERE cr.cr_item_sk = i.i_item_sk
      ) AS avg_catalog_return_amount,
      CASE WHEN SUM(wr.wr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag
    FROM tpcds.web_returns wr
    JOIN sampled_items i ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.web_sales ws ON wr.wr_order_number = ws.ws_order_number
      AND wr.wr_item_sk = ws.ws_item_sk
    JOIN tpcds.time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE i.i_manufact LIKE '%stable%'
      AND t.t_shift = 'second'
    GROUP BY ws.ws_web_site_sk, i.i_item_id, i.i_item_sk
  )
SELECT source,
       store_id,
       web_site_id,
       item_id,
       total_return_amount,
       avg_catalog_return_amount,
       loss_flag
FROM (
  SELECT * FROM store_ret
  UNION
  SELECT * FROM web_ret
) combined
ORDER BY source ASC, total_return_amount DESC
