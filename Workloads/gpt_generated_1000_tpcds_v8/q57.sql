WITH ws_agg AS (
    SELECT
        ws_sold_time_sk,
        ws_item_sk,
        ws_order_number,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_promo_sk,
        ws_ship_mode_sk,
        SUM(ws_net_paid)               AS ws_total_net_paid,
        SUM(ws_quantity)               AS ws_total_quantity,
        AVG(ws_ext_discount_amt)       AS ws_avg_discount
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY
        ws_sold_time_sk,
        ws_item_sk,
        ws_order_number,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_promo_sk,
        ws_ship_mode_sk
),
cs_agg AS (
    SELECT
        cs_sold_time_sk,
        cs_item_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_promo_sk,
        cs_ship_mode_sk,
        SUM(cs_net_paid) AS cs_total_net_paid,
        SUM(cs_quantity) AS cs_total_quantity
    FROM catalog_sales
    WHERE cs_quantity > 0
    GROUP BY
        cs_sold_time_sk,
        cs_item_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_promo_sk,
        cs_ship_mode_sk
),
sr_agg AS (
    SELECT
        sr_return_time_sk,
        sr_store_sk,
        sr_cdemo_sk,
        sr_hdemo_sk,
        SUM(sr_refunded_cash) AS sr_total_refunded_cash,
        COUNT(*)               AS sr_return_count
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY
        sr_return_time_sk,
        sr_store_sk,
        sr_cdemo_sk,
        sr_hdemo_sk
)
SELECT
    s.s_store_name,
    p.p_promo_name,
    sm.sm_ship_mode_id,
    td_ws.t_hour,
    cd.cd_gender,
    hd.hd_vehicle_count,
    SUM(ws_agg.ws_total_net_paid)          AS total_web_sales_net,
    SUM(cs_agg.cs_total_net_paid)          AS total_catalog_sales_net,
    SUM(sr_agg.sr_total_refunded_cash)     AS total_store_refunds,
    COUNT(DISTINCT ws_agg.ws_item_sk)      AS distinct_items_sold,
    CASE
        WHEN SUM(ws_agg.ws_total_net_paid) > 50000 THEN 'High'
        ELSE 'Medium'
    END                                    AS sales_category
FROM cs_agg
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN ws_agg
    ON ws_agg.ws_promo_sk = p.p_promo_sk
   AND ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_ws
    ON ws_agg.ws_sold_time_sk = td_ws.t_time_sk
JOIN customer_demographics cd
    ON ws_agg.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ws_agg.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws_agg.ws_item_sk
   AND wr.wr_order_number = ws_agg.ws_order_number
JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN sr_agg
    ON sr_agg.sr_cdemo_sk = cd.cd_demo_sk
   AND sr_agg.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON sr_agg.sr_store_sk = s.s_store_sk
JOIN time_dim td_sr
    ON sr_agg.sr_return_time_sk = td_sr.t_time_sk
WHERE
    td_ws.t_hour = 12
    AND p.p_discount_active = 'Y'
    AND s.s_state = 'TX'
    AND hd.hd_income_band_sk = 12
    AND wr.wr_return_quantity > 1
GROUP BY
    s.s_store_name,
    p.p_promo_name,
    sm.sm_ship_mode_id,
    td_ws.t_hour,
    cd.cd_gender,
    hd.hd_vehicle_count
HAVING
    SUM(ws_agg.ws_total_net_paid) > 20000
ORDER BY
    total_web_sales_net DESC
LIMIT 100
