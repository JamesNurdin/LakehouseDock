WITH refunded AS (
    SELECT
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_net_loss AS net_loss,
        cr.cr_order_number AS order_number,
        ca.ca_zip,
        ca.ca_city,
        ca.ca_state,
        ca.ca_gmt_offset,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        regexp_extract(ca.ca_zip, '^([0-9]{3})', 1) AS zip_prefix,
        concat(ca.ca_city, ', ', ca.ca_state) AS location,
        CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag
    FROM
        catalog_returns cr
        INNER JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        INNER JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE
        regexp_like(ca.ca_county, 'County$')
        AND ca.ca_zip LIKE '9%'
        AND cd.cd_credit_rating = 'Good'
        AND cr.cr_return_amount > 0
)
SELECT
    zip_prefix,
    location,
    loss_flag,
    COUNT(DISTINCT order_number) AS distinct_orders,
    SUM(return_amount) AS total_return_amount,
    AVG(return_quantity) AS avg_return_quantity,
    MAX(ca_gmt_offset) AS max_gmt_offset,
    CASE 
        WHEN SUM(return_amount) > 1000 THEN 'High'
        WHEN SUM(return_amount) > 500 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category
FROM
    refunded
GROUP BY
    zip_prefix,
    location,
    loss_flag
HAVING
    COUNT(*) > 5
ORDER BY
    total_return_amount DESC,
    zip_prefix
LIMIT 100
