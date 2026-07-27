WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cc.cc_name,
        cc.cc_state,
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        p.p_promo_name,
        cust.c_customer_id,
        hd.hd_income_band_sk,
        rs.r_reason_desc,
        sm.sm_type,
        sm.sm_code,
        CASE
            WHEN cr.cr_return_amount > 1000 THEN 'High'
            WHEN cr.cr_return_amount > 0 THEN 'Low'
            ELSE 'None'
        END AS return_level
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason rs ON cr.cr_reason_sk = rs.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_current_price BETWEEN 10 AND 500
      AND sm.sm_code = 'AIR'
)
SELECT
    base.cc_name,
    base.i_item_id,
    base.i_brand,
    base.i_category,
    base.p_promo_name,
    base.c_customer_id,
    base.return_level,
    SUM(base.cr_return_amount) OVER (PARTITION BY base.cc_name ORDER BY base.cr_returned_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount,
    RANK() OVER (PARTITION BY base.cc_name ORDER BY base.cr_return_amount DESC) AS amount_rank,
    DENSE_RANK() OVER (ORDER BY base.hd_income_band_sk) AS income_band_dense_rank
FROM base
WHERE EXISTS (
    SELECT 1 FROM promotion p2
    WHERE p2.p_item_sk = base.i_item_sk
      AND p2.p_response_target > 5
)
ORDER BY base.cr_returned_date_sk DESC
LIMIT 100
