WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_item_sk,
        i.i_item_desc,
        i.i_brand,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt,
        CONCAT(i.i_brand, '-', REGEXP_EXTRACT(i.i_item_desc, '^([^ ]+)', 1)) AS brand_desc_key,
        SUBSTRING(i.i_item_desc FROM 1 FOR 10) AS short_desc
    FROM store_sales AS ss
    JOIN date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store AS s ON ss.ss_store_sk = s.s_store_sk
    JOIN item AS i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(i.i_item_desc, '(?i)phone')
      AND i.i_brand LIKE '%y'
    GROUP BY ss.ss_store_sk, s.s_store_name, ss.ss_item_sk, i.i_item_desc, i.i_brand
)
SELECT
    sa.s_store_name,
    sa.i_item_desc,
    sa.brand_desc_key,
    sa.total_profit,
    sa.avg_discount,
    sa.sales_cnt,
    sa.short_desc,
    (
        SELECT MAX(ws.ws_quantity)
        FROM web_sales ws
        WHERE ws.ws_item_sk = sa.ss_item_sk
    ) AS max_web_quantity
FROM sales_agg AS sa
WHERE NOT EXISTS (
    SELECT 1
    FROM promotion p
    JOIN date_dim d2 ON p.p_start_date_sk = d2.d_date_sk
    WHERE p.p_item_sk = sa.ss_item_sk
      AND d2.d_year = 2001
)
ORDER BY sa.total_profit DESC
LIMIT 100
