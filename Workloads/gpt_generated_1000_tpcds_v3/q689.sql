WITH filtered_promotions AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_details,
        p.p_discount_active
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '[0-9]{4}')
      AND p.p_channel_details LIKE '%local%'
)
SELECT
    fp.p_promo_name,
    CONCAT(SUBSTRING(i.i_brand, 1, 3), '-', SUBSTRING(i.i_category, 1, 5)) AS brand_category_prefix,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount
FROM filtered_promotions fp
JOIN catalog_sales cs
    ON cs.cs_promo_sk = fp.p_promo_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
WHERE i.i_category LIKE '%Electronics%'
GROUP BY
    fp.p_promo_name,
    CONCAT(SUBSTRING(i.i_brand, 1, 3), '-', SUBSTRING(i.i_category, 1, 5))
ORDER BY total_net_profit DESC
LIMIT 100
