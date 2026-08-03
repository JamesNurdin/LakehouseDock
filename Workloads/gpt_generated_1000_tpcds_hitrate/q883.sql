WITH
    filtered_household AS (
        SELECT
            hd_demo_sk,
            hd_income_band_sk,
            hd_buy_potential,
            hd_dep_count,
            hd_vehicle_count
        FROM household_demographics
        WHERE hd_vehicle_count >= 2
          AND hd_dep_count <= 4
          AND hd_buy_potential IN ('1001-5000', '5001-10000')
    ),
    promo_filtered AS (
        SELECT
            p_promo_sk,
            p_promo_id,
            p_channel_radio,
            p_channel_event,
            p_discount_active
        FROM promotion
        WHERE p_channel_radio = 'N'
          AND p_channel_event = 'N'
          AND p_discount_active = 'Y'
    ),
    cs_filtered AS (
        SELECT
            cs_order_number,
            cs_bill_hdemo_sk,
            cs_ship_hdemo_sk,
            cs_ship_mode_sk,
            cs_promo_sk,
            cs_ext_sales_price,
            cs_ext_discount_amt,
            cs_net_profit,
            cs_quantity,
            cs_ext_list_price
        FROM catalog_sales
        WHERE cs_ext_list_price > 10000
          AND cs_quantity >= 2
    ),
    ss_filtered AS (
        SELECT
            ss_ticket_number,
            ss_hdemo_sk,
            ss_promo_sk,
            ss_ext_sales_price,
            ss_ext_discount_amt,
            ss_net_profit,
            ss_quantity
        FROM store_sales
        WHERE ss_quantity >= 2
          AND ss_ext_sales_price > 5000
    ),
    ws_filtered AS (
        SELECT
            ws_order_number,
            ws_bill_hdemo_sk,
            ws_ship_hdemo_sk,
            ws_ship_mode_sk,
            ws_promo_sk,
            ws_ext_sales_price,
            ws_ext_discount_amt,
            ws_net_profit,
            ws_quantity
        FROM web_sales
        WHERE ws_quantity >= 2
          AND ws_ext_sales_price > 5000
    ),
    intersect_orders AS (
        SELECT cs_order_number AS order_id FROM cs_filtered
        INTERSECT
        SELECT ws_order_number FROM ws_filtered
    )
SELECT
    p.p_promo_id,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    MIN(cs.cs_ext_sales_price) AS min_catalog_sales,
    MAX(ws.ws_ext_sales_price) AS max_web_sales,
    RANK() OVER (PARTITION BY p.p_promo_id ORDER BY (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) DESC) AS profit_rank
FROM filtered_household hd
JOIN cs_filtered cs ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN promo_filtered p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN ss_filtered ss ON ss.ss_hdemo_sk = hd.hd_demo_sk AND ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN ws_filtered ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk AND ws.ws_promo_sk = p.p_promo_sk
WHERE EXISTS (
    SELECT 1 FROM intersect_orders io WHERE io.order_id = cs.cs_order_number
)
GROUP BY p.p_promo_id
ORDER BY total_profit DESC
LIMIT 100
