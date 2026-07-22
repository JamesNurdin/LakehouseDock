WITH main AS (
    SELECT
        s.s_store_name,
        cp.cp_department,
        d_sr.d_year,
        COUNT(DISTINCT cr.cr_order_number) AS num_orders,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(CASE WHEN cr.cr_return_tax > 20 THEN cr.cr_return_tax ELSE 0 END) AS high_tax_return_total,
        AVG(p.p_cost) AS avg_promo_cost,
        (SELECT AVG(p2.p_cost) FROM promotion p2) AS overall_avg_promo_cost,
        CASE
            WHEN SUM(sr.sr_net_loss) > 100000 THEN 'High Loss'
            ELSE 'Low Loss'
        END AS loss_category
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sr.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d_sr.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_sr.d_week_seq = 12
      AND d_sr.d_year = 2001
      AND s.s_manager = 'Brian Norris'
      AND cp.cp_type = 'PROMO'
      AND p.p_discount_active = 'Y'
      AND cr.cr_return_tax > 20
      AND d_store_closed.d_current_quarter = 'Y'
    GROUP BY s.s_store_name, cp.cp_department, d_sr.d_year
)
SELECT *
FROM main
ORDER BY store_net_loss DESC
LIMIT 100
