WITH
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        WHERE inv_warehouse_sk IN (11, 15)                     -- filter predicate 1
        GROUP BY inv_item_sk, inv_date_sk
    ),
    date_filt AS (
        SELECT d_date_sk, d_year, d_week_seq
        FROM date_dim
        WHERE d_year = 2002                                   -- filter predicate 2
          AND d_week_seq BETWEEN 5 AND 15                     -- filter predicate 3
    ),
    page_with_returns AS (
        SELECT cp.cp_catalog_page_id
        FROM catalog_page cp
        JOIN catalog_returns cr ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cr.cr_return_amount > 0
    ),
    page_exclude AS (
        SELECT cp.cp_catalog_page_id
        FROM catalog_page cp
        JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    page_diff AS (
        SELECT cp_catalog_page_id
        FROM page_with_returns
        EXCEPT
        SELECT cp_catalog_page_id
        FROM page_exclude
    )
SELECT
    cp.cp_department,
    d.d_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ai.total_qty) AS total_inventory_qty,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cr.cr_return_amount) DESC) AS dept_return_rank,
    grp.g,
    yr.year_val,
    (SELECT MAX(d_year) FROM date_dim) AS max_year               -- scalar subquery
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_filt d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN inv_agg ai ON ai.inv_item_sk = cr.cr_item_sk AND ai.inv_date_sk = d.d_date_sk
CROSS JOIN (VALUES 1, 2, 3) AS grp(g)                              -- cartesian product
CROSS JOIN (
    SELECT DISTINCT d_year AS year_val
    FROM date_dim
    WHERE d_year IN (2001, 2002)
) AS yr                                                   -- computed set
WHERE cp.cp_department IN ('Books', 'Electronics')                 -- filter predicate 4
  AND cr.cr_return_amount > 0                                      -- filter predicate 5
  AND cp.cp_catalog_page_id IN (SELECT cp_catalog_page_id FROM page_diff)
  AND EXISTS (                                                     -- subquery predicate
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = cr.cr_item_sk
          AND cr2.cr_return_amount > 100
    )
GROUP BY GROUPING SETS (
        (cp.cp_department, d.d_year),
        (cp.cp_department),
        (d.d_year),
        ()
    ), cp.cp_department, d.d_year, grp.g, yr.year_val
HAVING SUM(cr.cr_return_amount) > 50
ORDER BY total_return_amount DESC
LIMIT 100
