WITH
  store_agg AS (
    SELECT
      sr.sr_item_sk AS item_sk,
      sr.sr_return_time_sk AS time_sk,
      SUM(sr.sr_net_loss) AS store_net_loss,
      SUM(sr.sr_return_quantity) AS store_return_qty,
      AVG(cd_store.cd_dep_college_count) AS avg_dep_college_store
    FROM store_returns sr
    JOIN time_dim t_store ON sr.sr_return_time_sk = t_store.t_time_sk
    JOIN item i_store ON sr.sr_item_sk = i_store.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd_store ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
    GROUP BY sr.sr_item_sk,
      sr.sr_return_time_sk
  ),
  catalog_agg AS (
    SELECT
      cr.cr_item_sk AS item_sk,
      cr.cr_returned_time_sk AS time_sk,
      SUM(cr.cr_net_loss) AS catalog_net_loss,
      SUM(cr.cr_return_quantity) AS catalog_return_qty,
      SUM(CASE WHEN cp.cp_type = 'Digital' THEN cr.cr_return_amount ELSE 0 END) AS digital_return_amount
    FROM catalog_returns cr
    JOIN time_dim t_cat ON cr.cr_returned_time_sk = t_cat.t_time_sk
    JOIN item i_cat ON cr.cr_item_sk = i_cat.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer_demographics cd_return ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
    GROUP BY cr.cr_item_sk,
      cr.cr_returned_time_sk
  ),
  web_agg AS (
    SELECT
      wr.wr_item_sk AS item_sk,
      wr.wr_returned_time_sk AS time_sk,
      SUM(wr.wr_net_loss) AS web_net_loss,
      SUM(wr.wr_return_quantity) AS web_return_qty,
      MAX(wp.wp_char_count) AS max_page_chars
    FROM web_returns wr
    JOIN time_dim t_web ON wr.wr_returned_time_sk = t_web.t_time_sk
    JOIN item i_web ON wr.wr_item_sk = i_web.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd_web_refund ON wr.wr_refunded_cdemo_sk = cd_web_refund.cd_demo_sk
    JOIN customer_demographics cd_web_return ON wr.wr_returning_cdemo_sk = cd_web_return.cd_demo_sk
    GROUP BY wr.wr_item_sk,
      wr.wr_returned_time_sk
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  d.t_hour,
  COALESCE(sa.store_net_loss, 0) + COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
  COALESCE(sa.store_return_qty, 0) + COALESCE(ca.catalog_return_qty, 0) + COALESCE(wa.web_return_qty, 0) AS total_return_qty,
  CASE
    WHEN COALESCE(sa.store_net_loss, 0) > 0 THEN 'Store'
    WHEN COALESCE(ca.catalog_net_loss, 0) > 0 THEN 'Catalog'
    ELSE 'Web'
  END AS primary_channel,
  SUM(COALESCE(sa.store_net_loss, 0) + COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0))
    OVER (PARTITION BY i.i_category ORDER BY d.t_hour ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS moving_loss_3hr
FROM item i
LEFT JOIN store_agg sa ON i.i_item_sk = sa.item_sk
LEFT JOIN catalog_agg ca ON i.i_item_sk = ca.item_sk
LEFT JOIN web_agg wa ON i.i_item_sk = wa.item_sk
LEFT JOIN time_dim d ON d.t_time_sk = COALESCE(sa.time_sk, ca.time_sk, wa.time_sk)
WHERE i.i_current_price > 20
ORDER BY total_net_loss DESC
LIMIT 100
