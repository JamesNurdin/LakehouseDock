WITH high_tax_non_tx_addresses AS (
    SELECT DISTINCT ca.ca_address_id
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_tax > 5.0
    EXCEPT
    SELECT DISTINCT ca.ca_address_id
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'TX'
),
filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_net_loss,
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_location_type,
        CASE WHEN sr.sr_return_tax > 20 THEN 'High Tax' ELSE 'Regular Tax' END AS tax_category,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY sr.sr_return_amt_inc_tax DESC) AS rn_state,
        SUM(sr.sr_return_amt_inc_tax) OVER (
            PARTITION BY ca.ca_state 
            ORDER BY sr.sr_returned_date_sk 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_return_amt_state
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_tax > 5.0
      AND ca.ca_zip LIKE '1%'
      AND sr.sr_return_amt_inc_tax > 100.0
)
SELECT
    fr.sr_returned_date_sk,
    fr.sr_return_amt_inc_tax,
    fr.ca_address_id,
    fr.ca_city,
    fr.ca_state,
    fr.tax_category,
    fr.rn_state,
    fr.cumulative_return_amt_state,
    (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_addr_sk = fr.sr_addr_sk) AS total_returns_for_address
FROM filtered_returns fr
WHERE fr.ca_address_id IN (SELECT ca_address_id FROM high_tax_non_tx_addresses)
ORDER BY fr.cumulative_return_amt_state DESC
LIMIT 100
