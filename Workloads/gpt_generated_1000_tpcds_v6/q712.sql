WITH filtered_items AS (
    SELECT i_item_sk,
           i_product_name,
           regexp_extract(i_product_name, '(\\w+)-\\w+', 1) AS brand_code,
           i_brand
    FROM item
    WHERE regexp_like(i_product_name, '(\\w+)-\\w+')
),
order_items AS (
    SELECT DISTINCT cs_order_number,
           cs_item_sk,
           cs_bill_customer_sk,
           cs_net_profit,
           cs_promo_sk
    FROM catalog_sales
)
SELECT
    c.c_customer_id,
    c.c_email_address,
    SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
    f.brand_code,
    CONCAT(f.brand_code, '-', f.i_brand) AS brand_label,
    COUNT(o.cs_order_number) AS orders,
    SUM(o.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    RANK() OVER (PARTITION BY f.brand_code ORDER BY SUM(o.cs_net_profit) DESC) AS brand_profit_rank
FROM order_items o
JOIN filtered_items f
    ON o.cs_item_sk = f.i_item_sk
JOIN customer c
    ON o.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN promotion p
    ON o.cs_promo_sk = p.p_promo_sk
WHERE c.c_email_address LIKE '%@%org'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = o.cs_order_number
          AND cr.cr_item_sk = o.cs_item_sk
    )
GROUP BY
    c.c_customer_id,
    c.c_email_address,
    SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1),
    f.brand_code,
    CONCAT(f.brand_code, '-', f.i_brand)
HAVING SUM(o.cs_net_profit) > 0
ORDER BY total_net_profit DESC, c.c_customer_id
LIMIT 100
