WITH
all_sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           d.d_year AS year,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS qty,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_call_center_sk AS call_center_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk

    UNION ALL

    SELECT ss.ss_item_sk,
           d.d_year,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_quantity,
           NULL AS promo_sk,
           NULL AS call_center_sk,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk

    UNION ALL

    SELECT ws.ws_item_sk,
           d.d_year,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_quantity,
           NULL AS promo_sk,
           NULL AS call_center_sk,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
sales_agg AS (
    SELECT
        item_sk,
        year,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(qty) AS total_qty,
        COUNT(DISTINCT CASE WHEN channel = 'catalog' THEN promo_sk END) AS promo_count,
        MAX(promo_sk) FILTER (WHERE channel = 'catalog') AS any_promo_sk,
        COUNT(DISTINCT CASE WHEN channel = 'catalog' THEN call_center_sk END) AS distinct_cc_count,
        MAX(call_center_sk) FILTER (WHERE channel = 'catalog') AS any_cc_sk
    FROM all_sales
    GROUP BY item_sk, year
),
item_info AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_brand,
           i.i_color,
           i.i_size
    FROM item i
),
returns_agg AS (
    SELECT i.i_item_sk,
           SUM(cr.cr_return_amount) AS catalog_returns,
           SUM(sr.sr_return_amt) AS store_returns,
           SUM(wr.wr_return_amt) AS web_returns
    FROM item i
    LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
    GROUP BY i.i_item_sk
),
promo_details AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           p.p_discount_active,
           p.p_channel_tv,
           p.p_channel_email,
           p.p_channel_catalog,
           p.p_channel_radio
    FROM promotion p
),
item_past_profit AS (
    SELECT s.item_sk,
           s.year,
           (SELECT AVG(prev.cs_net_profit / NULLIF(prev.cs_quantity, 0))
            FROM catalog_sales prev
            JOIN date_dim dprev ON prev.cs_sold_date_sk = dprev.d_date_sk
            WHERE prev.cs_item_sk = s.item_sk
              AND dprev.d_year BETWEEN s.year - 3 AND s.year - 1) AS avg_past_3yr_profit_per_unit
    FROM sales_agg s
),
high_profit_items AS (
    SELECT item_sk
    FROM sales_agg
    WHERE total_net_profit > 100000
),
brand_items AS (
    SELECT i_item_sk AS item_sk
    FROM item
    WHERE i_brand = 'Brand#23'
),
target_items AS (
    SELECT item_sk FROM high_profit_items
    INTERSECT
    SELECT item_sk FROM brand_items
),
final AS (
    SELECT
        ii.i_item_sk,
        ii.i_product_name,
        ii.i_brand,
        ii.i_color,
        ii.i_size,
        sa.year,
        sa.total_net_paid,
        sa.total_net_profit,
        sa.total_qty,
        COALESCE(ra.catalog_returns,0) AS catalog_returns,
        COALESCE(ra.store_returns,0) AS store_returns,
        COALESCE(ra.web_returns,0) AS web_returns,
        (COALESCE(ra.catalog_returns,0) + COALESCE(ra.store_returns,0) + COALESCE(ra.web_returns,0)) AS total_returns,
        CASE WHEN sa.total_qty = 0 THEN NULL ELSE sa.total_net_profit / sa.total_qty END AS profit_per_unit,
        ip.avg_past_3yr_profit_per_unit,
        ROW_NUMBER() OVER (PARTITION BY sa.year ORDER BY sa.total_net_profit DESC) AS profit_rank,
        COALESCE(pd.p_promo_name, 'No Promo') AS promo_name,
        CASE WHEN (COALESCE(ra.catalog_returns,0) + COALESCE(ra.store_returns,0) + COALESCE(ra.web_returns,0)) > 0.1 * sa.total_net_paid THEN TRUE ELSE FALSE END AS high_return_flag,
        CASE
            WHEN ii.i_product_name IS NULL THEN 'UNKNOWN'
            WHEN ii.i_product_name LIKE '%SPECIAL%' THEN 'Special'
            WHEN ii.i_product_name LIKE '%A%' AND ii.i_product_name NOT LIKE '%Z%' THEN 'Contains A not Z'
            ELSE 'Other'
        END AS name_category,
        CONCAT_WS(' | ', ii.i_brand, ii.i_color, ii.i_size) AS item_descriptor,
        REGEXP_REPLACE(COALESCE(ii.i_product_name, ''), '[^A-Za-z0-9 ]', '') AS product_name_alpha,
        CASE WHEN NULLIF(sa.total_net_paid,0) IS NULL THEN NULL ELSE (COALESCE(ra.catalog_returns,0) + COALESCE(ra.store_returns,0) + COALESCE(ra.web_returns,0)) / NULLIF(sa.total_net_paid,0) END AS return_rate,
        cc.cc_gmt_offset,
        CASE WHEN EXISTS (
                SELECT 1
                FROM promotion p
                WHERE p.p_promo_sk = sa.any_promo_sk
                  AND p.p_discount_active = 'Y'
                  AND p.p_channel_tv = 'Y'
                ) THEN TRUE ELSE FALSE END AS promo_tv_active,
        CONCAT('Item:', CAST(ii.i_item_sk AS VARCHAR), ' - ', SUBSTRING(ii.i_product_name, 1, 10)) AS short_desc
    FROM sales_agg sa
    JOIN item_info ii ON sa.item_sk = ii.i_item_sk
    LEFT JOIN returns_agg ra ON ii.i_item_sk = ra.i_item_sk
    LEFT JOIN item_past_profit ip ON sa.item_sk = ip.item_sk AND sa.year = ip.year
    LEFT JOIN promo_details pd ON sa.any_promo_sk = pd.p_promo_sk
    LEFT JOIN call_center cc ON sa.any_cc_sk = cc.cc_call_center_sk
    WHERE sa.total_net_paid > 0
      AND (COALESCE(ra.catalog_returns,0) + COALESCE(ra.store_returns,0) + COALESCE(ra.web_returns,0)) < sa.total_net_paid * 0.05
      AND ii.i_product_name IS NOT NULL
      AND ii.i_product_name NOT LIKE 'X%'
      AND EXISTS (SELECT 1 FROM target_items ti WHERE ti.item_sk = ii.i_item_sk)
)
SELECT *
FROM final
WHERE profit_rank <= 10
ORDER BY year DESC, profit_rank
LIMIT 200
