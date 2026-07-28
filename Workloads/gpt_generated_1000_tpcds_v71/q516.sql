WITH joined AS (
    SELECT
        cr.cr_net_loss,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_state,
        s.s_suite_number,
        s.s_city,
        s.s_country
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
      AND s.s_country = 'United States'
      AND regexp_like(s.s_suite_number, '^Suite [0-9]+$')
      AND s.s_suite_number LIKE 'Suite %'
),
aggregated AS (
    SELECT
        s_store_id,
        s_state,
        s_city,
        s_suite_number,
        d_year,
        d_month_seq,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr_net_loss) > 5000 THEN 'High' ELSE 'Low' END AS loss_category,
        CAST(regexp_extract(s_suite_number, '\\d+', 0) AS integer) AS suite_num
    FROM joined
    GROUP BY s_store_id, s_state, s_city, s_suite_number, d_year, d_month_seq
)
SELECT
    s_store_id,
    s_state,
    CONCAT(s_city, ', ', s_state) AS location,
    suite_num,
    d_year,
    d_month_seq,
    total_net_loss,
    return_cnt,
    loss_category,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_net_loss DESC) AS state_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
