WITH hourly_returns AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_net_loss,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_returning_addr_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
)
SELECT
    ca_ret.ca_country AS returning_country,
    ca_ref.ca_country AS refunded_country,
    td.t_hour,
    COUNT(*) AS return_cnt,
    SUM(hr.wr_net_loss) AS total_net_loss,
    AVG(hr.wr_return_amt) AS avg_return_amount,
    SUM(hr.wr_return_quantity) AS total_quantity
FROM hourly_returns hr
JOIN time_dim td ON hr.wr_returned_time_sk = td.t_time_sk
JOIN customer_address ca_ret ON hr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref ON hr.wr_refunded_addr_sk = ca_ref.ca_address_sk
WHERE ca_ret.ca_country = 'United States'
  AND td.t_hour BETWEEN 8 AND 20
GROUP BY ca_ret.ca_country, ca_ref.ca_country, td.t_hour
HAVING SUM(hr.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 50
