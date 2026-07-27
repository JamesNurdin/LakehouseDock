WITH returning_addr AS (
    SELECT
        ca.ca_state,
        ca.ca_location_type,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        CAST(regexp_extract(ca.ca_street_number, '(\\d+)', 1) AS integer) AS street_num_digits,
        CONCAT(ca.ca_city, ' - ', ca.ca_location_type) AS city_loc
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_street_number, '^[3-9][0-9]{2}$')
      AND ca.ca_city LIKE '%County%'
)
SELECT
    ca_state,
    ca_location_type,
    COUNT(*) AS return_cnt,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(wr_return_quantity) AS avg_quantity,
    MIN(street_num_digits) AS min_street_num,
    MAX(street_num_digits) AS max_street_num
FROM returning_addr
GROUP BY ca_state, ca_location_type
HAVING SUM(wr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
