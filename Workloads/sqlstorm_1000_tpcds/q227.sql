WITH sales_union AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk AS item_sk,
        ss_store_sk AS store_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        CAST(NULL AS INTEGER) AS web_site_sk,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        CAST(NULL AS INTEGER),
        cs_call_center_sk,
        CAST(NULL AS INTEGER),
        cs_quantity,
        cs_net_paid,
        cs_net_profit
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        CAST(NULL AS INTEGER),
        CAST(NULL AS INTEGER),
        ws_web_site_sk,
        ws_quantity,
        ws_net_paid,
        ws_net_profit
    FROM web_sales
),
sales_with_date AS (
    SELECT
        su.*,
        d.d_year,
        d.d_date
    FROM sales_union su
    LEFT JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
),
item_sales AS (
    SELECT
        swd.d_year,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        SUM(swd.net_profit) AS total_profit,
        SUM(swd.net_paid) AS total_paid,
        COUNT(*) AS transaction_count,
        SUM(swd.quantity) AS total_quantity
    FROM sales_with_date swd
    JOIN item i ON swd.item_sk = i.i_item_sk
    GROUP BY swd.d_year, i.i_item_id, i.i_product_name, i.i_category, i.i_brand
),
top_items AS (
    SELECT
        d_year,
        i_item_id,
        i_product_name,
        i_category,
        i_brand,
        total_profit,
        total_paid,
        transaction_count,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rn
    FROM item_sales
),
store_channel_stats AS (
    SELECT
        swd.d_year,
        s.s_store_name,
        i.i_category,
        SUM(swd.net_profit) AS store_profit,
        AVG(swd.net_paid) AS avg_net_paid,
        COUNT(DISTINCT swd.store_sk) AS store_count
    FROM sales_with_date swd
    JOIN store s ON swd.store_sk = s.s_store_sk
    JOIN item i ON swd.item_sk = i.i_item_sk
    WHERE swd.store_sk IS NOT NULL
    GROUP BY swd.d_year, s.s_store_name, i.i_category
),
call_center_stats AS (
    SELECT
        swd.d_year,
        cc.cc_name,
        i.i_brand,
        SUM(swd.net_profit) AS cc_profit,
        AVG(swd.net_paid) AS avg_cc_paid,
        COUNT(DISTINCT swd.call_center_sk) AS cc_count
    FROM sales_with_date swd
    JOIN call_center cc ON swd.call_center_sk = cc.cc_call_center_sk
    JOIN item i ON swd.item_sk = i.i_item_sk
    WHERE swd.call_center_sk IS NOT NULL
    GROUP BY swd.d_year, cc.cc_name, i.i_brand
),
web_site_stats AS (
    SELECT
        swd.d_year,
        ws.web_name,
        i.i_category,
        SUM(swd.net_profit) AS web_profit,
        AVG(swd.net_paid) AS avg_web_paid,
        COUNT(DISTINCT swd.web_site_sk) AS site_count
    FROM sales_with_date swd
    JOIN web_site ws ON swd.web_site_sk = ws.web_site_sk
    JOIN item i ON swd.item_sk = i.i_item_sk
    WHERE swd.web_site_sk IS NOT NULL
    GROUP BY swd.d_year, ws.web_name, i.i_category
),
max_store_profit AS (
    SELECT d_year, i_category, MAX(store_profit) AS store_profit
    FROM store_channel_stats
    GROUP BY d_year, i_category
),
max_cc_profit AS (
    SELECT d_year, i_brand, MAX(cc_profit) AS cc_profit
    FROM call_center_stats
    GROUP BY d_year, i_brand
),
max_web_profit AS (
    SELECT d_year, i_category, MAX(web_profit) AS web_profit
    FROM web_site_stats
    GROUP BY d_year, i_category
)
SELECT
    ti.d_year,
    ti.rn AS rank_by_profit,
    ti.i_item_id,
    ti.i_product_name,
    ti.i_category,
    ti.i_brand,
    ti.total_profit,
    ti.total_paid,
    ti.transaction_count,
    ti.total_quantity,
    COALESCE(ms.store_profit, 0) AS top_store_profit,
    COALESCE(mc.cc_profit, 0) AS top_call_center_profit,
    COALESCE(mw.web_profit, 0) AS top_web_site_profit,
    (COALESCE(ms.store_profit, 0) + COALESCE(mc.cc_profit, 0) + COALESCE(mw.web_profit, 0)) / 3.0 AS avg_channel_profit
FROM top_items ti
LEFT JOIN max_store_profit ms
    ON ti.d_year = ms.d_year AND ti.i_category = ms.i_category
LEFT JOIN max_cc_profit mc
    ON ti.d_year = mc.d_year AND ti.i_brand = mc.i_brand
LEFT JOIN max_web_profit mw
    ON ti.d_year = mw.d_year AND ti.i_category = mw.i_category
WHERE ti.rn <= 10
ORDER BY ti.d_year, ti.rn
