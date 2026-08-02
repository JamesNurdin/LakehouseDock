SELECT
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    MIN(SUBSTR(c.c_email_address, 1, 5)) AS email_prefix,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items,
    COUNT(DISTINCT REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{3})')) AS distinct_desc_codes,
    MIN(REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{3})')) AS sample_desc_code
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
WHERE
    p.p_promo_name LIKE '%Discount%'
    AND d.d_year = 2002
    AND REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND c.c_customer_sk IN (
        SELECT cr.cr_returning_customer_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity > 0
        EXCEPT
        SELECT sr.sr_customer_sk
        FROM store_returns sr
        WHERE sr.sr_return_quantity > 0
    )
GROUP BY
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name
HAVING
    SUM(ws.ws_net_paid_inc_tax) > 1000
ORDER BY
    total_profit DESC
LIMIT 100
