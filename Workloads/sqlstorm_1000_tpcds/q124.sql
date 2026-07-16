WITH
    sales_union AS (
        SELECT
            ss.ss_sold_date_sk AS sold_date_sk,
            ss.ss_net_profit AS net_profit,
            ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
            ss.ss_quantity AS quantity,
            ss.ss_item_sk AS item_sk,
            ss.ss_store_sk AS store_sk,
            CAST(NULL AS INTEGER) AS call_center_sk,
            CAST(NULL AS INTEGER) AS catalog_page_sk,
            CAST(NULL AS INTEGER) AS web_page_sk,
            ss.ss_promo_sk AS promo_sk,
            'store' AS src
        FROM store_sales ss
        UNION ALL
        SELECT
            cs.cs_sold_date_sk AS sold_date_sk,
            cs.cs_net_profit AS net_profit,
            cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
            cs.cs_quantity AS quantity,
            cs.cs_item_sk AS item_sk,
            CAST(NULL AS INTEGER) AS store_sk,
            cs.cs_call_center_sk AS call_center_sk,
            cs.cs_catalog_page_sk AS catalog_page_sk,
            CAST(NULL AS INTEGER) AS web_page_sk,
            cs.cs_promo_sk AS promo_sk,
            'catalog' AS src
        FROM catalog_sales cs
        UNION ALL
        SELECT
            ws.ws_sold_date_sk AS sold_date_sk,
            ws.ws_net_profit AS net_profit,
            ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
            ws.ws_quantity AS quantity,
            ws.ws_item_sk AS item_sk,
            CAST(NULL AS INTEGER) AS store_sk,
            CAST(NULL AS INTEGER) AS call_center_sk,
            CAST(NULL AS INTEGER) AS catalog_page_sk,
            ws.ws_web_page_sk AS web_page_sk,
            ws.ws_promo_sk AS promo_sk,
            'web' AS src
        FROM web_sales ws
    ),
    aggregated AS (
        SELECT
            su.item_sk,
            su.store_sk,
            su.call_center_sk,
            su.catalog_page_sk,
            su.web_page_sk,
            su.src,
            SUM(su.quantity) AS total_qty,
            SUM(su.net_profit) AS total_net_profit,
            SUM(su.net_paid_inc_tax) AS total_net_paid_inc_tax,
            MAX(su.sold_date_sk) AS max_sold_date_sk
        FROM sales_union su
        GROUP BY
            su.item_sk,
            su.store_sk,
            su.call_center_sk,
            su.catalog_page_sk,
            su.web_page_sk,
            su.src
    ),
    with_item AS (
        SELECT
            a.*,
            i.i_product_name,
            i.i_color,
            i.i_size,
            i.i_units,
            i.i_brand,
            i.i_category,
            i.i_manager_id,
            CASE WHEN i.i_color IS NULL THEN 'UNKNOWN_COLOR' ELSE i.i_color END AS color_norm
        FROM aggregated a
        LEFT JOIN item i ON a.item_sk = i.i_item_sk
    ),
    with_dates AS (
        SELECT
            wi.*,
            d.d_date AS sold_date,
            d.d_year,
            d.d_month_seq,
            d.d_day_name
        FROM with_item wi
        LEFT JOIN date_dim d ON wi.max_sold_date_sk = d.d_date_sk
    ),
    flagged AS (
        SELECT
            wd.*,
            CASE
                WHEN wd.total_net_paid_inc_tax = 0 THEN NULL
                ELSE wd.total_net_profit / wd.total_net_paid_inc_tax
            END AS profit_margin,
            ROW_NUMBER() OVER (PARTITION BY wd.store_sk ORDER BY wd.total_net_profit DESC) AS profit_rank,
            EXISTS (
                SELECT 1 FROM catalog_returns cr
                WHERE cr.cr_item_sk = wd.item_sk AND cr.cr_return_quantity > 0
            ) AS was_returned_in_catalog,
            COALESCE(wd.store_sk, -1) AS store_key,
            COALESCE(wd.call_center_sk, -1) AS call_center_key,
            COALESCE(wd.catalog_page_sk, -1) AS catalog_page_key,
            COALESCE(wd.web_page_sk, -1) AS web_page_key
        FROM with_dates wd
    ),
    join_all AS (
        SELECT
            f.*,
            s.s_store_name,
            s.s_city,
            s.s_state,
            cc.cc_name,
            cc.cc_manager,
            cp.cp_description,
            wp.wp_url,
            CASE
                WHEN f.profit_margin IS NULL THEN 'N/A'
                WHEN f.profit_margin > 0.25 THEN 'HIGH'
                WHEN f.profit_margin > 0.10 THEN 'MEDIUM'
                ELSE 'LOW'
            END AS profit_category,
            CONCAT(COALESCE(s.s_store_name, 'UNKNOWN_STORE'), ' | ', COALESCE(f.i_product_name, 'UNKNOWN_PRODUCT')) AS full_label,
            NULLIF(f.total_qty, 0) / NULLIF(f.total_net_profit, 0) AS qty_per_profit,
            REGEXP_REPLACE(COALESCE(f.i_product_name, ''), '[^A-Za-z0-9 ]', '') AS clean_product_name
        FROM flagged f
        LEFT JOIN store s ON f.store_sk = s.s_store_sk
        LEFT JOIN call_center cc ON f.call_center_sk = cc.cc_call_center_sk
        LEFT JOIN catalog_page cp ON f.catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN web_page wp ON f.web_page_sk = wp.wp_web_page_sk
    )
SELECT
    ja.store_key,
    ja.s_store_name,
    ja.item_sk,
    ja.i_product_name,
    ja.full_label,
    ja.total_qty,
    ja.total_net_profit,
    ja.profit_margin,
    ja.profit_category,
    ja.profit_rank,
    ja.sold_date,
    ja.was_returned_in_catalog,
    ja.clean_product_name,
    CASE
        WHEN ja.color_norm = 'R' THEN 'RED FLAG'
        WHEN ja.color_norm = 'B' THEN 'BLUE FLAG'
        ELSE 'NO FLAG'
    END AS color_flag,
    (COALESCE(ja.profit_margin, 0) + 1) * CASE WHEN ja.was_returned_in_catalog THEN 2 ELSE 1 END AS adjusted_metric
FROM join_all ja
WHERE ja.profit_rank <= 10
   OR (ja.store_key = -1 AND ja.profit_rank <= 5)
ORDER BY ja.store_key ASC NULLS FIRST, ja.profit_rank ASC
