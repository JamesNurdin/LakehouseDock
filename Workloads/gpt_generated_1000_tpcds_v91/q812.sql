WITH sampled_returns AS (
    SELECT
        sr_return_amt_inc_tax,
        sr_net_loss,
        sr_store_sk,
        sr_return_quantity,
        sr_return_tax,
        sr_customer_sk,
        sr_ticket_number,
        sr_returned_date_sk
    FROM store_returns
    TABLESAMPLE BERNOULLI (5)
)
SELECT
    s.s_store_id,
    s.s_store_name,
    CAST(regexp_extract(s.s_store_id, '[0-9]+') AS integer) AS store_id_number,
    regexp_extract(s.s_store_name, 'Store[[:space:]]+(\\w+)') AS store_type,
    CONCAT(s.s_city, '-', s.s_state) AS city_state_code,
    s.s_city,
    s.s_state,
    substring(s.s_city, 1, 1) AS city_initial,
    SUM(r.sr_net_loss) AS total_net_loss,
    SUM(r.sr_return_amt_inc_tax) AS total_return_amount,
    COUNT(*) AS return_count
FROM sampled_returns r
JOIN store s
    ON r.sr_store_sk = s.s_store_sk
WHERE regexp_like(s.s_store_name, '^Store[[:space:]].*$')
  AND s.s_city LIKE 'San%'
  AND s.s_state IN ('CA', 'TX')
GROUP BY
    s.s_store_id,
    s.s_store_name,
    CAST(regexp_extract(s.s_store_id, '[0-9]+') AS integer),
    regexp_extract(s.s_store_name, 'Store[[:space:]]+(\\w+)'),
    CONCAT(s.s_city, '-', s.s_state),
    s.s_city,
    s.s_state,
    substring(s.s_city, 1, 1)
ORDER BY total_net_loss DESC
LIMIT 100
