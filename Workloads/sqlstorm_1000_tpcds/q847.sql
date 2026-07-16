WITH sales AS (
    SELECT 
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_quantity AS qty,
        cs.cs_net_paid AS net_paid,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_class AS class,
        p.p_promo_name AS promo_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk

    UNION ALL

    SELECT 
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        i2.i_item_id,
        i2.i_product_name,
        i2.i_category,
        i2.i_class,
        p2.p_promo_name
    FROM store_sales ss
    JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
    LEFT JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk

    UNION ALL

    SELECT 
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        i3.i_item_id,
        i3.i_product_name,
        i3.i_category,
        i3.i_class,
        p3.p_promo_name
    FROM web_sales ws
    JOIN item i3 ON ws.ws_item_sk = i3.i_item_sk
    LEFT JOIN promotion p3 ON ws.ws_promo_sk = p3.p_promo_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    lower(c.c_email_address) AS email_lower,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    CASE 
        WHEN regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\\.com)$') THEN 'Corporate' 
        ELSE 'Other' 
    END AS email_type,
    sum(s.net_paid) AS total_net_paid,
    sum(s.qty) AS total_quantity,
    array_join(array_agg(DISTINCT s.product_name ORDER BY s.product_name), ' | ') AS distinct_products,
    array_join(array_agg(DISTINCT s.promo_name ORDER BY s.promo_name) FILTER (WHERE s.promo_name IS NOT NULL), ' | ') AS distinct_promos
FROM sales s
JOIN customer c ON s.cust_sk = c.c_customer_sk
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    lower(c.c_email_address),
    regexp_extract(c.c_email_address, '@(.+)$', 1),
    CASE 
        WHEN regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\\.com)$') THEN 'Corporate' 
        ELSE 'Other' 
    END
