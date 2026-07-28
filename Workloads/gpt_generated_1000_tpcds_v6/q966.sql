-- Goal: Compare profitability of high-cost web sales across billing and shipping customer demographics, broken down by gender, marital status and credit rating, and classify credit rating as High or Other.
WITH high_cost_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_wholesale_cost,
        ws.ws_net_profit,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_cdemo_sk
    FROM web_sales ws
    WHERE ws.ws_ext_wholesale_cost >= 5000
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(hs.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE WHEN cd.cd_credit_rating = 'A' THEN 'High' ELSE 'Other' END AS rating_category,
    'billing' AS demographic_role
FROM high_cost_sales hs
JOIN customer_demographics cd
    ON hs.ws_bill_cdemo_sk = cd.cd_demo_sk
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating

UNION ALL

SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(hs.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE WHEN cd.cd_credit_rating = 'A' THEN 'High' ELSE 'Other' END AS rating_category,
    'shipping' AS demographic_role
FROM high_cost_sales hs
JOIN customer_demographics cd
    ON hs.ws_ship_cdemo_sk = cd.cd_demo_sk
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating

ORDER BY total_profit DESC
LIMIT 100
