WITH joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_refunded_cash,
        cr.cr_net_loss,
        d_ret.d_year,
        d_ret.d_date,
        p.p_promo_id,
        p.p_cost,
        p.p_channel_demo,
        p.p_discount_active,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_ret.d_year = 2001
      AND p.p_channel_demo = 'N'
      AND cr.cr_return_tax > 50
      AND p.p_cost < 5000
      AND d_ret.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    cr_returned_date_sk,
    d_year,
    p_promo_id,
    amount_category,
    cr_return_amount,
    cr_return_tax,
    cr_refunded_cash,
    cr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY cr_return_amount DESC) AS rn_amount,
    RANK() OVER (PARTITION BY amount_category ORDER BY cr_return_tax DESC) AS rank_tax
FROM joined
ORDER BY d_year, rn_amount
LIMIT 100
