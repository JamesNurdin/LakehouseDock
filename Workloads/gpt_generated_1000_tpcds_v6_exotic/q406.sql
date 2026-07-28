WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_addr_sk,
        sr.sr_return_time_sk,
        sr.sr_reason_sk,
        sr.sr_net_loss,
        st.s_manager,
        st.s_city,
        ca.ca_city AS cust_city,
        r.r_reason_desc,
        t.t_hour,
        concat(st.s_manager, ' - ', st.s_city) AS manager_city
    FROM store_returns sr
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE regexp_like(ca.ca_city, '^.*(ton|ville)$')
      AND ca.ca_state LIKE 'A%'
      AND regexp_extract(r.r_reason_desc, '(.*)customer(.*)', 1) IS NOT NULL
)
SELECT
    manager_city,
    COUNT(*) AS return_cnt,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(sr_net_loss) AS avg_net_loss,
    MIN(t_hour) AS earliest_return_hour,
    MAX(t_hour) AS latest_return_hour
FROM filtered_returns
GROUP BY manager_city
HAVING SUM(sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
