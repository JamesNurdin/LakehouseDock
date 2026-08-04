WITH
  sales_sample AS (
    SELECT
      cs.cs_sold_date_sk AS date_key,
      cs.cs_item_sk AS item_key,
      cs.cs_quantity AS qty,
      cs.cs_sales_price AS amount,
      cs.cs_net_profit AS profit,
      hd.hd_vehicle_count AS vehicle_cnt,
      sm.sm_carrier AS carrier
    FROM catalog_sales AS cs
    TABLESAMPLE BERNOULLI (10)    
    JOIN household_demographics AS hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode AS sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_sales_price > 20
      AND hd.hd_vehicle_count >= 0
      AND sm.sm_carrier <> 'RUPEKSA'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
  ),
  returns_join AS (
    SELECT
      cr.cr_returned_date_sk AS date_key,
      cr.cr_item_sk AS item_key,
      cr.cr_return_quantity AS qty,
      cr.cr_return_amount AS amount,
      cr.cr_net_loss AS profit,
      hd.hd_vehicle_count AS vehicle_cnt,
      sm.sm_carrier AS carrier
    FROM catalog_returns AS cr
    JOIN catalog_sales AS cs
      ON cr.cr_item_sk = cs.cs_item_sk
     AND cr.cr_order_number = cs.cs_order_number
    JOIN household_demographics AS hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode AS sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 5
      AND hd.hd_vehicle_count >= 0
      AND sm.sm_carrier = 'MSC'
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
  ),
  store_join AS (
    SELECT
      sr.sr_returned_date_sk AS date_key,
      sr.sr_item_sk AS item_key,
      sr.sr_return_quantity AS qty,
      sr.sr_return_amt AS amount,
      sr.sr_net_loss AS profit,
      hd.hd_vehicle_count AS vehicle_cnt,
      CAST(NULL AS varchar) AS carrier
    FROM store_returns AS sr
    JOIN household_demographics AS hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 10
      AND hd.hd_vehicle_count >= 0
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
  ),
  union_all AS (
    SELECT date_key, item_key, qty, amount, profit, carrier, vehicle_cnt FROM sales_sample
    UNION DISTINCT
    SELECT date_key, item_key, qty, amount, profit, carrier, vehicle_cnt FROM returns_join
    UNION DISTINCT
    SELECT date_key, item_key, qty, amount, profit, carrier, vehicle_cnt FROM store_join
  ),
  ranked AS (
    SELECT
      date_key,
      item_key,
      qty,
      amount,
      profit,
      carrier,
      vehicle_cnt,
      ROW_NUMBER() OVER (PARTITION BY carrier ORDER BY amount DESC) AS rn_amount_desc,
      AVG(amount) OVER (PARTITION BY carrier ORDER BY date_key ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_amount
    FROM union_all
  )
SELECT
  carrier,
  COUNT(DISTINCT item_key) AS distinct_items,
  SUM(DISTINCT amount) AS sum_distinct_amount,
  MAX(rn_amount_desc) AS max_rank_per_carrier,
  AVG(moving_avg_amount) AS avg_moving_avg_amount
FROM ranked
WHERE rn_amount_desc <= 5                     -- keep top‑5 rows per carrier
  AND vehicle_cnt BETWEEN 0 AND 5               -- filter on household vehicle count
  AND amount > 0                                -- positive transaction amount
  AND profit < 500                              -- reasonable profit / loss bound
  AND date_key BETWEEN 2450000 AND 2450100      -- date range filter
GROUP BY carrier
ORDER BY distinct_items DESC
LIMIT 100
