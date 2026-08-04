WITH full_join AS (
    SELECT
        COALESCE(i.i_item_sk, ss.ss_item_sk) AS item_key,
        i.i_brand,
        i.i_category,
        i.i_size,
        i.i_formulation,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_item_sk AS ss_item_sk
    FROM tpcds.item i
    FULL OUTER JOIN tpcds.store_sales ss
        ON i.i_item_sk = ss.ss_item_sk
),
filtered AS (
    SELECT *
    FROM full_join
    WHERE
        i_size IN ('medium', 'small', 'extra large')
        AND i_formulation LIKE '%steel%'
        AND ss_ext_discount_amt > 100
        AND ss_ext_discount_amt < 5000
        AND ss_quantity BETWEEN 1 AND 10
        AND ss_net_profit > 0
        AND i_category IS NOT NULL
        AND i_brand IS NOT NULL
        AND ss_ext_sales_price > 0
),
distinct_agg AS (
    SELECT
        COUNT(DISTINCT i_brand) AS distinct_brand_cnt,
        SUM(DISTINCT ss_ext_discount_amt) AS sum_distinct_discount
    FROM filtered
),
windowed AS (
    SELECT
        item_key,
        i_brand,
        i_category,
        i_size,
        ss_ext_sales_price,
        ss_ext_discount_amt,
        ss_quantity,
        ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY ss_ext_sales_price DESC) AS rn_category,
        RANK() OVER (ORDER BY ss_net_profit DESC) AS profit_rank
    FROM filtered
),
anti_items AS (
    SELECT i.i_item_sk
    FROM tpcds.item i
    WHERE i.i_item_sk NOT IN (
        SELECT ss.ss_item_sk
        FROM tpcds.store_sales ss
        WHERE ss.ss_net_profit < 0
    )
),
-- sets for EXCEPT demonstration
sales_keys AS (
    SELECT ss.ss_item_sk AS key_sk
    FROM tpcds.store_sales ss
),
item_keys AS (
    SELECT i.i_item_sk AS key_sk
    FROM tpcds.item i
),
sales_not_in_item AS (
    SELECT key_sk FROM sales_keys
    EXCEPT
    SELECT key_sk FROM item_keys
),
final AS (
    SELECT
        w.item_key,
        w.i_brand,
        w.i_category,
        w.i_size,
        w.ss_ext_sales_price,
        w.ss_ext_discount_amt,
        w.rn_category,
        w.profit_rank,
        da.distinct_brand_cnt,
        da.sum_distinct_discount
    FROM windowed w
    CROSS JOIN distinct_agg da
    WHERE w.rn_category <= 5
      AND w.item_key IN (SELECT key_sk FROM sales_not_in_item) -- uses EXCEPT result
      AND w.item_key IN (SELECT i_item_sk FROM anti_items)      -- anti‑semi‑join
)
SELECT *
FROM final
ORDER BY profit_rank ASC, ss_ext_sales_price DESC
LIMIT 100
