WITH
  store_data AS (
    SELECT
      i.i_item_id,
      i.i_category,
      sr.sr_return_amt_inc_tax AS return_amount,
      CASE WHEN sr.sr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
      cd.cd_purchase_estimate
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 5000
      AND i.i_category_id IN (4,5,6)
  ),
  web_data AS (
    SELECT
      i.i_item_id,
      i.i_category,
      wr.wr_return_amt_inc_tax AS return_amount,
      CASE WHEN wr.wr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
      cd.cd_purchase_estimate
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 5000
      AND i.i_category_id IN (4,5,6)
  ),
  overall_avg AS (
    SELECT avg(return_amount) AS overall_avg_return
    FROM (
      SELECT sr_return_amt_inc_tax AS return_amount FROM store_returns
      UNION ALL
      SELECT wr_return_amt_inc_tax FROM web_returns
    )
  )
SELECT DISTINCT
  src.i_item_id AS item_id,
  src.i_category AS category,
  src.loss_category,
  src.return_amount,
  CASE
    WHEN src.return_amount > (SELECT overall_avg_return FROM overall_avg) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS compare_to_avg
FROM (
  SELECT i_item_id, i_category, return_amount, loss_category, cd_purchase_estimate FROM store_data
  UNION ALL
  SELECT i_item_id, i_category, return_amount, loss_category, cd_purchase_estimate FROM web_data
) src
ORDER BY src.return_amount DESC
LIMIT 100
