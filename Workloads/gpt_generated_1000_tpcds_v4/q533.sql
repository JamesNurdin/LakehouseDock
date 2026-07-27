WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS three_digit_code
    FROM item i
    WHERE regexp_like(i.i_item_desc, '\\d{3}')
      AND i.i_product_name LIKE '%Coffee%'
)
SELECT
    f.i_brand,
    p.p_promo_name,
    f.three_digit_code,
    CONCAT(f.i_brand, '-', f.three_digit_code) AS brand_code,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count
FROM filtered_items f
JOIN catalog_sales cs
    ON cs.cs_item_sk = f.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN inventory inv
    ON inv.inv_item_sk = f.i_item_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = f.i_item_sk
WHERE p.p_promo_name LIKE '%Summer%'
  AND inv.inv_quantity_on_hand > 500
GROUP BY
    f.i_brand,
    p.p_promo_name,
    f.three_digit_code,
    CONCAT(f.i_brand, '-', f.three_digit_code)
ORDER BY total_net_profit DESC
LIMIT 100
