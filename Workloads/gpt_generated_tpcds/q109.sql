-- Analytical query: profit and order metrics by gender, marital status and credit rating
--   using both billing and shipping customer demographics.
WITH combined_demo AS (
    -- Billing customer demographics
    SELECT
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    -- Shipping customer demographics
    SELECT
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
),
aggregated AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        COUNT(*) AS order_count,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_profit) AS avg_profit_per_order
    FROM combined_demo
    WHERE cd_credit_rating = 'A'
    GROUP BY cd_gender, cd_marital_status, cd_credit_rating
)
SELECT
    cd_gender,
    cd_marital_status,
    cd_credit_rating,
    order_count,
    total_quantity,
    total_discount,
    total_profit,
    avg_profit_per_order,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank
LIMIT 20
