WITH filtered_dates AS (
    SELECT d_date_sk, d_year, d_date
    FROM date_dim
    WHERE d_year = 2001
)
SELECT DISTINCT
    d.d_date,
    'Catalog' AS sales_channel,
    i.i_item_id,
    i.i_product_name,
    cs.cs_ext_sales_price AS total_sales,
    cs.cs_net_profit AS profit,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    (SELECT i_current_price FROM item WHERE i_item_sk = cs.cs_item_sk) AS current_price
FROM catalog_sales cs
JOIN filtered_dates d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
  AND i.i_brand = 'Brand#23'
  AND cs.cs_ext_sales_price > 1000
UNION ALL
SELECT DISTINCT
    d.d_date,
    'Web' AS sales_channel,
    i.i_item_id,
    i.i_product_name,
    ws.ws_ext_sales_price AS total_sales,
    ws.ws_net_profit AS profit,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    (SELECT i_current_price FROM item WHERE i_item_sk = ws.ws_item_sk) AS current_price
FROM web_sales ws
JOIN filtered_dates d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = ws.ws_promo_sk
          AND p2.p_discount_active = 'Y'
    )
  AND i.i_category = 'Electronics'
  AND ws.ws_ext_sales_price > 500
ORDER BY sales_channel, total_sales DESC
LIMIT 100
