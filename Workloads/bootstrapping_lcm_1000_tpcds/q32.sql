SELECT
    sub.d_year,
    sub.d_month_seq,
    sub.sm_type,
    sub.p_promo_name,
    sub.s_store_name,
    sub.num_orders,
    sub.total_quantity,
    sub.total_return_amount,
    sub.total_net_loss,
    sub.avg_fee,
    sub.total_promo_cost,
    sub.net_loss_rank_year,
    sub.rn_month_top
FROM (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        sm.sm_type AS sm_type,
        p.p_promo_name AS p_promo_name,
        s.s_store_name AS s_store_name,
        COUNT(DISTINCT cr.cr_order_number) AS num_orders,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_fee) AS avg_fee,
        SUM(p.p_cost) AS total_promo_cost,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_net_loss) DESC) AS net_loss_rank_year,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY SUM(cr.cr_return_amount) DESC) AS rn_month_top
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
      AND p.p_discount_active = 'Y'
      AND sm.sm_type <> 'UNKNOWN'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        p.p_promo_name,
        s.s_store_name
) sub
WHERE sub.net_loss_rank_year <= 5
  AND sub.rn_month_top <= 3
ORDER BY sub.d_year DESC, sub.d_month_seq, sub.total_net_loss DESC
LIMIT 50
