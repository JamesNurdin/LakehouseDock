SELECT
    i.i_brand AS brand,
    ca.ca_state AS state,
    COUNT(*) AS returns_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    MIN(sr.sr_reversed_charge) AS min_reversed_charge,
    MAX(sr.sr_reversed_charge) AS max_reversed_charge
FROM store_returns AS sr
JOIN item AS i
  ON sr.sr_item_sk = i.i_item_sk
JOIN customer_address AS ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE sr.sr_cdemo_sk IN (1568019, 1571148)
  AND sr.sr_reversed_charge > 100.00
  AND sr.sr_net_loss BETWEEN 50.00 AND 300.00
  AND ca.ca_gmt_offset = -5.00
  AND ca.ca_street_type = 'Ave'
  AND i.i_manufact_id = 212
GROUP BY i.i_brand, ca.ca_state
ORDER BY total_return_amount DESC
LIMIT 100
