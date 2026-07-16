SELECT
    s.s_store_id,
    cd.cd_gender,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(ss.ss_item_sk) AS items_sold,
    (SELECT ss2.ss_quantity FROM store_sales ss2 LIMIT 1) AS sample_quantity
FROM store_sales ss
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE s.s_state = 'NY'
  AND cd.cd_gender = 'M'
GROUP BY s.s_store_id, cd.cd_gender
HAVING SUM(ss.ss_ext_sales_price) > 3827.76
