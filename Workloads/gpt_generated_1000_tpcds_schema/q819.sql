WITH
    sampled_sales AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    sales_with_strings AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_time_sk,
            cs.cs_bill_customer_sk,
            cs.cs_promo_sk,
            cs.cs_catalog_page_sk,
            regexp_extract(cp.cp_description, '(\\w{3})', 1) AS desc_code,
            concat(p.p_promo_name, '_', cp.cp_type) AS promo_desc
        FROM sampled_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE regexp_like(cp.cp_description, '[A-Z]{3}')
          AND p.p_promo_name LIKE '%Sale%'
    ),
    returns_with_strings AS (
        SELECT
            cr.cr_order_number,
            cr.cr_returned_time_sk,
            regexp_like(cast(cr.cr_reason_sk AS varchar), '^5[0-9]$') AS reason_match,
            cp.cp_type
        FROM catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE regexp_like(cast(cr.cr_reason_sk AS varchar), '^5[0-9]$')
          AND cp.cp_type LIKE 'promo%'
    ),
    orders_intersect AS (
        SELECT cs_order_number AS order_number
        FROM sales_with_strings
        INTERSECT
        SELECT cr_order_number
        FROM returns_with_strings
    ),
    orders_except AS (
        SELECT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_returned_time_sk IS NOT NULL
        EXCEPT
        SELECT sr.sr_ticket_number
        FROM store_returns sr
    ),
    final_set AS (
        SELECT order_number FROM orders_intersect
        UNION ALL
        SELECT cr_order_number AS order_number FROM orders_except
    ),
    sales_anti AS (
        SELECT s.cs_order_number, s.cs_bill_customer_sk, s.cs_net_paid
        FROM catalog_sales s
        WHERE NOT EXISTS (
            SELECT 1 FROM catalog_returns r WHERE r.cr_order_number = s.cs_order_number
        )
    )
SELECT
    p.p_channel_event,
    COUNT(DISTINCT fs.order_number) AS order_cnt,
    SUM(s.cs_net_paid) AS total_net_paid,
    MIN(s.cs_sold_date_sk) AS earliest_date_sk,
    MAX(s.cs_sold_date_sk) AS latest_date_sk
FROM final_set fs
JOIN catalog_sales s ON fs.order_number = s.cs_order_number
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
GROUP BY p.p_channel_event
ORDER BY order_cnt DESC
LIMIT 100
