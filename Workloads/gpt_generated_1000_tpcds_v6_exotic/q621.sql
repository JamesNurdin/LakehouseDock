WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_addr_sk,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_return_tax,
        sr.sr_return_quantity,
        sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_return_amt > 100
      AND sr.sr_fee >= 20
      AND sr.sr_return_quantity >= 1
      AND sr.sr_net_loss IS NOT NULL
      AND sr.sr_return_tax BETWEEN 5 AND 50
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ca.ca_city,
    ca.ca_state,
    SUM(fr.sr_return_amt) AS total_return_amt,
    COUNT(DISTINCT fr.sr_return_quantity) AS distinct_qty,
    CASE
        WHEN SUM(fr.sr_return_amt) > 1000 THEN 'HIGH'
        WHEN SUM(fr.sr_return_amt) BETWEEN 500 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(fr.sr_return_amt) DESC) AS state_store_rank,
    ROW_NUMBER() OVER (ORDER BY SUM(fr.sr_return_amt) DESC) AS global_rank
FROM filtered_returns fr
JOIN store s ON fr.sr_store_sk = s.s_store_sk
JOIN customer_address ca ON fr.sr_addr_sk = ca.ca_address_sk
WHERE s.s_state = 'CA'
  AND s.s_division_id = 1
  AND ca.ca_gmt_offset BETWEEN -5.00 AND -4.00
  AND ca.ca_zip LIKE '9%'
GROUP BY s.s_store_id, s.s_store_name, ca.ca_city, ca.ca_state
HAVING SUM(fr.sr_return_amt) > 500
ORDER BY global_rank
LIMIT 20
