WITH filtered_returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        concat(s.s_city, ', ', s.s_state) AS store_location,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_city LIKE 'A%'
      AND regexp_like(r.r_reason_desc, '(?i)damage')
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        concat(s.s_city, ', ', s.s_state),
        r.r_reason_desc
)
SELECT
    fr.s_store_name,
    fr.store_location,
    fr.r_reason_desc,
    fr.total_net_loss,
    fr.return_cnt,
    substring(fr.r_reason_desc, 1, 10) AS reason_prefix,
    concat(fr.s_store_name, ' - ', fr.store_location) AS full_label
FROM filtered_returns fr
WHERE fr.total_net_loss > (
        SELECT avg(total_net_loss) FROM filtered_returns
    )
  AND EXISTS (
        SELECT 1 FROM store_sales ss WHERE ss.ss_store_sk = fr.s_store_sk
    )
ORDER BY fr.total_net_loss DESC
LIMIT 100
