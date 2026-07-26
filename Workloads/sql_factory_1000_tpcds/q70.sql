SELECT
    t.d_year,
    t.d_month_seq,
    t.hd_buy_potential,
    t.review_customers,
    t.active_promos,
    SUM(t.review_customers) OVER (PARTITION BY t.d_year, t.hd_buy_potential ORDER BY t.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_review_customers,
    SUM(t.active_promos) OVER (PARTITION BY t.d_year, t.hd_buy_potential ORDER BY t.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_active_promos,
    SUM(t.review_customers) OVER (PARTITION BY t.d_year, t.hd_buy_potential ORDER BY t.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) -
    SUM(t.active_promos) OVER (PARTITION BY t.d_year, t.hd_buy_potential ORDER BY t.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS diff_cum
FROM (
    SELECT
        d_rev.d_year,
        d_rev.d_month_seq,
        hd.hd_buy_potential,
        COUNT(DISTINCT c.c_customer_id) AS review_customers,
        COUNT(DISTINCT p.p_promo_id) AS active_promos
    FROM date_dim d_rev
    LEFT JOIN customer c ON c.c_last_review_date = d_rev.d_date_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p ON p.p_start_date_sk <= d_rev.d_date_sk AND p.p_end_date_sk >= d_rev.d_date_sk
    GROUP BY d_rev.d_year, d_rev.d_month_seq, hd.hd_buy_potential
) t
ORDER BY t.d_year, t.d_month_seq, t.hd_buy_potential
