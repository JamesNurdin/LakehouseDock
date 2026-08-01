/*
  Goal: Identify the top‑selling items (by revenue) in the sampled store sales data,
  combine them with items that have returns, enrich with promotion information,
  deduplicate via UNION, intersect item keys with promotion keys, and rank the results.
*/
WITH sampled_sales AS (
    SELECT ss_item_sk,
           ss_store_sk,
           ss_sold_date_sk,
           ss_ext_sales_price
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows for faster processing
),

sales_agg AS (
    SELECT i.i_item_id,
           i.i_item_desc,
           SUM(ss.ss_ext_sales_price) AS total_sales
    FROM sampled_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
    HAVING SUM(ss.ss_ext_sales_price) > 1000   -- keep only significant sales
),

returns_agg AS (
    SELECT i.i_item_id,
           SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001
    )
    GROUP BY i.i_item_id
),

full_join_sales_returns AS (
    SELECT COALESCE(s.i_item_id, r.i_item_id) AS item_id,
           s.total_sales,
           r.total_returns
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r ON s.i_item_id = r.i_item_id
),

promo_items AS (
    SELECT DISTINCT p.p_item_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),

intersect_keys AS (
    SELECT i_item_sk FROM item
    INTERSECT
    SELECT p_item_sk FROM promotion
),

union_set AS (
    SELECT item_id,
           total_sales,
           total_returns
    FROM full_join_sales_returns
    WHERE total_sales IS NOT NULL
    UNION   -- distinct union, removes duplicates across the two selects
    SELECT CAST(i.i_item_id AS VARCHAR) AS item_id,
           CAST(0 AS DOUBLE) AS total_sales,
           CAST(0 AS DOUBLE) AS total_returns
    FROM item i
    WHERE i.i_item_sk IN (SELECT i_item_sk FROM intersect_keys)
)

SELECT final.item_id,
       final.total_sales,
       final.total_returns,
       final.sales_rank
FROM (
    SELECT u.item_id,
           u.total_sales,
           u.total_returns,
           ROW_NUMBER() OVER (ORDER BY u.total_sales DESC NULLS LAST) AS sales_rank
    FROM union_set u
    WHERE u.item_id IN (
        SELECT CAST(p_item_sk AS VARCHAR)
        FROM promo_items
    )
) final
ORDER BY final.total_sales DESC NULLS LAST
LIMIT 100
