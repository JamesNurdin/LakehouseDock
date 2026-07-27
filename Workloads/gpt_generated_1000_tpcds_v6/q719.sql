WITH per_address AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        ca.ca_zip,
        SUM(sr.sr_return_amt) AS store_return_sum,
        SUM(wr.wr_return_amt) AS web_return_sum,
        SUM(sr.sr_net_loss + wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
    FROM tpcds.store_returns sr
    JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_returns wr ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
      AND ca.ca_zip LIKE '9%'
      AND ca.ca_city <> 'Unknown'
      AND sr.sr_return_tax > 1.00
      AND wr.wr_reversed_charge < 500
      AND sr.sr_return_quantity >= 1
      AND wr.wr_return_quantity >= 1
    GROUP BY ca.ca_state, ca.ca_city, ca.ca_zip
)
SELECT
    per_address.ca_state,
    per_address.ca_city,
    per_address.ca_zip,
    per_address.store_return_sum,
    per_address.web_return_sum,
    per_address.total_net_loss,
    per_address.store_return_cnt,
    per_address.web_return_cnt,
    SUM(per_address.store_return_sum) OVER (
        PARTITION BY per_address.ca_state
        ORDER BY per_address.store_return_sum DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_store_return_by_state
FROM per_address
WHERE per_address.total_net_loss > 1000
  AND per_address.store_return_cnt > 5
ORDER BY per_address.total_net_loss DESC
