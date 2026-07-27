WITH promo_web AS (
    SELECT
        p.p_promo_name,
        i.i_manager_id,
        i.i_product_name,
        REGEXP_EXTRACT(i.i_product_name, '([0-9]{2,})') AS product_code,
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        wp.wp_web_page_sk
    FROM promotion p
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_start.d_date_sk
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(i.i_product_name, '[0-9]{2,}')
      AND ca.ca_city LIKE 'A%'
      AND SUBSTRING(ca.ca_zip, 1, 3) = '489'
)
SELECT
    pw.p_promo_name,
    pw.i_manager_id,
    COUNT(DISTINCT pw.c_customer_sk) AS unique_customers,
    COUNT(pw.wp_web_page_sk) AS page_views,
    MIN(CONCAT(pw.ca_city, ', ', pw.ca_state)) AS sample_location,
    MIN(SUBSTRING(pw.ca_zip, 1, 3)) AS zip_prefix,
    MIN(pw.product_code) AS product_code_example
FROM promo_web pw
GROUP BY pw.p_promo_name, pw.i_manager_id
ORDER BY page_views DESC
LIMIT 100
