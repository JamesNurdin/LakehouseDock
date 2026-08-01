WITH intersect_orders AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 30
    INTERSECT
    SELECT ws.ws_order_number AS order_number
    FROM web_sales ws
    WHERE ws.ws_list_price > 60
)
SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT ws.ws_ship_mode_sk) AS distinct_ship_modes,
    COUNT(DISTINCT cr.cr_reason_sk) AS distinct_return_reasons,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    SUM(CASE WHEN cr.cr_fee > 50 THEN cr.cr_fee ELSE 0 END) AS high_fee_sum,
    CASE WHEN SUM(cr.cr_return_quantity) > 10 THEN 'HighQtyReturn' ELSE 'LowQtyReturn' END AS return_quantity_category,
    (SELECT SUM(cr_inner.cr_return_amount)
     FROM catalog_returns cr_inner
     WHERE cr_inner.cr_refunded_cdemo_sk = cd.cd_demo_sk) AS total_refund_for_demo,
    COUNT(*) AS transaction_count
FROM
    catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    cr.cr_return_amount > 20
    AND cr.cr_fee < 70
    AND cr.cr_return_ship_cost > 100
    AND ws.ws_list_price > 50
    AND ws.ws_ship_mode_sk IN (13, 19)
    AND cd.cd_purchase_estimate BETWEEN 3000 AND 8000
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cr.cr_order_number
          AND cr2.cr_fee > 90
    )
    AND cr.cr_order_number IN (SELECT order_number FROM intersect_orders)
GROUP BY
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status
HAVING
    SUM(ws.ws_ext_sales_price) > 1000
ORDER BY
    total_return_amount DESC
LIMIT 100
