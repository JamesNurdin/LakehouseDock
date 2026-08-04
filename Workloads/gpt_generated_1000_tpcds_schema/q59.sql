/* goal: Identify warehouses and brand‑category combinations that sold products containing the word ‘Phone’ both in catalog and web channels, showing sales performance and a shortened product name prefix. */
(
    SELECT
        w.w_warehouse_name      AS warehouse_name,
        i.i_brand               AS brand,
        i.i_category            AS category,
        CONCAT(i.i_brand, '_', i.i_category) AS brand_category,
        MAX(SUBSTRING(i.i_product_name, 1, 10)) AS prod_name_prefix,
        SUM(cs.cs_ext_sales_price)          AS total_sales,
        SUM(cs.cs_net_profit)               AS total_profit,
        COUNT(DISTINCT cs.cs_order_number)  AS order_cnt
    FROM catalog_sales cs
    JOIN item i          ON cs.cs_item_sk   = i.i_item_sk
    JOIN warehouse w     ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p     ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t      ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_product_name, '(?i)Phone')
      AND p.p_channel_email = 'Y'
    GROUP BY w.w_warehouse_name, i.i_brand, i.i_category
)
INTERSECT
(
    SELECT
        w.w_warehouse_name      AS warehouse_name,
        i.i_brand               AS brand,
        i.i_category            AS category,
        CONCAT(i.i_brand, '_', i.i_category) AS brand_category,
        MAX(SUBSTRING(i.i_product_name, 1, 10)) AS prod_name_prefix,
        SUM(ws.ws_ext_sales_price)         AS total_sales,
        SUM(ws.ws_net_profit)              AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN item i          ON ws.ws_item_sk   = i.i_item_sk
    JOIN warehouse w     ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p     ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t      ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE i.i_product_name LIKE '%Phone%'
      AND p.p_channel_email = 'Y'
    GROUP BY w.w_warehouse_name, i.i_brand, i.i_category
)
ORDER BY total_sales DESC
LIMIT 100
