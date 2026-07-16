WITH aggregated AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_city AS call_center_city,
        w.w_city AS warehouse_city,
        p.p_promo_name AS promotion_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT i.i_item_id) AS distinct_items_returned,
        AVG(hd_ref.hd_vehicle_count) AS avg_refunded_vehicle_count,
        AVG(hd_ret.hd_vehicle_count) AS avg_returning_vehicle_count,
        COUNT(DISTINCT ca_ref.ca_state) AS distinct_refunded_states
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE
        cc.cc_tax_percentage > 0.05
        AND p.p_discount_active = 'Y'
        AND cr.cr_returned_date_sk BETWEEN 2451000 AND 2452000
        AND cc.cc_state IN ('CA', 'NY', 'TX')
    GROUP BY
        cc.cc_name,
        cc.cc_city,
        w.w_city,
        p.p_promo_name
    HAVING
        SUM(cr.cr_net_loss) > 10000
)
SELECT
    a.*, 
    RANK() OVER (PARTITION BY a.promotion_name ORDER BY a.total_net_loss DESC) AS loss_rank_within_promo
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
