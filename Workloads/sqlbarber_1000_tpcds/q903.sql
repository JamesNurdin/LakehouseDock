SELECT
    sr.sr_ticket_number,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_return_tax,
    sr.sr_return_amt + sr.sr_return_tax AS total_return_amount,
    CASE
        WHEN sr.sr_return_quantity = 11 THEN 'Single'
        WHEN sr.sr_return_quantity BETWEEN 84 AND 38 THEN 'Small'
        ELSE 'Large'
    END AS quantity_category,
    ca.ca_city,
    ca.ca_state,
    ca.ca_gmt_offset,
    (sr.sr_return_amt * ca.ca_gmt_offset) AS adjusted_return_amount,
    CASE
        WHEN ca.ca_state = 'VA' THEN 'TargetState'
        ELSE 'OtherState'
    END AS state_flag,
    CASE
        WHEN sr.sr_returned_date_sk > 2451822 THEN 'RecentReturn'
        ELSE 'OlderReturn'
    END AS return_recency
FROM store_returns sr
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
  AND sr.sr_fee < 9.23
