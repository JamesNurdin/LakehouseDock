WITH joined_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        ws.ws_wholesale_cost,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        cd.cd_education_status,
        cd.cd_gender,
        ca.ca_state
    FROM catalog_returns AS cr
    JOIN customer_demographics AS cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_sales AS ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_tax > 10
      AND cr.cr_return_amount < 500
      AND ws.ws_wholesale_cost BETWEEN 10 AND 50
      AND cd.cd_education_status = 'College'
      AND ca.ca_state = 'CA'
),
agg_by_state_date AS (
    SELECT
        ca_state,
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM joined_data
    GROUP BY ca_state, cr_returned_date_sk
)
SELECT
    ca_state,
    cr_returned_date_sk,
    total_return_amount,
    total_sales,
    total_profit,
    txn_count,
    SUM(total_return_amount) OVER (
        PARTITION BY ca_state
        ORDER BY cr_returned_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_return_amount,
    RANK() OVER (
        PARTITION BY ca_state
        ORDER BY total_profit DESC
    ) AS profit_rank
FROM agg_by_state_date
WHERE total_return_amount > 1000
ORDER BY ca_state, cr_returned_date_sk DESC
LIMIT 100
