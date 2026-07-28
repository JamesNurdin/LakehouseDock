WITH rs AS (
    SELECT
        d.d_year,
        s.s_state,
        regexp_extract(s.s_manager, '^([^ ]+)') AS manager_first_name,
        concat(s.s_city, ', ', s.s_state) AS city_state,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        i.i_item_desc
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE i.i_item_desc LIKE '%size%'
      AND (s.s_manager LIKE '%Adams%' OR regexp_like(s.s_manager, '^J'))
)
SELECT
    d_year,
    s_state,
    manager_first_name,
    COUNT(*) AS return_cnt,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_quantity) AS avg_quantity,
    CASE WHEN SUM(sr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_level
FROM rs
GROUP BY d_year, s_state, manager_first_name
ORDER BY total_return_amount DESC
LIMIT 100
