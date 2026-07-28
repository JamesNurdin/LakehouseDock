WITH avg_discount AS (
    SELECT
        AVG(cs.cs_ext_discount_amt) AS cat_avg_discount,
        (SELECT AVG(ws.ws_ext_discount_amt) FROM web_sales ws) AS web_avg_discount
    FROM catalog_sales cs
),
filtered_items AS (
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name
    FROM item i
    WHERE i.i_current_price > 0
)
SELECT
    'CATALOG' AS channel,
    fi.i_item_id,
    fi.i_product_name,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_status,
    (SELECT cat_avg_discount FROM avg_discount) AS avg_discount_overall
FROM catalog_sales cs
JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = cs.cs_promo_sk
          AND p.p_discount_active = 'Y'
    )
GROUP BY fi.i_item_id, fi.i_product_name

UNION ALL

SELECT
    'WEB' AS channel,
    fi.i_item_id,
    fi.i_product_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_status,
    (SELECT web_avg_discount FROM avg_discount) AS avg_discount_overall
FROM web_sales ws
JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ws.ws_promo_sk
          AND p.p_discount_active = 'Y'
    )
GROUP BY fi.i_item_id, fi.i_product_name

ORDER BY total_sales DESC
LIMIT 100
