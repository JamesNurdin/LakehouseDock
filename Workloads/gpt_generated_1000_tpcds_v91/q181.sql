WITH filtered_sales AS (
    SELECT ss.ss_item_sk,
           ss.ss_promo_sk,
           ss.ss_quantity,
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           ss.ss_ext_wholesale_cost,
           ss.ss_sold_date_sk,
           ss.ss_store_sk
    FROM store_sales ss
    WHERE ss.ss_ext_wholesale_cost > 1500
      AND ss.ss_net_profit > 0
      AND ss.ss_quantity >= 2
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450200
),
intersected_items AS (
    SELECT p.p_item_sk AS i_item_sk
    FROM promotion p
    WHERE p.p_channel_details LIKE '%National%'
    INTERSECT
    SELECT i.i_item_sk
    FROM item i
    WHERE i.i_brand_id = 2004002
),
aggregated AS (
    SELECT i.i_item_id,
           i.i_brand,
           i.i_category,
           p.p_promo_name,
           SUM(fs.ss_ext_sales_price) AS total_sales,
           AVG(fs.ss_net_profit) AS avg_profit,
           COUNT(*) AS trans_cnt,
           MIN(fs.ss_sold_date_sk) AS first_sold_date_sk,
           MAX(fs.ss_sold_date_sk) AS last_sold_date_sk,
           CASE WHEN SUM(fs.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM filtered_sales fs
    JOIN item i ON fs.ss_item_sk = i.i_item_sk
    JOIN promotion p ON fs.ss_promo_sk = p.p_promo_sk
    WHERE i.i_item_sk IN (SELECT i_item_sk FROM intersected_items)
      AND i.i_brand_id IN (10005006, 2004002)
      AND i.i_size = 'extra large'
      AND p.p_channel_radio = 'N'
      AND NOT EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_channel_details = 'High'
      )
    GROUP BY i.i_item_id, i.i_brand, i.i_category, p.p_promo_name
)
SELECT a.*, ROW_NUMBER() OVER (PARTITION BY a.i_item_id ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated a
ORDER BY a.total_sales DESC
LIMIT 100
