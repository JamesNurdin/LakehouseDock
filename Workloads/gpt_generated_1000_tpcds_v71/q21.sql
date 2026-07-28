WITH base AS (
    SELECT
        d.d_year,
        cc.cc_name,
        sm.sm_type,
        r.r_reason_desc,
        i.inv_quantity_on_hand,
        p.p_cost,
        cr.cr_return_amount,
        cr.cr_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cr.cr_return_amount > 100
      AND cc.cc_employees > 50
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc LIKE '%damaged%'
      AND p.p_discount_active = 'N'
),
agg AS (
    SELECT
        d_year,
        cc_name,
        sm_type,
        r_reason_desc,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        MAX(inv_quantity_on_hand) AS max_on_hand,
        AVG(p_cost) AS avg_promo_cost
    FROM base
    GROUP BY d_year, cc_name, sm_type, r_reason_desc
)
SELECT
    a.d_year,
    a.cc_name,
    a.sm_type,
    a.r_reason_desc,
    a.total_return_amount,
    a.total_return_quantity,
    a.max_on_hand,
    a.avg_promo_cost,
    CASE
        WHEN a.total_return_amount > (
            SELECT MAX(p_cost)
            FROM promotion
            WHERE p_discount_active = 'N'
        ) THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amount DESC) AS loss_rank
FROM agg a
ORDER BY loss_rank, total_return_amount DESC
LIMIT 100
