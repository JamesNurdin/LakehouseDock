WITH returns_filtered AS (
    SELECT
        sr.sr_net_loss,
        s.s_store_name,
        s.s_manager,
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc
    FROM store_returns sr
    INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE split_part(s.s_manager, ' ', 2) LIKE 'J%'
      AND lower(r.r_reason_desc) LIKE '%damaged%'
      AND d.d_year = 2020
)
SELECT
    s_store_name,
    upper(split_part(s_manager, ' ', 2)) AS manager_last_name_upper,
    concat(cast(d_year AS varchar), '-', lpad(cast(d_month_seq AS varchar), 2, '0')) AS year_month,
    sum(sr_net_loss) AS total_net_loss,
    count(*) AS return_count
FROM returns_filtered
GROUP BY
    s_store_name,
    upper(split_part(s_manager, ' ', 2)),
    concat(cast(d_year AS varchar), '-', lpad(cast(d_month_seq AS varchar), 2, '0'))
ORDER BY total_net_loss DESC
LIMIT 5
