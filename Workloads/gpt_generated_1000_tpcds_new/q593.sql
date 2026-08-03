/*
Goal: Summarize combined net profit and distinct item keys by department, category, promotion, carrier, warehouse, store and website for items that appear in both high‑value catalog and store sales but are excluded from a set of web sales. This query exercises deep joins across all fifteen selected TPC‑DS tables, uses table aliases, CASE, UNNEST, INTERSECT, EXCEPT and aggregation.
*/
WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cp.cp_department,
        hd_bill.hd_income_band_sk,
        ib.ib_lower_bound,
        i.i_category,
        p.p_promo_name,
        sm.sm_carrier,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        ss.ss_store_sk,
        s.s_store_name,
        sr.sr_return_quantity,
        ws.ws_web_site_sk,
        we.web_name,
        ARRAY[cs.cs_item_sk, ss.ss_item_sk, ws.ws_item_sk] AS item_key_array,
        cs.cs_net_profit,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                         AND sr.sr_store_sk = s.s_store_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
),
unnested AS (
    SELECT
        b.*, 
        u.item_key AS unnested_item_key
    FROM base b
    CROSS JOIN UNNEST(b.item_key_array) AS u(item_key)
),
sub1 AS (
    SELECT cs_item_sk AS item_key FROM catalog_sales WHERE cs_ext_sales_price > 500
),
sub2 AS (
    SELECT ss_item_sk AS item_key FROM store_sales WHERE ss_quantity > 10
),
sub3 AS (
    SELECT ws_item_sk AS item_key FROM web_sales WHERE ws_quantity > 8
)
SELECT
    u.cp_department,
    u.i_category,
    u.p_promo_name,
    u.sm_carrier,
    u.w_warehouse_name,
    u.s_store_name,
    u.web_name,
    COUNT(DISTINCT u.unnested_item_key) AS distinct_item_keys,
    SUM(u.cs_net_profit + u.ss_net_profit + u.ws_net_profit) AS total_combined_net_profit,
    CASE
        WHEN SUM(u.cs_net_profit + u.ss_net_profit + u.ws_net_profit) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_level
FROM unnested u
WHERE u.cs_item_sk IN (
    SELECT item_key FROM sub1
    INTERSECT
    SELECT item_key FROM sub2
    EXCEPT
    SELECT item_key FROM sub3
)
GROUP BY
    u.cp_department,
    u.i_category,
    u.p_promo_name,
    u.sm_carrier,
    u.w_warehouse_name,
    u.s_store_name,
    u.web_name
ORDER BY total_combined_net_profit DESC
LIMIT 100
