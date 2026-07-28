WITH refunded_demo AS (
    SELECT
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM tpcds.web_returns wr
    JOIN tpcds.customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE
        wr.wr_return_amt BETWEEN 100 AND 500
        AND wr.wr_return_quantity >= 1
        AND cd.cd_purchase_estimate >= 3000
        AND cd.cd_dep_count <= 3
        AND wr.wr_return_tax <= 50
        AND wr.wr_net_loss > 0
        AND EXISTS (
            SELECT 1
            FROM tpcds.customer_address ca
            WHERE ca.ca_address_sk = wr.wr_refunded_addr_sk
              AND ca.ca_state = 'CA'
              AND ca.ca_zip LIKE '9___'
              AND ca.ca_street_type = 'Blvd'
        )
)
SELECT
    cd_gender,
    cd_marital_status,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_count,
    MIN(wr_return_quantity) AS min_quantity,
    MAX(wr_return_quantity) AS max_quantity
FROM refunded_demo
GROUP BY cd_gender, cd_marital_status
ORDER BY total_return_amount DESC
LIMIT 100
