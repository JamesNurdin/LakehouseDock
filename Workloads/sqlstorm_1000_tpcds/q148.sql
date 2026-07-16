WITH unified_sales AS (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_item_sk AS item_sk,
           cs_call_center_sk AS call_center_sk,
           CAST(NULL AS integer) AS store_sk,
           CAST(NULL AS integer) AS web_page_sk,
           cs_quantity AS quantity,
           cs_net_paid AS net_paid,
           cs_ext_discount_amt AS discount_amt,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           CAST(NULL AS integer),
           ss_store_sk,
           CAST(NULL AS integer),
           ss_quantity,
           ss_net_paid,
           ss_ext_discount_amt,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           CAST(NULL AS integer),
           CAST(NULL AS integer),
           ws_web_page_sk,
           ws_quantity,
           ws_net_paid,
           ws_ext_discount_amt,
           'web'
    FROM web_sales
),
sales_with_dims AS (
    SELECT us.*,
           d.d_date,
           d.d_year,
           i.i_product_name,
           i.i_brand,
           i.i_color,
           i.i_current_price,
           COALESCE(cc.cc_name, s.s_store_name, wp.wp_url) AS location_name,
           COALESCE(inv.inv_quantity_on_hand, 0) AS inventory_on_hand,
           CONCAT(i.i_brand, ' ', i.i_product_name, ' - ', i.i_color) AS product_label,
           CASE 
               WHEN us.discount_amt > 0 THEN 'Discounted'
               ELSE 'Full Price'
           END AS price_type,
           COALESCE(p.p_promo_name, 'No Promo') AS promo_name
    FROM unified_sales us
    LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON us.item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON us.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store s ON us.store_sk = s.s_store_sk
    LEFT JOIN web_page wp ON us.web_page_sk = wp.wp_web_page_sk
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN (
        SELECT inv_item_sk AS item_sk, MAX(inv_date_sk) AS max_date_sk
        FROM inventory
        GROUP BY inv_item_sk
    ) latest_inv ON us.item_sk = latest_inv.item_sk
    LEFT JOIN inventory inv ON us.item_sk = inv.inv_item_sk AND latest_inv.max_date_sk = inv.inv_date_sk
    WHERE d.d_year = 2001
),
sales_aggregated AS (
    SELECT *,
           SUM(net_paid) OVER (PARTITION BY item_sk ORDER BY d_date ROWS UNBOUNDED PRECEDING) AS cumulative_net_paid,
           AVG(net_paid) OVER (PARTITION BY item_sk ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d_net_paid,
           ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY net_paid DESC) AS daily_sales_rank
    FROM sales_with_dims
),
sales_without_returns AS (
    SELECT sa.*
    FROM sales_aggregated sa
    LEFT JOIN (
        SELECT cr_item_sk AS item_sk FROM catalog_returns
        UNION
        SELECT sr_item_sk FROM store_returns
        UNION
        SELECT wr_item_sk FROM web_returns
    ) r ON sa.item_sk = r.item_sk
    WHERE r.item_sk IS NULL
)
SELECT 
    swr.d_date,
    swr.product_label,
    swr.channel,
    swr.quantity,
    swr.net_paid,
    swr.cumulative_net_paid,
    swr.moving_avg_7d_net_paid,
    swr.daily_sales_rank,
    swr.inventory_on_hand,
    swr.price_type,
    swr.promo_name,
    swr.location_name,
    (SELECT AVG(swd2.discount_amt) FROM sales_with_dims swd2 WHERE swd2.item_sk = swr.item_sk AND swd2.d_date <= swr.d_date) AS avg_discount_to_date
FROM sales_without_returns swr
WHERE swr.daily_sales_rank <= 10
ORDER BY swr.d_date DESC, swr.daily_sales_rank
