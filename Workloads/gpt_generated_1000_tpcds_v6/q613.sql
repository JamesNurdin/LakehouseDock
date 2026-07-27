WITH filtered_returns AS (
    SELECT
        sr.sr_return_time_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_shift = 'Evening'
      AND REGEXP_LIKE(
            (SELECT ca.ca_street_name FROM customer_address ca WHERE ca.ca_address_sk = sr.sr_addr_sk),
            'Road$'
          )
      AND EXISTS (
            SELECT 1 FROM reason r
            WHERE r.r_reason_sk = sr.sr_reason_sk
              AND r.r_reason_desc LIKE '%damaged%'
          )
),
joined AS (
    SELECT
        st.s_store_name,
        st.s_city,
        r.r_reason_desc,
        fr.sr_net_loss
    FROM filtered_returns fr
    JOIN store st ON fr.sr_store_sk = st.s_store_sk
    JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON fr.sr_addr_sk = ca.ca_address_sk
)
SELECT
    CONCAT(st.s_store_name, ' - ', st.s_city) AS store_full_name,
    REGEXP_EXTRACT(r.r_reason_desc, '^([A-Za-z]+)', 1) AS reason_root_word,
    SUM(j.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM joined j
JOIN store st ON j.s_store_name = st.s_store_name AND j.s_city = st.s_city
JOIN reason r ON j.r_reason_desc = r.r_reason_desc
GROUP BY
    CONCAT(st.s_store_name, ' - ', st.s_city),
    REGEXP_EXTRACT(r.r_reason_desc, '^([A-Za-z]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 20
