WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2002
)
SELECT
    d.d_date AS activity_date,
    st.s_store_id AS store_id,
    ss.ss_ext_sales_price AS amount,
    'Sale' AS activity_type,
    CASE WHEN ss.ss_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
    (
        SELECT SUM(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = ss.ss_store_sk
    ) AS total_amount_for_key
FROM store_sales ss
JOIN recent_dates rd ON ss.ss_sold_date_sk = rd.d_date_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store st ON ss.ss_store_sk = st.s_store_sk
WHERE st.s_store_id IN (
    SELECT s_store_id
    FROM store
    WHERE s_state = 'TX'
)
UNION
SELECT
    d.d_date AS activity_date,
    CAST(NULL AS varchar) AS store_id,
    cr.cr_return_amount AS amount,
    'Return' AS activity_type,
    CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = cr.cr_returned_date_sk
    ) AS total_amount_for_key
FROM catalog_returns cr
JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_department IN ('Electronics', 'Clothing')
LIMIT 100
