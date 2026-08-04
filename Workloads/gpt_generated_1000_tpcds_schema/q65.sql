WITH
    agg_returns AS (
        SELECT
            wr_item_sk,
            SUM(wr_return_quantity) AS total_return_qty,
            SUM(wr_return_amt_inc_tax) AS total_return_amt,
            AVG(wr_return_amt_inc_tax) AS avg_return_amt
        FROM web_returns
        WHERE wr_return_amt_inc_tax > 100            -- return amount filter
          AND wr_fee < 50                           -- fee filter
          AND wr_return_quantity > 0               -- quantity filter
        GROUP BY wr_item_sk
    ),
    item_filtered AS (
        SELECT
            i_item_sk,
            i_item_id,
            i_brand,
            i_class,
            i_category,
            i_wholesale_cost,
            i_product_name
        FROM item
        WHERE i_wholesale_cost BETWEEN 5 AND 30            -- cost range filter
          AND i_class IN ('sports-apparel', 'decor', 'pop') -- class filter
          AND i_color IS NOT NULL                         -- non‑null color filter
    ),
    intersect_items AS (
        SELECT i_item_id FROM item_filtered WHERE i_brand = 'Brand#12'
        INTERSECT
        SELECT i_item_id FROM item_filtered WHERE i_category = 'pop'
    ),
    joined AS (
        SELECT
            i.i_item_id,
            i.i_brand,
            i.i_class,
            a.total_return_qty,
            a.total_return_amt,
            a.avg_return_amt
        FROM item_filtered i
        JOIN agg_returns a
            ON a.wr_item_sk = i.i_item_sk
        WHERE i.i_item_id IN (SELECT i_item_id FROM intersect_items)
    )
SELECT
    j.i_item_id,
    j.i_brand,
    j.i_class,
    j.total_return_qty,
    j.total_return_amt,
    j.avg_return_amt,
    monetary_component,
    ROW_NUMBER() OVER (PARTITION BY j.i_brand ORDER BY j.total_return_amt DESC) AS brand_rank,
    RANK() OVER (ORDER BY j.total_return_amt DESC) AS overall_rank
FROM joined j
CROSS JOIN UNNEST(ARRAY[j.total_return_amt, j.avg_return_amt]) AS t(monetary_component)
ORDER BY overall_rank
LIMIT 100
