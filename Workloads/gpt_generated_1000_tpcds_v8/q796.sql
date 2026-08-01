WITH union_items AS (
    SELECT DISTINCT i.i_item_sk, i.i_product_name
    FROM store_returns sr
    RIGHT OUTER JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_return_amt > 0

    UNION
    SELECT DISTINCT i.i_item_sk, i.i_product_name
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 0
),
high_web_items AS (
    SELECT DISTINCT i.i_item_sk, i.i_product_name
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt > 1000
),
intersect_items AS (
    SELECT i_item_sk, i_product_name
    FROM union_items
    INTERSECT
    SELECT i_item_sk, i_product_name
    FROM high_web_items
),
aggregated_returns AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        COALESCE(SUM(sr.sr_return_amt), 0) AS store_ret,
        COALESCE(SUM(cr.cr_return_amount), 0) AS catalog_ret,
        COALESCE(SUM(wr.wr_return_amt), 0) AS web_ret,
        COALESCE(SUM(sr.sr_return_amt), 0) + COALESCE(SUM(cr.cr_return_amount), 0) + COALESCE(SUM(wr.wr_return_amt), 0) AS total_ret
    FROM item i
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
    ar.i_item_sk,
    ar.i_product_name,
    ar.total_ret,
    CASE
        WHEN ar.total_ret > 5000 THEN 'High'
        WHEN ar.total_ret > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    ROW_NUMBER() OVER (
        PARTITION BY CASE
            WHEN ar.total_ret > 5000 THEN 'High'
            WHEN ar.total_ret > 1000 THEN 'Medium'
            ELSE 'Low'
        END
        ORDER BY ar.total_ret DESC
    ) AS category_rank
FROM intersect_items ii
JOIN aggregated_returns ar
    ON ii.i_item_sk = ar.i_item_sk
WHERE ar.total_ret > 0
GROUP BY ar.i_item_sk, ar.i_product_name, ar.total_ret,
    CASE
        WHEN ar.total_ret > 5000 THEN 'High'
        WHEN ar.total_ret > 1000 THEN 'Medium'
        ELSE 'Low'
    END
HAVING ar.total_ret > 1000
ORDER BY ar.total_ret DESC, category_rank
LIMIT 100
