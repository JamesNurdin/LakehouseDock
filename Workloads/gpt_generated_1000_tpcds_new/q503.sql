WITH
    sampled_ws AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    filtered_cr AS (
        SELECT *
        FROM catalog_returns
        WHERE cr_return_amount > 30
    ),
    intersect_orders AS (
        SELECT cr_order_number
        FROM catalog_returns
        WHERE cr_return_amount > 30
        INTERSECT
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_ext_sales_price > 100
    )
SELECT
    cd.cd_credit_rating,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ws.ws_ext_sales_price) AS avg_sales_price,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    MIN(ws.ws_net_profit) AS min_net_profit,
    MAX(ws.ws_net_profit) AS max_net_profit,
    (SELECT MAX(cr_return_amount) FROM catalog_returns) AS max_return_amount_overall
FROM filtered_cr cr
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN sampled_ws ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE cd.cd_credit_rating = 'Low Risk'
  AND cd.cd_marital_status = 'M'
  AND cd.cd_dep_college_count >= 2
  AND hd.hd_income_band_sk BETWEEN 8 AND 12
  AND hd.hd_buy_potential = '501-1000'
  AND ws.ws_ext_sales_price > 100
  AND cr.cr_order_number IN (SELECT cr_order_number FROM intersect_orders)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cr.cr_order_number
          AND cr2.cr_return_amount > 5000
    )
GROUP BY
    cd.cd_credit_rating,
    cd.cd_marital_status,
    hd.hd_buy_potential
ORDER BY total_return_amount DESC
LIMIT 100
