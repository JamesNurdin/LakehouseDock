WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_net_loss,
        sr.sr_return_time_sk,
        i.i_item_desc
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{2}')
      AND s.s_store_name LIKE '%Store%'
)
SELECT
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    SUBSTRING(s.s_city, 1, 3) AS city_prefix,
    SUM(fr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_cnt,
    MAX(regexp_extract(fr.i_item_desc, '([0-9]{3})', 1)) AS example_item_code
FROM filtered_returns fr
JOIN store s
    ON fr.sr_store_sk = s.s_store_sk
JOIN time_dim t
    ON fr.sr_return_time_sk = t.t_time_sk
WHERE t.t_hour BETWEEN 8 AND 17
GROUP BY s.s_store_name,
         CONCAT(s.s_city, ', ', s.s_state),
         SUBSTRING(s.s_city, 1, 3)
ORDER BY total_net_loss DESC
LIMIT 5
