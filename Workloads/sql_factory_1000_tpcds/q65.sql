SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    latest_sales.ss_sold_date_sk AS latest_sale_date,
    latest_sales.ss_ext_sales_price AS sale_price,
    CASE WHEN latest_sales.ss_ext_sales_price = 0 THEN NULL ELSE latest_sales.ss_ext_discount_amt / latest_sales.ss_ext_sales_price END AS discount_ratio,
    CASE
        WHEN latest_sales.ss_ext_sales_price = 0 THEN 'UNKNOWN'
        WHEN latest_sales.ss_ext_discount_amt / latest_sales.ss_ext_sales_price > 0.2 THEN 'HIGH'
        WHEN latest_sales.ss_ext_discount_amt / latest_sales.ss_ext_sales_price > 0.1 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS discount_category,
    COALESCE(p.p_promo_name, 'NO_PROMO') AS promotion_name,
    COALESCE(inv.inv_quantity_on_hand, 0) AS current_inventory_qty
FROM (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_promo_sk,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn
    FROM store_sales ss
) latest_sales
JOIN item i ON latest_sales.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON latest_sales.ss_promo_sk = p.p_promo_sk
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
WHERE latest_sales.rn = 1
ORDER BY discount_ratio DESC NULLS LAST
LIMIT 30
