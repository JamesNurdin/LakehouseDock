WITH item_metrics AS (
  SELECT
    cs.cs_item_sk,
    cs.cs_warehouse_sk,
    SUM(cs.cs_quantity) AS total_qty_sold,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_qty_returned,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    COUNT(DISTINCT cr.cr_order_number) AS total_return_orders,
    AVG(cr.cr_reversed_charge) FILTER (WHERE cr.cr_reversed_charge IS NOT NULL) AS avg_reversed_charge,
    CAST(COALESCE(SUM(cr.cr_return_quantity), 0) AS DOUBLE) / NULLIF(SUM(cs.cs_quantity), 0) AS return_qty_ratio,
    CAST(COALESCE(SUM(cr.cr_return_amount), 0) AS DOUBLE) / NULLIF(SUM(cs.cs_net_paid), 0) AS return_amount_ratio,
    (SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_profit_after_returns
  FROM catalog_sales cs
  LEFT JOIN catalog_returns cr
    ON cs.cs_item_sk = cr.cr_item_sk
    AND cs.cs_order_number = cr.cr_order_number
    AND (cr.cr_refunded_cdemo_sk IN (1740425, 1010103, 1353806) OR cr.cr_refunded_cdemo_sk IS NULL)
    AND (cr.cr_reversed_charge > 200 OR cr.cr_reversed_charge IS NULL)
  WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2451970
    AND cs.cs_warehouse_sk = 2
  GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk
  HAVING SUM(cs.cs_quantity) > 100
)
SELECT
  im.cs_item_sk AS item_sk,
  im.cs_warehouse_sk AS warehouse_sk,
  im.total_qty_sold,
  im.total_qty_returned,
  im.total_sales,
  im.total_return_amount,
  im.total_profit,
  im.total_return_loss,
  im.return_qty_ratio,
  im.return_amount_ratio,
  im.net_profit_after_returns,
  ROW_NUMBER() OVER (ORDER BY im.total_return_loss DESC) AS loss_rank
FROM item_metrics im
ORDER BY im.net_profit_after_returns DESC
LIMIT 100
