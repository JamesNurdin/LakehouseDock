WITH high_estimate AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    cd.cd_purchase_estimate,
    'HIGH' AS segment
  FROM tpcds.customer c
  JOIN tpcds.customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE cd.cd_purchase_estimate > 4000
    AND ca.ca_state = 'CA'
),
low_estimate AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    cd.cd_purchase_estimate,
    'LOW' AS segment
  FROM tpcds.customer c
  JOIN tpcds.customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE cd.cd_purchase_estimate <= 4000
    AND ca.ca_state = 'TX'
)
SELECT *
FROM high_estimate
UNION ALL
SELECT *
FROM low_estimate
ORDER BY segment, c_customer_id
