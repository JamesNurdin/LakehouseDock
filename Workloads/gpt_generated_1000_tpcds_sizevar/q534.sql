WITH
-- 1. Sample a fraction of the item dimension
item_sample AS (
    SELECT i_item_sk,
           i_item_id,
           i_category_id,
           i_wholesale_cost,
           i_formulation
    FROM   item
    TABLESAMPLE BERNOULLI (10)
),

-- 2. Aggregate web sales per item and warehouse
web_agg AS (
    SELECT ws_item_sk,
           ws_warehouse_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           SUM(ws_net_profit)      AS total_profit,
           COUNT(*)                AS sales_cnt
    FROM   web_sales
    WHERE  ws_sales_price > 25.00               -- realistic price filter
      AND  ws_quantity BETWEEN 2 AND 5          -- realistic quantity filter
    GROUP BY ws_item_sk, ws_warehouse_sk
),

-- 3. Aggregate store returns per item and reason
store_agg AS (
    SELECT sr_item_sk,
           sr_reason_sk,
           SUM(sr_return_amt) AS total_return_amt,
           COUNT(*)           AS return_cnt
    FROM   store_returns
    WHERE  sr_refunded_cash > 100.00            -- realistic cash filter
    GROUP BY sr_item_sk, sr_reason_sk
),

-- 4. Full outer join time dimension with catalog returns (keeps unmatched rows on both sides)
time_full AS (
    SELECT td.t_time_sk,
           td.t_hour,
           td.t_minute,
           td.t_meal_time,
           cr.cr_item_sk,
           cr.cr_returned_date_sk,
           cr.cr_returned_time_sk
    FROM   time_dim td
    FULL OUTER JOIN catalog_returns cr
           ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE  td.t_hour BETWEEN 8 AND 20           -- business‑hour filter
),

-- 5. Items that appear in web_sales but NOT in store_returns (set difference)
item_excluding_returns AS (
    SELECT DISTINCT ws_item_sk
    FROM   web_sales
    EXCEPT
    SELECT DISTINCT sr_item_sk
    FROM   store_returns
)

SELECT
    i.i_item_id,
    i.i_category_id,
    i.i_formulation,
    w.w_warehouse_name,
    r.r_reason_desc,
    tf.t_hour,
    tf.t_minute,
    tf.t_meal_time,
    wa.total_sales,
    wa.total_profit,
    wa.sales_cnt,
    sa.total_return_amt,
    sa.return_cnt,
    -- correlated scalar sub‑query: total catalog return amount for this item
    (SELECT SUM(cr.cr_return_amount)
     FROM   catalog_returns cr
     WHERE  cr.cr_item_sk = i.i_item_sk) AS item_total_return_amount,
    -- cost category based on an uncorrelated scalar sub‑query (average wholesale cost)
    CASE WHEN i.i_wholesale_cost > (SELECT AVG(i2.i_wholesale_cost) FROM item i2)
         THEN 'HIGH' ELSE 'NORMAL' END AS cost_category
FROM   item_sample i
LEFT   JOIN web_agg   wa ON wa.ws_item_sk = i.i_item_sk
LEFT   JOIN store_agg sa ON sa.sr_item_sk = i.i_item_sk
LEFT   JOIN reason    r  ON r.r_reason_sk = sa.sr_reason_sk
LEFT   JOIN warehouse w  ON w.w_warehouse_sk = wa.ws_warehouse_sk
LEFT   JOIN time_full tf ON tf.cr_item_sk = i.i_item_sk
WHERE  i.i_item_sk IN (SELECT ws_item_sk FROM item_excluding_returns)      -- IN sub‑query
  AND  i.i_wholesale_cost > 10.00                                         -- additional filter
  AND  tf.t_meal_time = 'LUNCH'                                           -- realistic time filter
  AND  r.r_reason_desc IS NOT NULL                                        -- ensure reason present
GROUP BY
    i.i_item_id,
    i.i_category_id,
    i.i_formulation,
    w.w_warehouse_name,
    r.r_reason_desc,
    tf.t_hour,
    tf.t_minute,
    tf.t_meal_time,
    wa.total_sales,
    wa.total_profit,
    wa.sales_cnt,
    sa.total_return_amt,
    sa.return_cnt,
    i.i_wholesale_cost,
    i.i_item_sk
ORDER BY total_sales DESC, i.i_item_id
LIMIT 100
