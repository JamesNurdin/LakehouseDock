WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_addr_sk,
        sr.sr_net_loss,
        sr.sr_return_amt
    FROM store_returns sr
    WHERE sr.sr_net_loss > 100
      AND sr.sr_return_quantity >= 1
      AND sr.sr_reversed_charge < 500
)
SELECT
    d.d_year,
    ca.ca_state,
    t.t_hour,
    COUNT(DISTINCT ca.ca_address_id) AS distinct_address_cnt,
    SUM(fr.sr_net_loss) AS total_net_loss,
    AVG(fr.sr_return_amt) AS avg_return_amt,
    MIN(fr.sr_net_loss) AS min_net_loss,
    MAX(fr.sr_net_loss) AS max_net_loss
FROM filtered_returns fr
JOIN date_dim d
    ON fr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON fr.sr_return_time_sk = t.t_time_sk
JOIN customer_address ca
    ON fr.sr_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2002
  AND ca.ca_state = 'CA'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY ROLLUP (d.d_year, ca.ca_state, t.t_hour)
HAVING SUM(fr.sr_net_loss) > 500
ORDER BY d.d_year ASC NULLS LAST,
         ca.ca_state ASC NULLS LAST,
         t.t_hour ASC NULLS LAST
LIMIT 100
