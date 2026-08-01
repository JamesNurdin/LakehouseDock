/* goal: Identify items that were returned both via catalog and web channels, summarizing return quantities and amounts by item, reason and year, with subtotals and full outer inclusion of all reasons. */
WITH cat_agg AS (
    SELECT
        cr.cr_item_sk                         AS item_sk,
        i.i_product_name                      AS product_name,
        r.r_reason_desc                       AS reason_desc,
        d.d_year                              AS year,
        SUM(cr.cr_return_quantity)            AS total_qty,
        SUM(cr.cr_return_amount)              AS total_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    LEFT OUTER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
    GROUP BY cr.cr_item_sk, i.i_product_name, r.r_reason_desc, d.d_year
),
web_agg AS (
    SELECT
        wr.wr_item_sk                         AS item_sk,
        i.i_product_name                      AS product_name,
        r.r_reason_desc                       AS reason_desc,
        d2.d_year                             AS year,
        SUM(wr.wr_return_quantity)            AS total_qty,
        SUM(wr.wr_return_amt)                 AS total_amount
    FROM web_returns wr
    RIGHT OUTER JOIN date_dim d2
        ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT OUTER JOIN date_dim d3
        ON wp.wp_creation_date_sk = d3.d_date_sk
    LEFT OUTER JOIN date_dim d4
        ON wp.wp_access_date_sk   = d4.d_date_sk
    WHERE d2.d_year BETWEEN 2000 AND 2002
    GROUP BY wr.wr_item_sk, i.i_product_name, r.r_reason_desc, d2.d_year
),
common_items AS (
    SELECT item_sk FROM cat_agg
    INTERSECT
    SELECT item_sk FROM web_agg
),
union_agg AS (
    SELECT item_sk, product_name, reason_desc, year, total_qty, total_amount FROM cat_agg
    UNION DISTINCT
    SELECT item_sk, product_name, reason_desc, year, total_qty, total_amount FROM web_agg
)
SELECT
    ua.item_sk,
    ua.product_name,
    ua.reason_desc,
    ua.year,
    SUM(ua.total_qty)   AS sum_qty,
    SUM(ua.total_amount) AS sum_amount
FROM union_agg ua
FULL OUTER JOIN reason r_full
    ON ua.reason_desc = r_full.r_reason_desc
WHERE ua.item_sk IN (SELECT item_sk FROM common_items)
GROUP BY GROUPING SETS (
    (ua.item_sk, ua.product_name, ua.reason_desc, ua.year),
    (ua.item_sk, ua.product_name, ua.year),
    (ua.item_sk, ua.year),
    ()
)
ORDER BY sum_amount DESC
OFFSET 0 ROWS
LIMIT 100
