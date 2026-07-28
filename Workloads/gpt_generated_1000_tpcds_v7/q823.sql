WITH catalog_returns_filtered AS (
    SELECT
        i.i_brand AS brand,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        p.p_promo_id AS promo_id
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '(?i)blue')
      AND c.c_email_address LIKE '%@example.com'
),
store_returns_filtered AS (
    SELECT
        i.i_brand AS brand,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        p.p_promo_id AS promo_id
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '(?i)blue')
      AND c.c_email_address LIKE '%@example.com'
),
combined AS (
    SELECT
        brand,
        return_amount,
        net_loss,
        regexp_extract(promo_id, '(\\d+)$') AS promo_suffix
    FROM catalog_returns_filtered
    UNION ALL
    SELECT
        brand,
        return_amount,
        net_loss,
        regexp_extract(promo_id, '(\\d+)$') AS promo_suffix
    FROM store_returns_filtered
)
SELECT
    brand,
    promo_suffix,
    CONCAT(brand, ' - ', promo_suffix) AS brand_promo_key,
    SUM(return_amount) AS total_return_amount,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS return_rows
FROM combined
GROUP BY brand, promo_suffix
ORDER BY total_return_amount DESC
LIMIT 20
