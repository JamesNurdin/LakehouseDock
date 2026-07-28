WITH filtered_returns AS (
    SELECT
        cr.cr_net_loss,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_ship_cost > 500
      AND cr.cr_refunded_cash < 200
      AND cd.cd_marital_status IN ('S', 'M')
      AND ca.ca_street_type = 'Rd'
)
SELECT
    cd_gender,
    cd_marital_status,
    ca_state,
    COUNT(*) AS returns_cnt,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount,
    MIN(cr_return_ship_cost) AS min_ship_cost,
    MAX(cr_refunded_cash) AS max_refunded_cash
FROM filtered_returns
GROUP BY cd_gender, cd_marital_status, ca_state
ORDER BY total_net_loss DESC
LIMIT 100
