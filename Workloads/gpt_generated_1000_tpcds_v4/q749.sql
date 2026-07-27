WITH item_returns AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_brand,
    i.i_brand_id,
    i.i_category,
    i.i_color,
    i.i_formulation,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM
    tpcds.store_returns sr
    JOIN tpcds.item i
      ON sr.sr_item_sk = i.i_item_sk
  WHERE
    sr.sr_return_amt > 100
    AND sr.sr_return_quantity >= 2
    AND sr.sr_return_tax BETWEEN 5 AND 50
    AND i.i_manufact_id IN (212, 625)
    AND i.i_color IN ('red', 'pink')
    AND i.i_formulation LIKE '%blue%'
  GROUP BY
    i.i_item_sk,
    i.i_item_id,
    i.i_brand,
    i.i_brand_id,
    i.i_category,
    i.i_color,
    i.i_formulation
  HAVING
    SUM(sr.sr_return_quantity) > 10
)
SELECT
  ir.i_item_id,
  ir.i_brand,
  ir.i_category,
  ir.i_color,
  ir.i_formulation,
  ir.total_return_qty,
  ir.total_return_amt,
  ir.total_net_loss,
  (SELECT avg(sr2.sr_net_loss)
   FROM tpcds.store_returns sr2
   JOIN tpcds.item i2 ON sr2.sr_item_sk = i2.i_item_sk
   WHERE i2.i_brand = ir.i_brand) AS avg_brand_net_loss,
  ir.total_net_loss - (SELECT avg(sr2.sr_net_loss)
                       FROM tpcds.store_returns sr2
                       JOIN tpcds.item i2 ON sr2.sr_item_sk = i2.i_item_sk
                       WHERE i2.i_brand = ir.i_brand) AS net_loss_vs_avg,
  ROW_NUMBER() OVER (PARTITION BY ir.i_brand ORDER BY ir.total_net_loss DESC) AS brand_item_rank
FROM
  item_returns ir
WHERE
  EXISTS (
    SELECT 1
    FROM tpcds.store_returns sr3
    WHERE sr3.sr_item_sk = ir.i_item_sk
      AND sr3.sr_reversed_charge > 50
  )
ORDER BY
  ir.total_net_loss DESC,
  brand_item_rank
LIMIT 100
