WITH promo_start AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_item_sk,
        p.p_cost,
        p.p_response_target,
        p.p_promo_name,
        p.p_channel_event,
        d.d_year,
        d.d_month_seq,
        d.d_date
    FROM promotion p
    JOIN date_dim d
        ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_current_quarter = 'Y'
      AND regexp_like(p.p_promo_name, '(?i)clearance|sale')
      AND p.p_promo_id LIKE 'AAAAAAA%'
),
agg_year_month AS (
    SELECT
        ps.d_year,
        ps.d_month_seq,
        COUNT(DISTINCT ps.p_promo_sk)                         AS promo_count,
        SUM(ps.p_cost)                                         AS total_cost,
        AVG(ps.p_cost)                                         AS avg_cost,
        MAX(ps.p_cost)                                         AS max_cost,
        CASE
            WHEN SUM(CASE WHEN ps.p_channel_event = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'HAS_EVENT'
            ELSE 'NO_EVENT'
        END                                                    AS event_presence,
        (
            SELECT SUM(p2.p_cost)
            FROM promotion p2
            JOIN date_dim d2 ON p2.p_end_date_sk = d2.d_date_sk
            WHERE d2.d_year = ps.d_year
              AND d2.d_holiday = 'Y'
        )                                                     AS holiday_end_cost,
        CONCAT('Year ', CAST(ps.d_year AS varchar), ' Month ', CAST(ps.d_month_seq AS varchar)) AS year_month_desc
    FROM promo_start ps
    GROUP BY ps.d_year, ps.d_month_seq
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.promo_count,
    a.total_cost,
    a.avg_cost,
    a.max_cost,
    a.event_presence,
    a.holiday_end_cost,
    a.year_month_desc,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_cost DESC) AS month_rank_by_cost,
    regexp_extract(a.year_month_desc, '(\\d+)$', 1)                                 AS month_number_extracted
FROM agg_year_month a
ORDER BY a.d_year, month_rank_by_cost
