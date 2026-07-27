WITH avg_discount AS (
    SELECT avg(ss_ext_discount_amt) AS avg_disc
    FROM store_sales
)
SELECT
    promotion.p_promo_name AS promo_name,
    promotion.p_channel_email AS channel,
    SUM(store_sales.ss_ext_sales_price) AS total_sales,
    CASE WHEN SUM(store_sales.ss_ext_sales_price) > 5000 THEN 'High' ELSE 'Low' END AS sales_category,
    (SELECT avg_disc FROM avg_discount) AS overall_avg_discount
FROM store_sales
JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
WHERE promotion.p_channel_email = 'Y'
  AND store_sales.ss_ext_sales_price > 1000
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = store_sales.ss_promo_sk
          AND p2.p_discount_active = 'Y'
      )
GROUP BY promotion.p_promo_name, promotion.p_channel_email

UNION ALL

SELECT
    promotion.p_promo_name AS promo_name,
    promotion.p_channel_catalog AS channel,
    SUM(store_sales.ss_ext_sales_price) AS total_sales,
    CASE WHEN SUM(store_sales.ss_ext_sales_price) > 5000 THEN 'High' ELSE 'Low' END AS sales_category,
    (SELECT avg_disc FROM avg_discount) AS overall_avg_discount
FROM store_sales
JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
WHERE promotion.p_channel_catalog = 'Y'
  AND store_sales.ss_ext_sales_price <= 1000
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = store_sales.ss_promo_sk
          AND p2.p_discount_active = 'Y'
      )
GROUP BY promotion.p_promo_name, promotion.p_channel_catalog

ORDER BY total_sales DESC
LIMIT 100
