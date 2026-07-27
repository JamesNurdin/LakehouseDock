WITH sales_agg AS (
    SELECT ss_item_sk,
           ss_customer_sk,
           ss_store_sk,
           ss_promo_sk,
           SUM(ss_ext_sales_price) AS total_sales,
           SUM(ss_quantity)        AS total_qty,
           AVG(ss_net_profit)      AS avg_profit,
           COUNT(*)                AS txn_count
    FROM store_sales
    WHERE ss_quantity > 0
      AND ss_ext_sales_price > 0
    GROUP BY ss_item_sk, ss_customer_sk, ss_store_sk, ss_promo_sk
)
SELECT i.i_category,
       i.i_brand,
       s.s_market_id,
       p.p_promo_name,
       cd.cd_gender,
       SUM(sa.total_sales) AS sum_sales,
       SUM(sa.total_qty)   AS sum_qty,
       AVG(sa.avg_profit)  AS avg_profit,
       COUNT(*)            AS txn_rows
FROM sales_agg sa
JOIN item i ON sa.ss_item_sk = i.i_item_sk
JOIN promotion p ON sa.ss_promo_sk = p.p_promo_sk
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN customer c ON sa.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE i.i_current_price > 50
  AND s.s_market_id IN (2, 8)
  AND cd.cd_gender = 'F'
  AND cd.cd_dep_count >= 3
  AND p.p_discount_active = 'Y'
GROUP BY i.i_category, i.i_brand, s.s_market_id, p.p_promo_name, cd.cd_gender
ORDER BY sum_sales DESC
LIMIT 100
