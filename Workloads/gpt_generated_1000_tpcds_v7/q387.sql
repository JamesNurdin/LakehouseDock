WITH filtered AS (
    SELECT
        cr.cr_refunded_cash,
        cr.cr_return_amount,
        r.r_reason_desc,
        p.p_promo_name,
        i.i_product_name,
        substring(i.i_product_name, 1, 5) AS prod_prefix,
        CASE
            WHEN regexp_like(i.i_product_name, '^A.*') THEN 'StartsA'
            ELSE 'Other'
        END AS name_category
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage')
      AND p.p_promo_name LIKE '%Clearance%'
      AND substring(i.i_product_name, 1, 3) = 'ABC'
)
SELECT
    prod_prefix,
    name_category,
    COUNT(*) AS return_cnt,
    SUM(cr_refunded_cash) AS total_refunded_cash,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_refunded_cash) AS avg_refunded_cash
FROM filtered
GROUP BY prod_prefix, name_category
ORDER BY total_refunded_cash DESC
LIMIT 10
