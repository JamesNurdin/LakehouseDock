WITH refunded_losses AS (
    SELECT
        concat(cc.cc_city, ', ', cc.cc_state) AS location,
        'CallCenter' AS source,
        SUM(cr.cr_net_loss) AS total_metric,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM
        catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE
        regexp_like(cd.cd_education_status, '(College|Advanced Degree)')
        AND cc.cc_city LIKE 'San%'
    GROUP BY
        concat(cc.cc_city, ', ', cc.cc_state)
),
page_returns AS (
    SELECT
        cp.cp_catalog_page_id AS location,
        'CatalogPage' AS source,
        SUM(cr.cr_return_amount) AS total_metric,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM
        catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE
        regexp_like(cp.cp_description, '\\d{3,}')
        AND cd.cd_gender = 'M'
        AND cp.cp_type LIKE 'A%'
    GROUP BY
        cp.cp_catalog_page_id
)
SELECT
    location,
    source,
    total_metric,
    loss_category
FROM refunded_losses
UNION ALL
SELECT
    location,
    source,
    total_metric,
    loss_category
FROM page_returns
ORDER BY total_metric DESC
LIMIT 100
