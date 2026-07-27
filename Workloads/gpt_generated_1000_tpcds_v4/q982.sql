WITH return_agg AS (
    SELECT
        cc.cc_mkt_class AS category,
        SUM(cr.cr_return_amount) AS total_amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cc.cc_mkt_class LIKE '%physical%'
    GROUP BY cc.cc_mkt_class
),
sale_agg AS (
    SELECT
        cd.cd_gender AS category,
        SUM(ws.ws_net_paid) AS total_amount
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY cd.cd_gender
)
SELECT DISTINCT
    category,
    total_amount
FROM (
    SELECT category, total_amount FROM return_agg
    UNION ALL
    SELECT category, total_amount FROM sale_agg
) combined
ORDER BY total_amount DESC
