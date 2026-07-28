WITH returns_with_sales AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_refunded_customer_sk,
        cs.cs_promo_sk,
        cs.cs_item_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_channel_email,
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    regexp_extract(r.r_reason_desc, '^([^ ]+)', 1) AS reason_first_word,
    sum(rw.cr_return_amount) AS total_return_amount,
    sum(rw.cr_net_loss) AS total_net_loss,
    count(DISTINCT rw.cr_order_number) AS distinct_returns
FROM returns_with_sales rw
JOIN promotion p
    ON rw.cs_promo_sk = p.p_promo_sk
JOIN reason r
    ON rw.cr_reason_sk = r.r_reason_sk
JOIN customer c
    ON rw.cr_refunded_customer_sk = c.c_customer_sk
WHERE
    regexp_like(p.p_promo_id, '^AAAA')
    AND p.p_channel_email = 'Y'
    AND r.r_reason_desc LIKE '%color%'
    AND concat(c.c_first_name, c.c_last_name) LIKE '%Smith%'
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    p.p_channel_email,
    concat(c.c_first_name, ' ', c.c_last_name),
    regexp_extract(r.r_reason_desc, '^([^ ]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
