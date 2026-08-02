/* Goal: Compute total sales and profit per store and hour across store, catalog, and web channels, limited to stores located in California and only active promotions. The query also demonstrates deep joins, table reuse under different aliases, an INTERSECT of store IDs, and a semi‑join via IN. */
WITH
    ss_data AS (
        SELECT
            ss.ss_store_sk AS store_sk,
            td_ss.t_hour,
            ss.ss_ext_sales_price,
            ss.ss_net_profit,
            s.s_store_name,
            s.s_state,
            p_store.p_promo_id
        FROM store_sales ss
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN time_dim td_ss
            ON ss.ss_sold_time_sk = td_ss.t_time_sk
        JOIN promotion p_store
            ON ss.ss_promo_sk = p_store.p_promo_sk
        JOIN promotion p_store_active
            ON ss.ss_promo_sk = p_store_active.p_promo_sk
               AND p_store_active.p_discount_active = 'Y'
        JOIN customer_address ca_ss
            ON ss.ss_addr_sk = ca_ss.ca_address_sk
        JOIN customer_demographics cd_ss
            ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        JOIN household_demographics hd_ss
            ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        JOIN income_band ib_ss
            ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
    ),
    cs_data AS (
        SELECT
            cs.cs_call_center_sk,
            cc.cc_name,
            cp.cp_catalog_page_number,
            sm_cs.sm_type,
            p_cat.p_promo_id,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            td_cs.t_hour,
            hd_bill.hd_income_band_sk,
            ib_cs.ib_lower_bound,
            ib_cs.ib_upper_bound,
            cd_bill.cd_gender AS bill_gender,
            cd_ship.cd_gender AS ship_gender,
            ca_bill.ca_state AS bill_state,
            ca_ship.ca_state AS ship_state
        FROM catalog_sales cs
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm_cs
            ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
        JOIN promotion p_cat
            ON cs.cs_promo_sk = p_cat.p_promo_sk
        JOIN promotion p_cat_active
            ON cs.cs_promo_sk = p_cat_active.p_promo_sk
               AND p_cat_active.p_discount_active = 'Y'
        JOIN household_demographics hd_bill
            ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship
            ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN income_band ib_cs
            ON hd_bill.hd_income_band_sk = ib_cs.ib_income_band_sk
        JOIN customer_address ca_bill
            ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship
            ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN customer_demographics cd_bill
            ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_demographics cd_ship
            ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN time_dim td_cs
            ON cs.cs_sold_time_sk = td_cs.t_time_sk
    ),
    ws_data AS (
        SELECT
            ws.ws_order_number,
            ws.ws_ext_sales_price,
            ws.ws_net_profit,
            td_ws.t_hour,
            sm_ws.sm_type,
            p_web.p_promo_id,
            ca_ws_bill.ca_state AS bill_state,
            cd_ws_bill.cd_gender AS bill_gender,
            hd_ws_bill.hd_income_band_sk AS bill_income_band_sk,
            ib_ws_bill.ib_lower_bound AS bill_lb,
            ib_ws_bill.ib_upper_bound AS bill_ub,
            ca_ws_ship.ca_state AS ship_state,
            cd_ws_ship.cd_gender AS ship_gender,
            hd_ws_ship.hd_income_band_sk AS ship_income_band_sk,
            ib_ws_ship.ib_lower_bound AS ship_lb,
            ib_ws_ship.ib_upper_bound AS ship_ub
        FROM web_sales ws
        JOIN time_dim td_ws
            ON ws.ws_sold_time_sk = td_ws.t_time_sk
        JOIN ship_mode sm_ws
            ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN promotion p_web
            ON ws.ws_promo_sk = p_web.p_promo_sk
        JOIN customer_address ca_ws_bill
            ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
        JOIN customer_demographics cd_ws_bill
            ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
        JOIN household_demographics hd_ws_bill
            ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
        JOIN income_band ib_ws_bill
            ON hd_ws_bill.hd_income_band_sk = ib_ws_bill.ib_income_band_sk
        JOIN customer_address ca_ws_ship
            ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
        JOIN customer_demographics cd_ws_ship
            ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
        JOIN household_demographics hd_ws_ship
            ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
        JOIN income_band ib_ws_ship
            ON hd_ws_ship.hd_income_band_sk = ib_ws_ship.ib_income_band_sk
        WHERE ws.ws_item_sk IN (SELECT cs.cs_item_sk FROM catalog_sales cs)
    ),
    intersect_store_ids AS (
        SELECT ss.store_sk
        FROM ss_data ss
        INTERSECT
        SELECT s.s_store_sk
        FROM store s
        WHERE s.s_state = 'CA'
    ),
    cs_agg AS (
        SELECT
            SUM(cs_ext_sales_price) AS total_catalog_sales,
            SUM(cs_net_profit)       AS total_catalog_profit
        FROM cs_data
    ),
    ws_agg AS (
        SELECT
            SUM(ws_ext_sales_price) AS total_web_sales,
            SUM(ws_net_profit)      AS total_web_profit
        FROM ws_data
    )
SELECT
    i.store_sk,
    ss.t_hour,
    SUM(ss.ss_ext_sales_price)    AS total_store_sales,
    SUM(ss.ss_net_profit)         AS total_store_profit,
    MAX(cs.total_catalog_sales)   AS total_catalog_sales,
    MAX(cs.total_catalog_profit)  AS total_catalog_profit,
    MAX(ws.total_web_sales)       AS total_web_sales,
    MAX(ws.total_web_profit)      AS total_web_profit
FROM intersect_store_ids i
LEFT JOIN ss_data ss
    ON ss.store_sk = i.store_sk
CROSS JOIN cs_agg cs
CROSS JOIN ws_agg ws
GROUP BY i.store_sk, ss.t_hour
ORDER BY total_store_sales DESC
LIMIT 50
