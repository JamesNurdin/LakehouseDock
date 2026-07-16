WITH aggregated_returns AS (
    SELECT
        ca_returning.ca_state AS returning_state,
        ca_returning.ca_city AS returning_city,
        ca_refunded.ca_county AS refunded_county,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_returns wr
    JOIN customer_address ca_refunded
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE wr.wr_returned_date_sk BETWEEN 20200101 AND 20221231
      AND ca_returning.ca_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
    GROUP BY
        ca_returning.ca_state,
        ca_returning.ca_city,
        ca_refunded.ca_county
    HAVING COUNT(*) >= 5
)
SELECT
    returning_state,
    returning_city,
    refunded_county,
    return_cnt,
    total_return_amt_inc_tax,
    total_net_loss,
    avg_return_qty,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated_returns
ORDER BY total_net_loss DESC
LIMIT 50
