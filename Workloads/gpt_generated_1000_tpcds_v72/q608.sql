/*
  Goal: Analyze profitability by U.S. state and item category, classifying profit levels, while excluding items that ever sold with a zero coupon amount in the same store. The query joins item, store, and store_sales, applies numerous realistic filters, uses a CASE expression, rolls up the grouping hierarchy, orders the result and limits it to 100 rows.
*/
WITH filtered_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        ss.ss_coupon_amt
    FROM store_sales ss
    WHERE ss.ss_coupon_amt > 5
      AND ss.ss_ext_sales_price > 100
      AND ss.ss_quantity >= 1
      AND ss.ss_ext_discount_amt < 500
      AND ss.ss_net_profit <> 0
      AND ss.ss_ext_sales_price < 20000
)
SELECT
    s.s_state,
    i.i_category,
    CASE
        WHEN SUM(fs.ss_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(fs.ss_net_profit) < 0 THEN 'LOSS'
        ELSE 'MEDIUM'
    END AS profit_level,
    COUNT(DISTINCT fs.ss_item_sk) AS distinct_items_sold,
    SUM(fs.ss_quantity) AS total_quantity,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    AVG(fs.ss_ext_sales_price) AS avg_sales_price,
    MIN(fs.ss_ext_sales_price) AS min_sales_price,
    MAX(fs.ss_ext_sales_price) AS max_sales_price
FROM filtered_sales fs
JOIN item i
    ON fs.ss_item_sk = i.i_item_sk
JOIN store s
    ON fs.ss_store_sk = s.s_store_sk
WHERE i.i_current_price BETWEEN 5 AND 500
  AND i.i_brand = 'BrandX'
  AND s.s_state = 'CA'
  AND s.s_floor_space > 8000000
  AND s.s_market_id IN (1, 2, 3)
  AND i.i_rec_end_date > DATE '2000-01-01'
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
          AND ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_coupon_amt = 0
      )
GROUP BY ROLLUP (s.s_state, i.i_category)
ORDER BY s.s_state ASC, i.i_category ASC, profit_level
LIMIT 100
