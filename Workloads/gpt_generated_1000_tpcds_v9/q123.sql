WITH raw_returns AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_city AS city,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS store_full_name,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '^(\\w+)') AS reason_first_word,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE 
        regexp_like(r.r_reason_desc, '(?i)damage|defect|broken')
        AND s.s_city LIKE 'San%'
)
SELECT 
    rr.store_full_name,
    rr.city,
    rr.reason_first_word,
    SUM(rr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    (
        SELECT AVG(inner_agg.city_total_net_loss)
        FROM (
            SELECT city, SUM(sr_net_loss) AS city_total_net_loss
            FROM raw_returns
            GROUP BY city
        ) inner_agg
        WHERE inner_agg.city = rr.city
    ) AS avg_city_net_loss
FROM raw_returns rr
GROUP BY rr.store_full_name, rr.city, rr.reason_first_word
HAVING SUM(rr.sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
