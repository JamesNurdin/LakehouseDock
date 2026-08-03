WITH full_sales_returns AS (
    SELECT
        COALESCE(cs.cs_order_number, cr.cr_order_number) AS key_id,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS description,
        (
            SELECT COALESCE(SUM(cr_sub.cr_return_amount), 0)
            FROM catalog_returns cr_sub
            WHERE cr_sub.cr_order_number = COALESCE(cs.cs_order_number, cr.cr_order_number)
        ) AS metric
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    WHERE COALESCE(cs.cs_order_number, cr.cr_order_number) IS NOT NULL
),
store_keys_returns AS (
    SELECT sr.sr_store_sk AS store_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 5
),
store_keys_closed AS (
    SELECT s.s_store_sk AS store_sk
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
),
intersected_store_keys AS (
    SELECT store_sk FROM store_keys_returns
    INTERSECT
    SELECT store_sk FROM store_keys_closed
),
store_details AS (
    SELECT s.s_store_sk AS key_id,
           s.s_store_name AS description,
           CAST(NULL AS decimal(7,2)) AS metric
    FROM store s
    JOIN intersected_store_keys isk ON s.s_store_sk = isk.store_sk
)
SELECT key_id, description, metric
FROM (
    SELECT key_id, description, metric FROM full_sales_returns
    UNION ALL
    SELECT key_id, description, metric FROM store_details
) AS combined
ORDER BY metric DESC NULLS LAST
LIMIT 100
