WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_net_loss,
        ca.ca_city,
        s.s_store_name,
        r.r_reason_desc
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_city, '^New')
      AND s.s_store_name LIKE '%Market%'
)
SELECT
    fr.s_store_name,
    CONCAT(fr.s_store_name, ' (', CAST(fr.sr_store_sk AS varchar), ')') AS store_label,
    fr.r_reason_desc,
    SUM(fr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    MIN(regexp_extract(fr.ca_city, '^(\\w+)', 1)) AS city_prefix,
    ROW_NUMBER() OVER (PARTITION BY fr.sr_store_sk ORDER BY SUM(fr.sr_net_loss) DESC) AS loss_rank
FROM filtered_returns fr
GROUP BY fr.s_store_name, fr.sr_store_sk, fr.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
