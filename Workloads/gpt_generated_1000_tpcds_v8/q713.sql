/*
Goal: Analyze sales and return performance per department and brand, combining catalog, web and store channels. The query joins all six selected tables using the allowed keys, re‑uses the ITEM table under two aliases, includes a TABLESAMPLE, an EXISTS semi‑join, a LATERAL subquery, a correlated subquery, a UNION DISTINCT of two aggregated branches, and the result is paginated and limited to 100 rows.
*/
WITH sampled_item AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)
),
base AS (
    SELECT
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        ws1.ws_ext_sales_price,
        ws1.ws_sold_date_sk,
        i1.i_item_sk,
        i1.i_brand,
        i1.i_current_price,
        cp.cp_department
    FROM catalog_returns cr
    JOIN sampled_item i1 ON cr.cr_item_sk = i1.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_sales ws1 ON i1.i_item_sk = ws1.ws_item_sk
    JOIN web_returns wr ON ws1.ws_item_sk = wr.wr_item_sk
                         AND ws1.ws_order_number = wr.wr_order_number
    JOIN store_returns sr ON i1.i_item_sk = sr.sr_item_sk
    WHERE i1.i_current_price > 20
),
agg1 AS (
    SELECT
        cp_department,
        i_brand,
        ws_sold_date_sk,
        i_item_sk,
        SUM(ws_ext_sales_price)               AS total_sales,
        SUM(cr_return_amount)                AS total_catalog_returns,
        SUM(sr_return_amt)                   AS total_store_returns,
        SUM(wr_return_amt)                   AS total_web_returns
    FROM base
    WHERE EXISTS (
        SELECT 1
        FROM web_sales ws_check
        WHERE ws_check.ws_item_sk = base.i_item_sk
          AND ws_check.ws_ext_sales_price > 500
    )
    GROUP BY cp_department, i_brand, ws_sold_date_sk, i_item_sk
),
agg2 AS (
    SELECT
        cp.cp_department               AS cp_department,
        i2.i_brand                     AS i_brand,
        ws2.ws_sold_date_sk            AS ws_sold_date_sk,
        i2.i_item_sk                   AS i_item_sk,
        SUM(ws2.ws_ext_sales_price) * 0.9   AS total_sales,
        SUM(cr2.cr_return_amount) * 1.1    AS total_catalog_returns,
        SUM(sr2.sr_return_amt)             AS total_store_returns,
        SUM(wr2.wr_return_amt)             AS total_web_returns
    FROM catalog_returns cr2
    JOIN sampled_item i2 ON cr2.cr_item_sk = i2.i_item_sk
    JOIN catalog_page cp ON cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_sales ws2 ON i2.i_item_sk = ws2.ws_item_sk
    JOIN web_returns wr2 ON ws2.ws_item_sk = wr2.wr_item_sk
                         AND ws2.ws_order_number = wr2.wr_order_number
    JOIN store_returns sr2 ON i2.i_item_sk = sr2.sr_item_sk
    WHERE i2.i_current_price BETWEEN 10 AND 30
    GROUP BY cp.cp_department, i2.i_brand, ws2.ws_sold_date_sk, i2.i_item_sk
)
SELECT
    u.cp_department,
    u.i_brand,
    u.ws_sold_date_sk,
    u.total_sales,
    u.total_catalog_returns,
    u.total_store_returns,
    u.total_web_returns,
    lt.avg_return,
    (
        SELECT MAX(ws3.ws_ext_sales_price)
        FROM web_sales ws3
        JOIN item i3 ON ws3.ws_item_sk = i3.i_item_sk
        WHERE i3.i_brand = u.i_brand
    ) AS max_price_for_brand
FROM (
    SELECT * FROM agg1
    UNION DISTINCT
    SELECT * FROM agg2
) u
CROSS JOIN LATERAL (
    SELECT (u.total_store_returns + u.total_web_returns + u.total_catalog_returns) / 3.0 AS avg_return
) lt
WHERE u.total_sales > (
    SELECT AVG(inner_u.total_sales)
    FROM (
        SELECT total_sales FROM agg1
        UNION ALL
        SELECT total_sales FROM agg2
    ) inner_u
)
ORDER BY u.total_sales DESC
OFFSET 10
LIMIT 100
