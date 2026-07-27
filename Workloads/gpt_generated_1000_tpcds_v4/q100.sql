WITH all_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        cs.cs_net_paid,
        ws.ws_net_paid,
        sr.sr_return_amt,
        cr.cr_return_amount,
        w.w_warehouse_id,
        w.w_state,
        cc.cc_name,
        p.p_promo_name,
        r.r_reason_desc,
        cd_bill.cd_purchase_estimate,
        hd_bill.hd_buy_potential,
        ib.ib_lower_bound,
        inv.inv_quantity_on_hand,
        wp.wp_url,
        wsit.web_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    LEFT JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN customer_address ca_cr_refund ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
    LEFT JOIN customer_demographics cd_cr_refund ON cr.cr_refunded_cdemo_sk = cd_cr_refund.cd_demo_sk
    LEFT JOIN household_demographics hd_cr_refund ON cr.cr_refunded_hdemo_sk = hd_cr_refund.hd_demo_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
),
agg AS (
    SELECT
        i_item_id,
        i_category,
        w_warehouse_id,
        cc_name,
        i_current_price,
        i_item_sk,
        w_state,
        cd_purchase_estimate,
        inv_quantity_on_hand,
        SUM(COALESCE(cs_net_paid, 0) + COALESCE(ws_net_paid, 0) - COALESCE(sr_return_amt, 0) - COALESCE(cr_return_amount, 0)) AS total_revenue,
        MAX(cd_purchase_estimate) > 4000 AS high_purchase_estimate
    FROM all_data
    WHERE w_state = 'CA'
      AND i_category = 'Electronics'
      AND cd_purchase_estimate > 4000
      AND inv_quantity_on_hand > 0
    GROUP BY
        i_item_id,
        i_category,
        w_warehouse_id,
        cc_name,
        i_current_price,
        i_item_sk,
        w_state,
        cd_purchase_estimate,
        inv_quantity_on_hand
)
SELECT
    a.i_item_id,
    a.i_category,
    a.w_warehouse_id,
    a.cc_name,
    a.i_current_price,
    a.total_revenue,
    CASE WHEN a.total_revenue > 10000 THEN 'High' ELSE 'Low' END AS revenue_category,
    ROW_NUMBER() OVER (ORDER BY a.total_revenue DESC) AS revenue_rank,
    (
        SELECT COUNT(*)
        FROM promotion p_sub
        WHERE p_sub.p_item_sk = a.i_item_sk
          AND p_sub.p_discount_active = 'Y'
    ) AS active_promo_count
FROM agg a
ORDER BY a.total_revenue DESC
LIMIT 100
