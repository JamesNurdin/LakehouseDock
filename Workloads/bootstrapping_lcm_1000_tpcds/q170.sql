WITH promotion_dates AS (
    SELECT
        p.p_cost,
        p.p_discount_active,
        p.p_response_target,
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk,
        ds.d_year AS start_year,
        ds.d_quarter_name AS start_quarter,
        de.d_year AS end_year,
        de.d_quarter_name AS end_quarter
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN date_dim de ON p.p_end_date_sk = de.d_date_sk
),
store_promo_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_market_desc,
        cds.d_year AS closed_year,
        cds.d_quarter_name AS closed_quarter,
        COUNT(DISTINCT pd.p_promo_id) AS promo_count,
        SUM(pd.p_cost) AS total_promo_cost,
        SUM(CASE WHEN pd.p_discount_active = 'Y' THEN pd.p_cost ELSE 0 END) AS total_active_cost,
        AVG(pd.p_response_target) AS avg_response_target
    FROM store s
    JOIN date_dim cds ON s.s_closed_date_sk = cds.d_date_sk
    JOIN promotion_dates pd ON cds.d_date_sk BETWEEN pd.p_start_date_sk AND pd.p_end_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_market_desc,
        cds.d_year,
        cds.d_quarter_name
)
SELECT
    spa.*,
    ROW_NUMBER() OVER (PARTITION BY spa.s_state ORDER BY spa.total_promo_cost DESC) AS state_rank
FROM store_promo_agg spa
ORDER BY spa.s_state, state_rank
