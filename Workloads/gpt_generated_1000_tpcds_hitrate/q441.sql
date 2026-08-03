WITH agg_inventory AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    d.d_year AS sales_year,
    i.i_category AS item_category,
    p.p_promo_name AS promo_name,
    CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_mode_type,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    (
        SELECT SUM(ai.total_on_hand)
        FROM agg_inventory ai
        WHERE ai.inv_item_sk = i.i_item_sk
          AND ai.inv_date_sk = d.d_date_sk
    ) AS inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY (
        SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price)
    ) DESC) AS category_rank,
    ROW_NUMBER() OVER (ORDER BY (
        SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price)
    ) DESC) AS overall_rank
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
WHERE d.d_year = 2001
  AND i.i_brand_id = 20
  AND hd.hd_income_band_sk IN (3, 4, 12)
  AND sm.sm_contract LIKE 'O9V6oF8RJnLMmZYd1%'
GROUP BY
    d.d_year,
    i.i_category,
    p.p_promo_name,
    sm.sm_code,
    i.i_item_sk,
    d.d_date_sk
ORDER BY catalog_sales_amount DESC
LIMIT 100
