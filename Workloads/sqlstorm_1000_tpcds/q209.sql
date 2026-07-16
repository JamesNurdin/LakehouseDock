WITH date_range AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2001
),
store_agg AS (
    SELECT 
        dr.d_date_sk,
        dr.d_date,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_qty,
        COUNT(DISTINCT ss.ss_store_sk) AS store_cnt
    FROM date_range dr
    JOIN store_sales ss ON ss.ss_sold_date_sk = dr.d_date_sk
    JOIN item i ON i.i_item_sk = ss.ss_item_sk
    GROUP BY dr.d_date_sk, dr.d_date, i.i_item_sk, i.i_item_id, i.i_product_name
),
web_agg AS (
    SELECT 
        dr.d_date_sk,
        dr.d_date,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_qty,
        COUNT(DISTINCT ws.ws_web_page_sk) AS web_pages
    FROM date_range dr
    JOIN web_sales ws ON ws.ws_sold_date_sk = dr.d_date_sk
    JOIN item i ON i.i_item_sk = ws.ws_item_sk
    GROUP BY dr.d_date_sk, dr.d_date, i.i_item_sk, i.i_item_id, i.i_product_name
),
catalog_agg AS (
    SELECT 
        dr.d_date_sk,
        dr.d_date,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_qty,
        COUNT(DISTINCT cs.cs_catalog_page_sk) AS catalog_pages
    FROM date_range dr
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = dr.d_date_sk
    JOIN item i ON i.i_item_sk = cs.cs_item_sk
    GROUP BY dr.d_date_sk, dr.d_date, i.i_item_sk, i.i_item_id, i.i_product_name
),
combined AS (
    SELECT 
        COALESCE(s.d_date_sk, w.d_date_sk, c.d_date_sk) AS d_date_sk,
        COALESCE(s.d_date, w.d_date, c.d_date) AS d_date,
        COALESCE(s.i_item_sk, w.i_item_sk, c.i_item_sk) AS i_item_sk,
        COALESCE(s.i_item_id, w.i_item_id, c.i_item_id) AS i_item_id,
        COALESCE(s.i_product_name, w.i_product_name, c.i_product_name) AS i_product_name,
        s.store_net_profit,
        w.web_net_profit,
        c.catalog_net_profit,
        s.store_qty,
        w.web_qty,
        c.catalog_qty,
        s.store_cnt,
        w.web_pages,
        c.catalog_pages
    FROM store_agg s
    FULL OUTER JOIN web_agg w
        ON s.d_date_sk = w.d_date_sk AND s.i_item_sk = w.i_item_sk
    FULL OUTER JOIN catalog_agg c
        ON COALESCE(s.d_date_sk, w.d_date_sk) = c.d_date_sk
        AND COALESCE(s.i_item_sk, w.i_item_sk) = c.i_item_sk
),
profit_stats_base AS (
    SELECT
        d_date,
        i_item_id,
        i_product_name,
        COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0) AS total_net_profit,
        COALESCE(store_qty, 0) + COALESCE(web_qty, 0) + COALESCE(catalog_qty, 0) AS total_quantity,
        COALESCE(store_cnt, 0) + COALESCE(web_pages, 0) + COALESCE(catalog_pages, 0) AS total_channels,
        CONCAT(i_product_name, ' (', i_item_id, ')') AS item_desc,
        i_item_sk,
        (store_net_profit IS NOT DISTINCT FROM web_net_profit) AS store_eq_web,
        CASE WHEN REGEXP_LIKE(i_product_name, '(?i)special|limited') THEN 'Special' ELSE 'Regular' END AS product_category,
        REVERSE(i_item_id) AS rev_item_id
    FROM combined
    WHERE (COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0) > 0
           OR (COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0)) IS NULL)
      AND (COALESCE(store_qty, 0) + COALESCE(web_qty, 0) + COALESCE(catalog_qty, 0) > 0
           OR (COALESCE(store_qty, 0) + COALESCE(web_qty, 0) + COALESCE(catalog_qty, 0)) IS NULL)
      AND (store_net_profit IS NOT DISTINCT FROM web_net_profit)
),
profit_stats_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY total_net_profit DESC) AS profit_rank,
        total_net_profit / NULLIF(total_channels, 0) AS avg_profit_per_channel,
        (SELECT AVG(p2.total_net_profit)
         FROM profit_stats_base p2
         WHERE p2.i_item_sk = p1.i_item_sk) AS overall_avg_profit
    FROM profit_stats_base p1
),
exclude_low_profit AS (
    SELECT *
    FROM profit_stats_ranked
    WHERE NOT (avg_profit_per_channel < 0.01 AND total_net_profit < 100)
),
final_set AS (
    SELECT
        d_date,
        item_desc,
        total_net_profit,
        total_quantity,
        avg_profit_per_channel,
        profit_rank,
        CASE WHEN profit_rank = 1 THEN 'TOP' ELSE NULL END AS top_flag,
        product_category,
        rev_item_id
    FROM exclude_low_profit
    UNION ALL
    SELECT
        dr.d_date,
        'UNKNOWN ITEM',
        0.0,
        0,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    FROM (SELECT DISTINCT d_date FROM date_range) dr
    WHERE NOT EXISTS (SELECT 1 FROM exclude_low_profit e WHERE e.d_date = dr.d_date)
)
SELECT *
FROM final_set
WHERE d_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
ORDER BY d_date DESC, total_net_profit DESC NULLS LAST
LIMIT 100
