WITH
  max_net_paid AS (
    SELECT max(cs_net_paid_inc_tax) AS max_paid
    FROM catalog_sales
  ),
  catalog_sales_sample AS (
    SELECT
      cs.cs_item_sk,
      i.i_item_id,
      cs.cs_quantity,
      cs.cs_net_paid_inc_tax,
      cs.cs_net_profit
    FROM catalog_sales cs
      TABLESAMPLE BERNOULLI (10)
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_net_paid_inc_tax > (SELECT max_paid FROM max_net_paid)
  )
SELECT
  cs_sample.i_item_id      AS item_id,
  cs_sample.cs_quantity    AS qty,
  cs_sample.cs_net_paid_inc_tax AS amount,
  CASE WHEN cs_sample.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
  (SELECT sum(sr_return_amt)
   FROM store_returns sr
   WHERE sr.sr_item_sk = cs_sample.cs_item_sk) AS related_amount
FROM catalog_sales_sample cs_sample
WHERE cs_sample.cs_item_sk IS NOT NULL
  AND cs_sample.cs_quantity > 0
  AND cs_sample.cs_net_paid_inc_tax > (SELECT max_paid FROM max_net_paid)

UNION ALL

SELECT
  i.i_item_id           AS item_id,
  sr.sr_return_quantity AS qty,
  sr.sr_return_amt       AS amount,
  CASE WHEN sr.sr_net_loss > 0 THEN 'LOSS' ELSE 'GAIN' END AS profit_flag,
  (SELECT sum(cs.cs_net_paid_inc_tax)
   FROM catalog_sales cs
   WHERE cs.cs_item_sk = sr.sr_item_sk) AS related_amount
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE sr.sr_return_amt > (SELECT max_paid FROM max_net_paid)

LIMIT 100
