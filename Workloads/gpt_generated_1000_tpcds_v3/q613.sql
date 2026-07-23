WITH sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        s.s_store_name AS store_name,
        CONCAT(i.i_brand, ' ', i.i_item_desc) AS full_desc,
        SUBSTR(i.i_item_desc, 1, 15) AS short_desc,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS numeric_code,
        SUM(ss.ss_net_paid_inc_tax) AS amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_transactions,
        CASE
            WHEN SUM(ss.ss_net_paid_inc_tax) > 10000 THEN 'High'
            ELSE 'Low'
        END AS category,
        'sales' AS metric_type
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        AND regexp_like(i.i_item_desc, '\\d{3}')
        AND i.i_item_desc LIKE '%Co%'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        i.i_brand,
        i.i_item_desc
    HAVING
        SUM(ss.ss_net_paid_inc_tax) > 1000
),
returns_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        s.s_store_name AS store_name,
        CONCAT(i.i_brand, ' ', i.i_item_desc) AS full_desc,
        SUBSTR(i.i_item_desc, 1, 15) AS short_desc,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS numeric_code,
        SUM(r.sr_return_amt) AS amount,
        COUNT(DISTINCT r.sr_ticket_number) AS distinct_transactions,
        CASE
            WHEN SUM(r.sr_return_amt) > 5000 THEN 'High Return'
            ELSE 'Low Return'
        END AS category,
        'returns' AS metric_type
    FROM
        store_returns r
        JOIN date_dim d ON r.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON r.sr_item_sk = i.i_item_sk
        JOIN store s ON r.sr_store_sk = s.s_store_sk
        JOIN reason re ON r.sr_reason_sk = re.r_reason_sk
    WHERE
        d.d_year = 2001
        AND regexp_like(i.i_item_desc, '\\d{3}')
        AND i.i_item_desc LIKE '%Co%'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        i.i_brand,
        i.i_item_desc
    HAVING
        SUM(r.sr_return_amt) > 100
)
SELECT DISTINCT
    item_id,
    product_name,
    store_name,
    numeric_code,
    full_desc,
    short_desc,
    metric_type,
    amount,
    distinct_transactions,
    category
FROM (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
) AS combined
ORDER BY amount DESC
LIMIT 100
