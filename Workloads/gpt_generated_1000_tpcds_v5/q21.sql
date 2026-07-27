WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_net_loss,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND ca.ca_state = 'GA'
      AND cd.cd_purchase_estimate > 5000
)
SELECT
    ca.ca_state,
    d.d_year,
    COUNT(*) AS return_cnt,
    SUM(fr.wr_net_loss) AS total_net_loss,
    AVG(fr.wr_return_amt) AS avg_return_amount,
    MIN(fr.wr_return_quantity) AS min_quantity,
    MAX(fr.wr_return_quantity) AS max_quantity
FROM filtered_returns fr
JOIN date_dim d ON fr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address ca ON fr.wr_refunded_addr_sk = ca.ca_address_sk
GROUP BY ca.ca_state, d.d_year
ORDER BY total_net_loss DESC
