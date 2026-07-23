WITH avg_purchase_estimate AS (
    SELECT AVG(cd_purchase_estimate) AS avg_est
    FROM customer_demographics
),

filtered_returns AS (
    SELECT cr_returned_date_sk,
           cr_return_quantity,
           cr_return_amount,
           cr_net_loss,
           cr_reason_sk,
           cr_catalog_page_sk,
           cr_refunded_cdemo_sk,
           cr_refunded_addr_sk
    FROM catalog_returns cr
    WHERE cr_return_amount > 0
),

joined_data AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_description,
        r.r_reason_desc,
        ca.ca_city,
        ca.ca_state,
        cd.cd_purchase_estimate,
        fr.cr_return_amount,
        fr.cr_net_loss
    FROM filtered_returns fr
    JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON fr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cp.cp_description, '(?i)promo|discount')
      AND ca.ca_city LIKE 'San%'
      AND regexp_like(r.r_reason_desc, '(?i)defect|damage')
)

SELECT
    cp_catalog_page_id,
    SUBSTRING(cp_description, 1, 30) AS short_description,
    r_reason_desc,
    CONCAT(ca_city, ', ', ca_state) AS city_state,
    COUNT(*) AS return_count,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM joined_data
WHERE cd_purchase_estimate > (SELECT avg_est FROM avg_purchase_estimate)
GROUP BY
    cp_catalog_page_id,
    SUBSTRING(cp_description, 1, 30),
    r_reason_desc,
    CONCAT(ca_city, ', ', ca_state)
ORDER BY total_return_amount DESC
LIMIT 100
