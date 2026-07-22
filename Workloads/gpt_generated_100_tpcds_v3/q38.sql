SELECT
    promotion.p_promo_name,
    store_sales.ss_item_sk,
    SUM(store_sales.ss_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt
FROM
    store_sales
INNER JOIN promotion
    ON store_sales.ss_promo_sk = promotion.p_promo_sk
WHERE
    promotion.p_channel_demo = 'N'
    AND store_sales.ss_ext_list_price > 1000
GROUP BY
    promotion.p_promo_name,
    store_sales.ss_item_sk
ORDER BY
    total_sales DESC
LIMIT 100
