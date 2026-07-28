WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        sr.sr_returned_date_sk,
        r.r_reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND sr.sr_return_amt_inc_tax > 100
)
SELECT
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    d.d_year,
    COUNT(*) AS returns_count,
    SUM(fr.sr_return_quantity) AS total_quantity,
    SUM(fr.sr_return_amt_inc_tax) AS total_return_amount,
    SUM(fr.sr_net_loss) AS total_net_loss,
    REGEXP_EXTRACT(MIN(fr.r_reason_desc), '([A-Za-z]{3})') AS short_reason
FROM filtered_returns fr
JOIN store s ON fr.sr_store_sk = s.s_store_sk
JOIN date_dim d ON fr.sr_returned_date_sk = d.d_date_sk
WHERE s.s_store_name LIKE 'Store %'
  AND SUBSTRING(s.s_store_name, 1, 5) = 'Store'
GROUP BY
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state),
    d.d_year
HAVING SUM(fr.sr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
