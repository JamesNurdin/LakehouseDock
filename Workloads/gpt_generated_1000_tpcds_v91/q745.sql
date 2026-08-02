WITH item_agg AS (
    SELECT
        i.i_item_id AS entity_id,
        'Item' AS entity_type,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
        CONCAT(i.i_brand, ' ', i.i_category) AS metric,
        (
            SELECT COUNT(DISTINCT ss_inner.ss_customer_sk)
            FROM store_sales ss_inner
            WHERE ss_inner.ss_item_sk = i.i_item_sk
        ) AS extra_metric,
        regexp_extract(i.i_product_name, '([A-Z]{2}[0-9]{3})', 1) AS extra_str
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    WHERE regexp_like(i.i_product_name, '^.*[A-Z]{2}[0-9]{3}.*$')
      AND i.i_product_name LIKE '%COOL%'
    GROUP BY i.i_item_id, i.i_brand, i.i_category, i.i_item_sk, i.i_product_name
),
customer_agg AS (
    SELECT
        c.c_customer_id AS entity_id,
        'Customer' AS entity_type,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS metric,
        (
            SELECT SUM(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_customer_sk = c.c_customer_sk
        ) AS extra_metric,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS extra_str
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_customer_sk = sr.sr_customer_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND c.c_first_name LIKE 'A%'
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_customer_sk, c.c_email_address
)
SELECT
    entity_id,
    entity_type,
    total_sales,
    total_returns,
    metric,
    extra_metric,
    extra_str
FROM (
    SELECT
        entity_id,
        entity_type,
        total_sales,
        total_returns,
        metric,
        extra_metric,
        extra_str
    FROM item_agg
    UNION
    SELECT
        entity_id,
        entity_type,
        total_sales,
        total_returns,
        metric,
        extra_metric,
        extra_str
    FROM customer_agg
) combined
ORDER BY total_sales DESC
LIMIT 100
