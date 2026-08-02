WITH ss_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        d.d_year,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_net_paid) AS store_net_paid,
        COUNT(*) AS store_sales_cnt,
        MIN(t.t_hour) AS min_sold_hour,
        MAX(t.t_hour) AS max_sold_hour
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    GROUP BY ss.ss_item_sk, d.d_year
),

promo_agg AS (
    SELECT
        p.p_item_sk AS item_sk,
        d.d_year,
        COUNT(*) AS promo_cnt,
        MAX(p.p_discount_active) AS any_discount_active,
        MIN(p.p_promo_name) AS any_promo_name
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    GROUP BY p.p_item_sk, d.d_year
),

cs_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        d.d_year,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_ext_sales_price
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_item_sk, d.d_year
),

cr_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        d.d_year,
        SUM(cr.cr_return_quantity) AS return_quantity,
        SUM(cr.cr_net_loss) AS return_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_item_sk, d.d_year
),

ws_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        d.d_year,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_ext_sales_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_item_sk, d.d_year
),

inv_agg AS (
    SELECT
        inv.inv_item_sk AS item_sk,
        d.d_year,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    GROUP BY inv.inv_item_sk, d.d_year
),

call_center_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        d_cc.d_year,
        MAX(cc.cc_county) AS any_cc_county
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc ON cc.cc_open_date_sk = d_cc.d_date_sk
    GROUP BY cs.cs_item_sk, d_cc.d_year
),

catalog_page_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        d_cp.d_year,
        MAX(cp.cp_catalog_page_number) AS max_catalog_page_number
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp ON cp.cp_start_date_sk = d_cp.d_date_sk
    GROUP BY cs.cs_item_sk, d_cp.d_year
),

ship_mode_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        d_sm.d_year,
        MAX(sm.sm_type) AS any_ship_mode_type,
        COUNT(DISTINCT cs.cs_ship_mode_sk) AS distinct_ship_modes
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_sm ON cs.cs_ship_date_sk = d_sm.d_date_sk
    GROUP BY cs.cs_item_sk, d_sm.d_year
),

full_sp AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        p.p_item_sk,
        p.p_discount_active,
        COALESCE(d_ss.d_year, d_p.d_year) AS d_year
    FROM store_sales ss
    FULL OUTER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN date_dim d_p ON p.p_start_date_sk = d_p.d_date_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    ss.d_year,
    COALESCE(ss.store_quantity, 0) AS store_quantity,
    COALESCE(cs.catalog_quantity, 0) AS catalog_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(inv.total_on_hand, 0) AS total_on_hand,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(cr.return_net_loss, 0)) AS total_net_profit,
    RANK() OVER (PARTITION BY ss.d_year ORDER BY (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(cr.return_net_loss, 0)) DESC) AS profit_rank,
    CASE
        WHEN COALESCE(ss.store_quantity, 0) > 0 AND COALESCE(cs.catalog_quantity, 0) > 0 THEN 'Store & Catalog'
        WHEN COALESCE(ws.web_quantity, 0) > 0 THEN 'Web Only'
        ELSE 'Other'
    END AS sales_channel_flag,
    pr.any_discount_active,
    ccag.any_cc_county,
    cpag.max_catalog_page_number,
    smag.any_ship_mode_type
FROM item i
LEFT JOIN ss_agg ss ON i.i_item_sk = ss.item_sk
LEFT JOIN cs_agg cs ON i.i_item_sk = cs.item_sk AND cs.d_year = ss.d_year
LEFT JOIN ws_agg ws ON i.i_item_sk = ws.item_sk AND ws.d_year = ss.d_year
LEFT JOIN cr_agg cr ON i.i_item_sk = cr.item_sk AND cr.d_year = ss.d_year
LEFT JOIN inv_agg inv ON i.i_item_sk = inv.item_sk AND inv.d_year = ss.d_year
LEFT JOIN promo_agg pr ON i.i_item_sk = pr.item_sk AND pr.d_year = ss.d_year
LEFT JOIN call_center_agg ccag ON i.i_item_sk = ccag.item_sk AND ccag.d_year = ss.d_year
LEFT JOIN catalog_page_agg cpag ON i.i_item_sk = cpag.item_sk AND cpag.d_year = ss.d_year
LEFT JOIN ship_mode_agg smag ON i.i_item_sk = smag.item_sk AND smag.d_year = ss.d_year
LEFT JOIN full_sp fs_ss ON i.i_item_sk = fs_ss.ss_item_sk AND fs_ss.d_year = ss.d_year
LEFT JOIN full_sp fs_p ON i.i_item_sk = fs_p.p_item_sk AND fs_p.d_year = ss.d_year
WHERE
    i.i_category = 'Sports'
    AND i.i_brand = 'Brand#12'
    AND ss.d_year = 2002
    AND COALESCE(ss.store_quantity, 0) > 5
    AND COALESCE(cs.catalog_net_profit, 0) > 1000
    AND pr.any_discount_active = 'Y'
    AND ccag.any_cc_county = 'Jackson County'
    AND smag.any_ship_mode_type = 'AIR'
ORDER BY
    total_net_profit DESC,
    profit_rank,
    i.i_item_id
LIMIT 100
