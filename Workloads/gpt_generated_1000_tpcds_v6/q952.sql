WITH agg AS (
    SELECT
        s.s_state,
        i.i_brand,
        d1.d_year,
        SUM(sr.sr_return_amt) AS total_store_return,
        SUM(cr.cr_return_amount) AS total_catalog_return,
        COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
        (SELECT AVG(ib2.ib_upper_bound) FROM income_band ib2) AS avg_income_upper
    FROM store_returns sr
    JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d1.d_date_sk
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d3 ON p.p_start_date_sk = d3.d_date_sk
    JOIN date_dim d4 ON p.p_end_date_sk = d4.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d5 ON wp.wp_creation_date_sk = d5.d_date_sk
    JOIN date_dim d6 ON wp.wp_access_date_sk = d6.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d5.d_date_sk
    WHERE
        d1.d_year = 2001
        AND i.i_brand = 'Brand#45'
        AND ib.ib_lower_bound >= 30000
        AND s.s_state IN ('CA', 'TX', 'NY')
        AND sm.sm_type = 'AIR'
        AND wp.wp_type = 'Content'
        AND hd.hd_buy_potential = '>10000'
    GROUP BY ROLLUP(s.s_state, i.i_brand, d1.d_year)
)
SELECT
    a.s_state,
    a.i_brand,
    a.d_year,
    a.total_store_return,
    a.total_catalog_return,
    a.distinct_promos,
    a.avg_income_upper,
    DENSE_RANK() OVER (ORDER BY a.total_store_return DESC) AS state_rank
FROM agg a
ORDER BY a.total_store_return DESC
LIMIT 100
