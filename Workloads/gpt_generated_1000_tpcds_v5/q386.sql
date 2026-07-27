WITH returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk
    FROM catalog_returns cr
),
sales AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_item_sk,
        ws.ws_promo_sk
    FROM web_sales ws
),
filtered AS (
    SELECT
        r.cr_return_amount,
        r.cr_return_quantity,
        s.ws_ext_sales_price,
        s.ws_quantity,
        i.i_brand,
        i.i_item_desc,
        p.p_promo_name,
        ca.ca_street_name,
        regexp_extract(i.i_item_desc, '(Deluxe|Premium)', 1) AS extracted_term,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM returns r
    JOIN item i ON r.cr_item_sk = i.i_item_sk
    JOIN customer c ON r.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON r.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN sales s ON s.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '(Deluxe|Premium)')
      AND ca.ca_street_name LIKE 'M%'
)
SELECT
    i_brand AS brand,
    extracted_term,
    p_promo_name AS promo_name,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_ext_sales_price) AS total_sales_amount,
    CASE
        WHEN SUM(ws_ext_sales_price) > 0 THEN SUM(cr_return_amount) / SUM(ws_ext_sales_price)
        ELSE NULL
    END AS return_to_sales_ratio,
    COUNT(*) AS return_count
FROM filtered
GROUP BY
    i_brand,
    extracted_term,
    p_promo_name
ORDER BY total_return_amount DESC
LIMIT 100
