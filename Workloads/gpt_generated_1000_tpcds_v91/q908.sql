WITH call_center_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(*) AS num_returns,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c_ret
        ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c_ret.c_customer_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND cr.cr_return_amount > 50
      AND wp.wp_char_count > 1500
      AND cd_ret.cd_credit_rating = 'Excellent'
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city
),
intersect_call_centers AS (
    SELECT cc.cc_call_center_sk
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_return_quantity > 2
    INTERSECT
    SELECT cc.cc_call_center_sk
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_return_amount > 200
)
SELECT
    ca.cc_name,
    ca.cc_city,
    ca.total_return_amount,
    ca.avg_return_amount,
    ca.total_return_quantity,
    (SELECT AVG(total_return_amount) FROM call_center_agg) AS overall_avg_return_amount,
    (SELECT MAX(cr2.cr_return_amount) FROM catalog_returns cr2) AS max_return_amount
FROM call_center_agg ca
WHERE ca.cc_call_center_sk IN (SELECT cc_call_center_sk FROM intersect_call_centers)
ORDER BY ca.total_return_amount DESC
LIMIT 100
