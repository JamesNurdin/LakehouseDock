WITH joined_data AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        cc.cc_gmt_offset,
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        ws.ws_order_number,
        ws.ws_net_profit,
        cr.cr_net_loss,
        p.p_discount_active,
        p.p_cost,
        web_site.web_name
    FROM call_center cc
    JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                       AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
                       AND p.p_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        i.i_current_price > 50.0
        AND cc.cc_state = 'CA'
        AND hd_refunded.hd_buy_potential = '1001-5000'
        AND i.i_item_sk NOT IN (SELECT i3.i_item_sk FROM item i3 WHERE i3.i_brand_id = 999999)
),
aggregated AS (
    SELECT
        cc_call_center_id,
        cc_name,
        cc_state,
        cc_gmt_offset,
        i_brand,
        i_category,
        web_name,
        SUM(ws_net_profit) AS total_sales_profit,
        SUM(cr_net_loss) AS total_return_net_loss,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        AVG(CASE WHEN p_discount_active = 'Y' THEN p_cost ELSE NULL END) AS avg_active_promo_cost,
        CASE WHEN cc_gmt_offset >= 0 THEN 'East' ELSE 'West' END AS region
    FROM joined_data
    GROUP BY
        cc_call_center_id,
        cc_name,
        cc_state,
        cc_gmt_offset,
        i_brand,
        i_category,
        web_name
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_state,
    i_brand,
    i_category,
    web_name,
    total_sales_profit,
    total_return_net_loss,
    distinct_orders,
    avg_active_promo_cost,
    region,
    (SELECT MAX(i2.i_current_price) FROM item i2) AS max_item_price,
    RANK() OVER (ORDER BY total_sales_profit DESC) AS profit_rank,
    SUM(total_sales_profit) OVER (PARTITION BY cc_state) AS profit_by_state
FROM aggregated
ORDER BY total_sales_profit DESC
LIMIT 100
