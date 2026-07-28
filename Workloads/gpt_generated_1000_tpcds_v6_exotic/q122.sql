-- Goal: Identify items with the highest total return amount, categorize them by loss level, and compare their sales price and wholesale cost, combining high‑loss and low‑loss items using UNION ALL while applying window ranking and existence checks.
WITH item_returns AS (
   SELECT
     cr.cr_item_sk,
     SUM(cr.cr_return_amount) AS total_return_amount,
     SUM(cr.cr_return_quantity) AS total_return_qty,
     COUNT(*) AS return_cnt,
     CASE
       WHEN SUM(cr.cr_return_amount) > 5000 THEN 'HIGH_LOSS'
       ELSE 'LOW_LOSS'
     END AS loss_category
   FROM catalog_returns cr
   WHERE cr.cr_return_amount > 0
   GROUP BY cr.cr_item_sk
)

SELECT
  ir.cr_item_sk,
  ir.total_return_amount,
  ir.total_return_qty,
  ir.return_cnt,
  ir.loss_category,
  cs.cs_list_price,
  cs.cs_wholesale_cost,
  ROW_NUMBER() OVER (PARTITION BY ir.loss_category ORDER BY ir.total_return_amount DESC) AS rank_by_loss
FROM item_returns ir
JOIN catalog_sales cs
  ON ir.cr_item_sk = cs.cs_item_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = ir.cr_item_sk
      AND cr2.cr_returning_hdemo_sk = 5571
)
  AND cs.cs_list_price BETWEEN 100 AND 300

UNION ALL

SELECT
  ir2.cr_item_sk,
  ir2.total_return_amount,
  ir2.total_return_qty,
  ir2.return_cnt,
  ir2.loss_category,
  cs2.cs_list_price,
  cs2.cs_wholesale_cost,
  ROW_NUMBER() OVER (PARTITION BY ir2.loss_category ORDER BY ir2.total_return_amount ASC) AS rank_by_loss
FROM item_returns ir2
JOIN catalog_sales cs2
  ON ir2.cr_item_sk = cs2.cs_item_sk
WHERE ir2.loss_category = 'LOW_LOSS'
  AND cs2.cs_wholesale_cost < 50
  AND cs2.cs_ext_ship_cost > 0

ORDER BY total_return_amount DESC
LIMIT 100
