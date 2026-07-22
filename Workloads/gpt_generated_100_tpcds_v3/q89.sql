WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_item_desc,
        CONCAT(i.i_brand, ' ', i.i_item_desc) AS full_name
    FROM item i
    WHERE regexp_like(i.i_item_desc, '(?i)blue|red')
      AND i.i_units LIKE '%Pound%'
)
SELECT
    fi.i_category,
    fi.full_name,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_profit,
    CASE
        WHEN SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status
FROM filtered_items fi
LEFT JOIN catalog_sales cs ON cs.cs_item_sk = fi.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = fi.i_item_sk
GROUP BY fi.i_category, fi.full_name
HAVING SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) > 1000
ORDER BY catalog_sales DESC
LIMIT 50
