WITH
  catalog_orders AS (
    SELECT DISTINCT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_warehouse_sk = 4
      AND cr.cr_refunded_hdemo_sk = 5209
  ),
  web_orders AS (
    SELECT DISTINCT wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
  ),
  diff_orders AS (
    SELECT cr_order_number
    FROM catalog_orders
    EXCEPT
    SELECT wr_order_number
    FROM web_orders
  ),
  agg AS (
    SELECT
      i.i_category,
      sm.sm_code,
      i.i_manufact,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_refunded_cash) AS total_refunded_cash,
      AVG(cr.cr_return_quantity) AS avg_return_quantity,
      COUNT(DISTINCT cr.cr_order_number) AS cnt_orders,
      MIN(cr.cr_return_amount) AS min_return_amount,
      MAX(cr.cr_return_amount) AS max_return_amount
    FROM diff_orders d
    JOIN catalog_returns cr
      ON cr.cr_order_number = d.cr_order_number
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
      sm.sm_code = 'AIR'
      AND i.i_manufact_id = 364
      AND cr.cr_return_quantity > 1
      AND cr.cr_return_amount > 10
      AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = i.i_item_sk
          AND wr.wr_return_quantity > 0
      )
    GROUP BY
      i.i_category,
      sm.sm_code,
      i.i_manufact
    HAVING SUM(cr.cr_return_amount) > 1000
  )
SELECT
  i_category,
  sm_code,
  i_manufact,
  total_return_amount,
  total_refunded_cash,
  avg_return_quantity,
  cnt_orders,
  min_return_amount,
  max_return_amount,
  RANK() OVER (ORDER BY total_return_amount DESC) AS return_rank
FROM agg
ORDER BY return_rank
LIMIT 100
