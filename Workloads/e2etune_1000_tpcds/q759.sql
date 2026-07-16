WITH filtered_returns AS (
    SELECT
        wr.wr_net_loss,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        ca.ca_county
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_country = 'CHILE'
      AND c.c_birth_month = 12
      AND td.t_shift = 'EVE'
)
SELECT
    ca_county,
    total_net_loss,
    avg_return_amt,
    total_return_qty,
    RANK() OVER (ORDER BY total_net_loss DESC) AS county_rank,
    SUM(total_net_loss) OVER (ORDER BY total_net_loss DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss
FROM (
    SELECT
        ca_county,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_amt) AS avg_return_amt,
        SUM(wr_return_quantity) AS total_return_qty
    FROM filtered_returns
    GROUP BY ca_county
    HAVING SUM(wr_net_loss) > 0
) agg
ORDER BY total_net_loss DESC
LIMIT 5
