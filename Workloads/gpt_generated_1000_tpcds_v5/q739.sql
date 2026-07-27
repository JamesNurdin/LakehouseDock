WITH sales_agg AS (
    SELECT
        ws_item_sk,
        ws_web_page_sk,
        ws_promo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_coupon_amt) AS avg_coupon
    FROM web_sales
    WHERE ws_coupon_amt > 0
      AND ws_list_price >= 20
      AND ws_quantity > 0
    GROUP BY ws_item_sk, ws_web_page_sk, ws_promo_sk
),
joined_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_class,
        i.i_manager_id,
        wp.wp_type,
        p.p_promo_name,
        p.p_channel_catalog,
        p.p_discount_active,
        sa.total_sales,
        sa.total_qty,
        sa.total_profit,
        CASE
            WHEN sa.total_profit > 10000 THEN 'High'
            WHEN sa.total_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_level
    FROM sales_agg sa
    JOIN item i ON sa.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON sa.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON sa.ws_promo_sk = p.p_promo_sk
    WHERE i.i_class = 'swimwear'
      AND p.p_channel_catalog = 'Y'
      AND i.i_manager_id IN (4, 18, 25)
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
),
distinct_categories AS (
    SELECT DISTINCT i_category
    FROM item
    WHERE i_class = 'swimwear'
)
SELECT
    jd.i_item_id,
    jd.i_product_name,
    jd.i_category,
    jd.wp_type,
    jd.p_promo_name,
    jd.total_sales,
    jd.total_qty,
    jd.total_profit,
    jd.profit_level,
    ROW_NUMBER() OVER (PARTITION BY jd.i_category ORDER BY jd.total_profit DESC) AS profit_rank_in_category,
    DENSE_RANK() OVER (ORDER BY jd.total_sales DESC) AS sales_dense_rank
FROM joined_data jd
JOIN distinct_categories dc ON jd.i_category = dc.i_category
WHERE jd.total_sales > 0
GROUP BY
    jd.i_item_id,
    jd.i_product_name,
    jd.i_category,
    jd.wp_type,
    jd.p_promo_name,
    jd.total_sales,
    jd.total_qty,
    jd.total_profit,
    jd.profit_level
HAVING SUM(jd.total_sales) > 10000
ORDER BY jd.total_profit DESC
LIMIT 100
