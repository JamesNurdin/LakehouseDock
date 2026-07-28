WITH ss_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        d_ss.d_year AS ss_year,
        cd_ss.cd_gender,
        hd_ss.hd_vehicle_count,
        p_ss.p_promo_name
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
),
ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        d_ws_sold.d_year AS ws_sold_year,
        d_ws_ship.d_year AS ws_ship_year,
        cd_ws_bill.cd_gender AS bill_gender,
        hd_ws_bill.hd_vehicle_count AS bill_vehicle_cnt,
        p_ws.p_promo_name AS ws_promo_name,
        wp.wp_type,
        w_ws.w_warehouse_name
    FROM web_sales ws
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
),
wr_base AS (
    SELECT
        wr.wr_order_number,
        wr.wr_returned_date_sk,
        r.r_reason_desc,
        cd_ref.cd_gender AS refunded_gender,
        hd_ref.hd_vehicle_count AS refunded_vehicle_cnt,
        cd_ret.cd_gender AS returning_gender,
        hd_ret.hd_vehicle_count AS returning_vehicle_cnt,
        wp_wr.wp_type AS return_page_type
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
),
inv_base AS (
    SELECT
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        d_inv.d_year AS inv_year
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
),
cc_base AS (
    SELECT
        cc.cc_market_manager,
        cc.cc_mkt_desc,
        d_open.d_year AS open_year,
        d_closed.d_year AS closed_year
    FROM call_center cc
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
)
SELECT
    cc.cc_mkt_desc,
    ss.p_promo_name,
    ws.ws_promo_name,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_store_items,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_web_items,
    CASE
        WHEN SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) > 1000000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS profit_level
FROM ss_base ss
JOIN ws_base ws ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
JOIN wr_base wr ON ws.ws_order_number = wr.wr_order_number
JOIN inv_base inv ON ws.ws_warehouse_sk = inv.inv_warehouse_sk
JOIN cc_base cc ON cc.open_year = inv.inv_year
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i2
    JOIN date_dim d2 ON i2.inv_date_sk = d2.d_date_sk
    WHERE i2.inv_warehouse_sk = ws.ws_warehouse_sk
      AND d2.d_year = ws.ws_sold_year
      AND i2.inv_quantity_on_hand = 0
)
GROUP BY
    cc.cc_mkt_desc,
    ss.p_promo_name,
    ws.ws_promo_name,
    cc.cc_mkt_desc,
    ss.p_promo_name,
    ws.ws_promo_name
ORDER BY total_store_profit DESC
LIMIT 100
