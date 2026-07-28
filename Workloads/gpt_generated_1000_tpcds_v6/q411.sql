WITH returns AS (
    SELECT
        'Return' AS source,
        cc.cc_name AS location,
        SUM(cr.cr_return_amount) AS total_amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND cr.cr_return_amount > 1500
    GROUP BY cc.cc_name
),
sales AS (
    SELECT
        'Sale' AS source,
        wp.wp_url AS location,
        SUM(ws.ws_net_paid) AS total_amount
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE wp.wp_type = 'content'
      AND ws.ws_net_paid > 5000
    GROUP BY wp.wp_url
)
SELECT source, location, total_amount
FROM returns
UNION ALL
SELECT source, location, total_amount
FROM sales
ORDER BY total_amount DESC
