WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2452000
      AND sr.sr_return_amt_inc_tax > 100
      AND sr.sr_return_quantity >= 1
      AND sr.sr_fee >= 0
      AND sr.sr_return_ship_cost >= 0
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ca.ca_city,
    ca.ca_state,
    fr.sr_returned_date_sk,
    fr.sr_return_amt_inc_tax,
    CASE
        WHEN fr.sr_return_amt_inc_tax > 1000 THEN 'High'
        WHEN fr.sr_return_amt_inc_tax > 500 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY fr.sr_return_amt_inc_tax DESC) AS rn_store,
    DENSE_RANK() OVER (ORDER BY fr.sr_return_amt_inc_tax DESC) AS overall_rank
FROM filtered_returns fr
JOIN customer_address ca
    ON fr.sr_addr_sk = ca.ca_address_sk
JOIN store s
    ON fr.sr_store_sk = s.s_store_sk
WHERE ca.ca_zip LIKE '4%'
  AND ca.ca_state = 'CA'
  AND s.s_state = 'CA'
  AND s.s_tax_percentage > 0.05
  AND s.s_city = 'Seattle'
ORDER BY overall_rank ASC, s.s_store_id
LIMIT 100
