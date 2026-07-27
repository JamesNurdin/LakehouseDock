WITH store_promo AS (
    SELECT
        s.s_store_id,
        d_start.d_year AS promo_year,
        SUM(p.p_cost) AS total_cost,
        COUNT(*) AS promo_cnt
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_end.d_date_sk
    WHERE s.s_country = 'United States'
      AND s.s_state IN ('CA', 'TX', 'NY')
      AND p.p_channel_event = 'N'
      AND p.p_discount_active = 'Y'
      AND d_start.d_year = 2022
      AND p.p_response_target > 100
      AND p.p_cost > 100
    GROUP BY s.s_store_id, d_start.d_year
)
SELECT
    sp.promo_year,
    AVG(sp.total_cost) AS avg_store_cost,
    (SELECT MAX(total_cost) FROM store_promo sp2 WHERE sp2.promo_year = sp.promo_year) AS max_store_cost_year
FROM store_promo sp
GROUP BY sp.promo_year
HAVING AVG(sp.total_cost) > 500
ORDER BY avg_store_cost DESC
LIMIT 100
