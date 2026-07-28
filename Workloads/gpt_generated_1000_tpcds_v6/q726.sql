WITH sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_net_profit
    FROM tpcds.catalog_sales cs
)
SELECT
    i.i_category,
    i.i_brand,
    concat(i.i_brand, ' - ', i.i_category) AS brand_category,
    substring(i.i_product_name, 1, 3) AS product_prefix,
    sum(s.cs_net_profit) AS total_net_profit,
    count(distinct s.cs_order_number) AS order_cnt
FROM sales s
JOIN tpcds.item i
    ON s.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p
    ON s.cs_promo_sk = p.p_promo_sk
WHERE regexp_like(i.i_item_desc, '(?i)red')
  AND p.p_promo_name LIKE '%DISCOUNT%'
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr
        WHERE sr.sr_item_sk = i.i_item_sk
          AND sr.sr_net_loss > 100
    )
GROUP BY
    i.i_category,
    i.i_brand,
    concat(i.i_brand, ' - ', i.i_category),
    substring(i.i_product_name, 1, 3)
ORDER BY total_net_profit DESC
LIMIT 100
