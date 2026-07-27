WITH joined_data AS (
    SELECT
        s.s_store_id,
        s.s_state,
        ca.ca_state AS address_state,
        ca.ca_location_type,
        sr.sr_return_amt,
        sr.sr_net_loss,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_wholesale_cost
    FROM store_returns sr
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('TX','WA','UT','LA','OH')
      AND ca.ca_location_type = 'single family'
      AND sr.sr_return_amt > 100
      AND sr.sr_net_loss > 0
      AND ws.ws_quantity BETWEEN 1 AND 10
      AND ws.ws_net_profit > 0
      AND s.s_number_employees > 30
      AND s.s_tax_percentage < 0.12
      AND ca.ca_zip LIKE '9%'
),
agg AS (
    SELECT
        s_store_id,
        s_state,
        address_state,
        ca_location_type,
        SUM(sr_return_amt)               AS total_return_amt,
        SUM(sr_net_loss)                 AS total_net_loss,
        COUNT(*)                         AS return_txn_cnt,
        SUM(ws_ext_sales_price)          AS total_sales,
        SUM(ws_net_profit)               AS total_profit,
        COUNT(DISTINCT ws_net_paid)      AS sales_txn_cnt,
        SUM(CASE WHEN ws_ext_sales_price > 1000 THEN ws_ext_sales_price ELSE 0 END) AS high_value_sales
    FROM joined_data
    GROUP BY s_store_id, s_state, address_state, ca_location_type
)
SELECT
    a.s_store_id,
    a.s_state,
    a.address_state,
    a.ca_location_type,
    a.total_return_amt,
    a.total_sales,
    a.total_profit,
    CASE
        WHEN a.total_profit > 50000 THEN 'High'
        WHEN a.total_profit BETWEEN 20000 AND 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    a.total_sales - a.total_return_amt AS net_sales_minus_returns,
    (
        SELECT MAX(s2.s_tax_percentage)
        FROM store s2
        WHERE s2.s_state = a.s_state
    ) AS max_state_tax_pct
FROM agg a
WHERE a.total_sales > 20000
  AND a.high_value_sales > 5000
  AND a.total_return_amt > 5000
  AND a.total_profit > 10000
  AND a.return_txn_cnt >= 5
  AND a.sales_txn_cnt >= 5
ORDER BY net_sales_minus_returns DESC
LIMIT 100
