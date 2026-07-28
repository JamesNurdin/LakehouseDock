WITH agg_returns AS (
    SELECT
        cr_item_sk,
        cr_call_center_sk,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        SUM(cr_return_quantity) AS total_qty
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_return_amount > 10
      AND cr_return_tax > 0
    GROUP BY
        cr_item_sk,
        cr_call_center_sk,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_customer_sk
),
promo_agg AS (
    SELECT
        p_item_sk,
        MIN(p_cost) AS min_promo_cost,
        MAX(p_discount_active) AS any_discount_active
    FROM promotion
    WHERE p_discount_active = 'Y'
    GROUP BY p_item_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    i.i_item_id,
    i.i_product_name,
    ar.total_return_amount,
    ar.total_qty,
    ar.return_cnt,
    pa.min_promo_cost,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    c.c_preferred_cust_flag,
    sm.sm_type,
    w.w_warehouse_name,
    RANK() OVER (PARTITION BY cc.cc_call_center_id ORDER BY ar.total_return_amount DESC) AS return_amount_rank
FROM agg_returns ar
JOIN item i
    ON ar.cr_item_sk = i.i_item_sk
JOIN call_center cc
    ON ar.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON ar.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ar.cr_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
    ON ar.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer c
    ON ar.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN promo_agg pa
    ON i.i_item_sk = pa.p_item_sk
WHERE cc.cc_state = 'CA'
  AND w.w_state = 'CA'
  AND ib.ib_upper_bound >= 50000
ORDER BY cc.cc_call_center_id, return_amount_rank
LIMIT 100
