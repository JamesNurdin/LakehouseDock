WITH promo_info AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_catalog,
        p.p_channel_email,
        p.p_channel_tv
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
)
SELECT
    'catalog' AS sales_channel,
    cp.cp_department,
    pi.p_promo_name,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS orders
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN promo_info pi ON cs.cs_promo_sk = pi.p_promo_sk
WHERE w.w_county = 'Fairfield County'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY cp.cp_department, pi.p_promo_name

UNION ALL

SELECT
    'web' AS sales_channel,
    CAST(NULL AS varchar) AS cp_department,
    pi.p_promo_name,
    SUM(ws.ws_ext_sales_price) AS total_ext_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS orders
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN promo_info pi ON ws.ws_promo_sk = pi.p_promo_sk
WHERE w.w_county = 'Fairfield County'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY pi.p_promo_name

ORDER BY total_ext_sales DESC
LIMIT 100
