WITH cc_returns AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_county,
        cc.cc_state,
        cc.cc_zip,
        regexp_extract(cc.cc_zip, '(\\d{5})', 1) AS zip5,
        concat(cc.cc_city, ', ', cc.cc_state) AS location,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk
    FROM
        tpcds.call_center cc
        JOIN tpcds.catalog_returns cr
            ON cc.cc_call_center_sk = cr.cr_call_center_sk
    WHERE
        regexp_like(cc.cc_name, '(?i)center')
        AND cc.cc_county LIKE 'W%'
)
SELECT
    crv.cc_name,
    crv.zip5,
    crv.location,
    COUNT(*) AS total_returns,
    SUM(crv.cr_return_amount) AS total_return_amount,
    AVG(crv.cr_return_ship_cost) AS avg_ship_cost,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_refunded_returns
FROM
    cc_returns crv
    LEFT JOIN tpcds.customer_demographics cd
        ON crv.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE EXISTS (
        SELECT 1
        FROM tpcds.customer_demographics cd2
        WHERE cd2.cd_demo_sk = crv.cr_returning_cdemo_sk
          AND cd2.cd_gender = 'M'
          AND cd2.cd_dep_count >= 2
    )
GROUP BY
    crv.cc_name,
    crv.zip5,
    crv.location
HAVING
    SUM(crv.cr_return_amount) > 10000
    AND COUNT(*) >= 10
ORDER BY
    total_return_amount DESC
LIMIT 100
