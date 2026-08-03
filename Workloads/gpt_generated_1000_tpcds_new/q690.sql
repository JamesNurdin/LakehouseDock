WITH sampled_returns AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    WHERE sr_return_tax > 5.00   -- predicate 1
),
agg_returns AS (
    SELECT
        sr_item_sk,
        sr_reason_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_return_quantity)   AS total_qty,
        AVG(sr_return_tax)        AS avg_tax,
        COUNT(*)                  AS cnt_returns
    FROM sampled_returns
    GROUP BY sr_item_sk, sr_reason_sk
),
filtered_items AS (
    SELECT
        i_item_sk,
        i_category,
        i_manager_id,
        i_wholesale_cost,
        i_color,
        i_brand_id
    FROM item
    WHERE i_wholesale_cost > 5.00          -- predicate 2
      AND i_manager_id IN (4, 41)          -- predicate 3
      AND i_color = 'Red'                  -- predicate 4
      AND i_brand_id = 10                  -- predicate 5
),
filtered_reason AS (
    SELECT
        r_reason_sk,
        r_reason_desc,
        r_reason_id
    FROM reason
    WHERE r_reason_desc LIKE '%color%'
       OR r_reason_id = 'AAAAAAAAPAAAAAAA'
),
intersect_items AS (
    SELECT i_item_sk FROM item WHERE i_manager_id = 4
    INTERSECT
    SELECT i_item_sk FROM item WHERE i_color = 'Red'
),
base_agg AS (
    SELECT
        i.i_category,
        r.r_reason_desc,
        SUM(ar.total_return_amt) AS sum_return_amt,
        AVG(ar.avg_tax)          AS avg_return_tax,
        SUM(ar.total_qty)        AS sum_qty,
        COUNT(*)                 AS num_items
    FROM agg_returns ar
    JOIN filtered_items i   ON ar.sr_item_sk = i.i_item_sk
    JOIN filtered_reason r  ON ar.sr_reason_sk = r.r_reason_sk
    JOIN intersect_items ii ON i.i_item_sk = ii.i_item_sk
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_amt_inc_tax > 5000
    )
    GROUP BY i.i_category, r.r_reason_desc
    HAVING SUM(ar.total_return_amt) > 1000   -- additional filter
),
ranked AS (
    SELECT
        b.*,
        ROW_NUMBER() OVER (PARTITION BY b.i_category ORDER BY b.sum_return_amt DESC) AS rn
    FROM base_agg b
)
SELECT
    i_category,
    r_reason_desc,
    sum_return_amt,
    avg_return_tax,
    sum_qty,
    num_items
FROM ranked
WHERE rn <= 5                                 -- top‑5 per category
ORDER BY i_category, sum_return_amt DESC
