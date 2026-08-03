WITH cr_agg AS (
    SELECT
        cr_call_center_sk,
        cr_returned_date_sk,
        cr_refunded_hdemo_sk,
        cr_returning_hdemo_sk,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    GROUP BY cr_call_center_sk, cr_returned_date_sk, cr_refunded_hdemo_sk, cr_returning_hdemo_sk
),
joined AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        d_ret.d_date               AS return_date,
        cr_agg.total_net_loss,
        cr_agg.return_cnt,
        ib_refunded.ib_lower_bound AS refunded_income_lower,
        ib_returning.ib_upper_bound AS returning_income_upper,
        p.p_promo_id,
        p.p_channel_details,
        (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_channel_tv = 'Y') AS max_tv_promo_cost,
        p.p_discount_active        -- keep for filtering, not projected later
    FROM cr_agg
    JOIN call_center cc
        ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_ret
        ON cr_agg.cr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_closed
        ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN household_demographics hd_refunded
        ON cr_agg.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr_agg.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN income_band ib_refunded
        ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
    JOIN income_band ib_returning
        ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
    JOIN promotion p
        ON d_ret.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_ret.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    cc_call_center_id,
    cc_name,
    return_date,
    total_net_loss,
    return_cnt,
    refunded_income_lower,
    returning_income_upper,
    p_promo_id,
    p_channel_details,
    max_tv_promo_cost
FROM joined
WHERE p_discount_active = 'Y'
EXCEPT
SELECT
    cc_call_center_id,
    cc_name,
    return_date,
    total_net_loss,
    return_cnt,
    refunded_income_lower,
    returning_income_upper,
    p_promo_id,
    p_channel_details,
    max_tv_promo_cost
FROM joined
WHERE p_discount_active = 'N'
ORDER BY total_net_loss DESC
