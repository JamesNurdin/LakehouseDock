WITH filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        ca.ca_state,
        ca.ca_location_type,
        ca.ca_gmt_offset,
        cd.cd_gender,
        cd.cd_dep_employed_count,
        cd.cd_purchase_estimate
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN tpcds.customer_address ca
        ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    WHERE cr.cr_return_quantity = 4
      AND cr.cr_fee > 20.00
      AND ca.ca_location_type = 'condo'
      AND ca.ca_gmt_offset = -6.00
      AND cd.cd_dep_employed_count >= 4
      AND cd.cd_purchase_estimate BETWEEN 4000 AND 6000
      AND cs.cs_quantity > 5
)
SELECT
    ca_state,
    cd_gender,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cs_net_paid) AS avg_net_paid,
    MIN(cr_return_quantity) AS min_return_qty,
    MAX(cr_return_quantity) AS max_return_qty
FROM filtered
GROUP BY ca_state, cd_gender
ORDER BY total_return_amount DESC
LIMIT 100
