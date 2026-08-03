WITH filtered_sales AS (
    SELECT
        s.s_city,
        i.i_item_id,
        i.i_product_name,
        p.p_promo_name,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity)   AS total_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_city LIKE 'A%'
      AND regexp_like(i.i_item_desc, '[0-9]{3}')
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND p2.p_channel_tv = 'Y'
      )
    GROUP BY s.s_city, i.i_item_id, i.i_product_name, p.p_promo_name
)
SELECT
    ROW_NUMBER() OVER (ORDER BY fs.total_profit DESC) AS row_num,
    fs.s_city,
    fs.i_item_id,
    fs.i_product_name,
    fs.p_promo_name,
    fs.total_quantity,
    fs.total_profit,
    CONCAT('City: ', fs.s_city) AS city_label,
    SUBSTRING(fs.i_product_name, 1, 10) AS product_short
FROM (
    SELECT DISTINCT *
    FROM filtered_sales
) fs
ORDER BY fs.total_profit DESC
LIMIT 100
