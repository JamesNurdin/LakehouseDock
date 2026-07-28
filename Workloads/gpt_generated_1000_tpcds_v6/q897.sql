WITH base AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_net_profit AS net_profit,
        cs.cs_sold_date_sk,
        i.i_item_id AS item_id,
        i.i_brand AS brand,
        i.i_current_price,
        cp.cp_department AS department,
        sm.sm_type,
        p.p_promo_name,
        p.p_discount_active,
        ca_bill.ca_state,
        cd_bill.cd_gender,
        hd_bill.hd_income_band_sk,
        cr.cr_return_amount,
        sr.sr_return_quantity,
        ws.ws_net_profit AS ws_net_profit,
        wp.wp_type AS web_page_type,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_profit DESC) AS dept_rank,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_flag
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    WHERE i.i_current_price > 20
      AND sm.sm_type = 'OVERNIGHT'
      AND p.p_discount_active = 'Y'
      AND ca_bill.ca_state = 'CA'
      AND cd_bill.cd_gender = 'M'
)
SELECT DISTINCT
    order_number,
    item_id,
    brand,
    department,
    net_profit,
    profit_flag,
    dept_rank,
    cr_return_amount AS return_amount,
    sr_return_quantity AS return_quantity,
    ws_net_profit,
    web_page_type
FROM base
ORDER BY dept_rank, net_profit DESC
LIMIT 100
