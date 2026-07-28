WITH catalog_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, i.i_category
),
sales_union AS (
    SELECT i_item_id, i_category, total_sales, total_profit, orders_cnt, 'catalog' AS source
    FROM catalog_agg
    UNION ALL
    SELECT i_item_id, i_category, total_sales, total_profit, orders_cnt, 'web' AS source
    FROM web_agg
)
SELECT
    su.i_item_id,
    su.i_category,
    su.total_sales,
    su.total_profit,
    su.orders_cnt,
    su.source,
    RANK() OVER (PARTITION BY su.i_category ORDER BY su.total_sales DESC) AS sales_rank,
    (SELECT AVG(su2.total_profit) FROM sales_union su2 WHERE su2.i_category = su.i_category) AS avg_category_profit
FROM sales_union su
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i_ret ON sr.sr_item_sk = i_ret.i_item_sk
    WHERE d_ret.d_year = 2001
      AND i_ret.i_item_id = su.i_item_id
)
ORDER BY su.i_category, sales_rank
LIMIT 100
