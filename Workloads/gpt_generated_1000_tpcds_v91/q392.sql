WITH promo_sales AS (
    SELECT
        p.p_promo_id,
        p.p_channel_radio,
        sm.sm_type,
        sm.sm_contract,
        c.c_preferred_cust_flag,
        td.t_hour,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_qty,
        COUNT(cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_net_paid) AS avg_net_paid
    FROM
        catalog_sales cs
        RIGHT OUTER JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        LEFT OUTER JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT OUTER JOIN time_dim td
            ON cs.cs_sold_time_sk = td.t_time_sk
        LEFT OUTER JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE
        p.p_promo_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAADAAAAAAA', 'AAAAAAAEBAAAAAA')
        AND sm.sm_type IN ('OVERNIGHT', 'NEXT DAY', 'EXPRESS')
        AND sm.sm_contract <> 'GNJr3g5i7oorKqtX'
        AND td.t_hour BETWEEN 8 AND 20
        AND c.c_preferred_cust_flag = 'Y'
        AND cs.cs_quantity > 2
        AND cs.cs_net_paid >= 100
    GROUP BY
        p.p_promo_id,
        p.p_channel_radio,
        sm.sm_type,
        sm.sm_contract,
        c.c_preferred_cust_flag,
        td.t_hour
    HAVING
        SUM(cs.cs_net_paid) > 1000
        AND COUNT(cs.cs_order_number) >= 5
)
SELECT
    ps.p_promo_id,
    ps.sm_type,
    ps.c_preferred_cust_flag,
    ps.total_net_paid,
    ps.total_qty,
    ps.order_cnt,
    ps.avg_net_paid,
    lr.ratio AS net_paid_per_qty,
    RANK() OVER (PARTITION BY ps.sm_type ORDER BY ps.total_net_paid DESC) AS promo_rank_by_ship_type
FROM
    promo_sales ps
    LEFT JOIN LATERAL (
        SELECT CASE WHEN ps.total_qty = 0 THEN NULL ELSE ps.total_net_paid / ps.total_qty END AS ratio
    ) lr ON TRUE
ORDER BY
    ps.total_net_paid DESC,
    ps.p_promo_id
LIMIT 100
