WITH catalog_ret AS (
  SELECT
    d.d_date AS return_date,
    CAST('catalog' AS varchar) AS return_channel,
    cr.cr_net_loss AS net_loss,
    CASE WHEN cr.cr_net_loss > 1000 THEN 'Y' ELSE 'N' END AS large_loss_flag,
    w.w_warehouse_id AS warehouse_id
  FROM tpcds.catalog_returns cr
  JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2001
),
web_ret AS (
  SELECT
    d.d_date AS return_date,
    CAST('web' AS varchar) AS return_channel,
    wr.wr_net_loss AS net_loss,
    CASE WHEN wr.wr_net_loss > 1000 THEN 'Y' ELSE 'N' END AS large_loss_flag,
    w.w_warehouse_id AS warehouse_id
  FROM tpcds.web_returns wr
  JOIN tpcds.web_sales ws ON wr.wr_order_number = ws.ws_order_number
                           AND wr.wr_item_sk = ws.ws_item_sk
  JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2001
)
SELECT
  return_date,
  return_channel,
  net_loss,
  large_loss_flag,
  warehouse_id
FROM catalog_ret
UNION ALL
SELECT
  return_date,
  return_channel,
  net_loss,
  large_loss_flag,
  warehouse_id
FROM web_ret
ORDER BY return_date DESC, net_loss DESC
LIMIT 100
