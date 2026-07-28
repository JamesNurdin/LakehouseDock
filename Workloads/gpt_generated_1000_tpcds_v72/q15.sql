WITH catalog_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CAST('Catalog' AS varchar) AS return_source,
        CAST(NULL AS varchar) AS carrier
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450552 AND 2450781
    GROUP BY r.r_reason_desc
),
web_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amount,
        CAST('Web' AS varchar) AS return_source,
        sm.sm_carrier AS carrier
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450552 AND 2450781
    GROUP BY r.r_reason_desc, sm.sm_carrier
)
SELECT reason_desc,
       total_return_amount,
       return_source,
       carrier
FROM catalog_ret
UNION ALL
SELECT reason_desc,
       total_return_amount,
       return_source,
       carrier
FROM web_ret
ORDER BY total_return_amount DESC
LIMIT 100
