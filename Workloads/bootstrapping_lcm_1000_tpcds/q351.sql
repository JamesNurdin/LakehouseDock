WITH agg AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        sm.sm_carrier AS carrier,
        s.s_state AS store_state,
        s.s_city AS store_city,
        d.d_year,
        d.d_quarter_name,
        p.p_promo_name,
        pe.p_promo_id AS end_promo_id,
        p.p_channel_email,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        MIN(p.p_cost) AS min_promo_cost,
        MAX(p.p_cost) AS max_promo_cost,
        SUM(CASE WHEN cr.cr_return_quantity > 5 THEN 1 ELSE 0 END) AS high_qty_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN promotion pe ON pe.p_end_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND p.p_discount_active = 'Y'
    GROUP BY
        sm.sm_type,
        sm.sm_carrier,
        s.s_state,
        s.s_city,
        d.d_year,
        d.d_quarter_name,
        p.p_promo_name,
        pe.p_promo_id,
        p.p_channel_email
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    ship_mode_type,
    carrier,
    store_state,
    store_city,
    d_year,
    d_quarter_name,
    p_promo_name,
    end_promo_id,
    p_channel_email,
    return_cnt,
    total_return_qty,
    total_net_loss,
    avg_return_amount,
    min_promo_cost,
    max_promo_cost,
    high_qty_return_cnt,
    RANK() OVER (PARTITION BY ship_mode_type ORDER BY total_net_loss DESC) AS loss_rank_by_ship_mode
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
