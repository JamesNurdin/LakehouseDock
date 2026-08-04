WITH inv_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT
    it.i_item_id,
    it.i_product_name,
    it.i_category,
    ss.ss_sold_date_sk,
    ss.ss_net_profit,
    ROW_NUMBER() OVER (PARTITION BY it.i_category ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    (SELECT SUM(ss2.ss_ext_sales_price)
       FROM store_sales ss2
       WHERE ss2.ss_item_sk = it.i_item_sk) AS total_item_sales,
    CASE WHEN pr.p_channel_radio = 'Y' THEN 'Radio' ELSE 'Other' END AS promo_channel
FROM inv_sample i
JOIN item it ON i.inv_item_sk = it.i_item_sk
JOIN promotion pr ON pr.p_item_sk = it.i_item_sk
JOIN store_sales ss ON ss.ss_item_sk = it.i_item_sk AND ss.ss_promo_sk = pr.p_promo_sk
WHERE i.inv_quantity_on_hand > 0
  AND i.inv_warehouse_sk IN (2, 3, 15)
  AND it.i_current_price BETWEEN 10 AND 200
  AND pr.p_discount_active = 'Y'
  AND ss.ss_net_profit > 0
  AND ss.ss_sold_date_sk BETWEEN 2450900 AND 2451100
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
          AND p2.p_cost > 500
      )
UNION
SELECT
    it.i_item_id,
    it.i_product_name,
    it.i_category,
    ss.ss_sold_date_sk,
    ss.ss_net_profit,
    ROW_NUMBER() OVER (PARTITION BY it.i_category ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    (SELECT SUM(ss2.ss_ext_sales_price)
       FROM store_sales ss2
       WHERE ss2.ss_item_sk = it.i_item_sk) AS total_item_sales,
    CASE WHEN pr.p_channel_radio = 'Y' THEN 'Radio' ELSE 'Other' END AS promo_channel
FROM inv_sample i
JOIN item it ON i.inv_item_sk = it.i_item_sk
JOIN promotion pr ON pr.p_item_sk = it.i_item_sk
JOIN store_sales ss ON ss.ss_item_sk = it.i_item_sk AND ss.ss_promo_sk = pr.p_promo_sk
WHERE i.inv_quantity_on_hand > 5
  AND i.inv_warehouse_sk IN (13, 14)
  AND it.i_current_price BETWEEN 20 AND 500
  AND pr.p_discount_active = 'N'
  AND ss.ss_net_profit > 10
  AND ss.ss_sold_date_sk BETWEEN 2450800 AND 2451200
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
          AND p2.p_cost > 500
      )
ORDER BY profit_rank
OFFSET 0 ROWS
LIMIT 100
