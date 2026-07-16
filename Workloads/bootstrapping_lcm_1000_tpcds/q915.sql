WITH store_year_stats AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_ret.d_year,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS total_returns,
        SUM(CASE WHEN cd_ref.cd_gender = 'F' THEN 1 ELSE 0 END) AS refunded_female_cnt,
        SUM(CASE WHEN cd_ret.cd_gender = 'F' THEN 1 ELSE 0 END) AS returning_female_cnt
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE s.s_state = 'TX'
      AND d_ret.d_year BETWEEN 2000 AND 2005
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state, d_ret.d_year
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    d_year,
    total_net_loss,
    avg_return_amount,
    total_returns,
    refunded_female_cnt,
    returning_female_cnt,
    CAST(refunded_female_cnt AS double) / NULLIF(total_returns, 0) * 100 AS pct_refunded_female,
    CAST(returning_female_cnt AS double) / NULLIF(total_returns, 0) * 100 AS pct_returning_female,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM store_year_stats
ORDER BY d_year, loss_rank
LIMIT 100
