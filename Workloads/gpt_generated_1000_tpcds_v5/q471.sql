WITH filtered_sales AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_net_profit AS net_profit,
        cp.cp_department AS department,
        cp.cp_catalog_number AS catalog_number,
        cp.cp_type AS type,
        i.i_color AS color,
        i.i_product_name AS product_name,
        regexp_extract(i.i_product_name, '([A-Za-z]+)', 1) AS product_first_word,
        concat(cp.cp_type, '_', i.i_color) AS type_color
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_product_name, '[A-Z]{2}')
      AND cp.cp_description LIKE '%Special%'
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
)
SELECT
    department,
    catalog_number,
    type,
    color,
    product_first_word,
    type_color,
    COUNT(DISTINCT order_number) AS orders_cnt,
    SUM(net_profit) AS total_profit
FROM filtered_sales
GROUP BY
    department,
    catalog_number,
    type,
    color,
    product_first_word,
    type_color
HAVING SUM(net_profit) > 5000
ORDER BY total_profit DESC
LIMIT 100
