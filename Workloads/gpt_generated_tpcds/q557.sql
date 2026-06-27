WITH
catalog_sales_data AS (
    SELECT
        d_cs.d_year AS year,
        cd.cd_gender AS gender,
        cs.cs_net_profit AS net_amount,
        cs.cs_order_number AS order_number,
        c.c_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
),
catalog_returns_data AS (
    SELECT
        d_cr.d_year AS year,
        cd.cd_gender AS gender,
        -cr.cr_net_loss AS net_amount,
        cr.cr_order_number AS order_number,
        c.c_customer_sk AS customer_sk
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
),
web_sales_data AS (
    SELECT
        d_ws.d_year AS year,
        cd.cd_gender AS gender,
        ws.ws_net_profit AS net_amount,
        ws.ws_order_number AS order_number,
        c.c_customer_sk AS customer_sk
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
),
store_returns_data AS (
    SELECT
        d_sr.d_year AS year,
        cd.cd_gender AS gender,
        -sr.sr_net_loss AS net_amount,
        sr.sr_ticket_number AS order_number,
        c.c_customer_sk AS customer_sk
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
),
combined AS (
    SELECT year, gender, net_amount, order_number, customer_sk FROM catalog_sales_data
    UNION ALL
    SELECT year, gender, net_amount, order_number, customer_sk FROM catalog_returns_data
    UNION ALL
    SELECT year, gender, net_amount, order_number, customer_sk FROM web_sales_data
    UNION ALL
    SELECT year, gender, net_amount, order_number, customer_sk FROM store_returns_data
)
SELECT
    combined.year,
    combined.gender,
    SUM(combined.net_amount) AS total_net_amount,
    COUNT(DISTINCT combined.customer_sk) AS distinct_customers
FROM combined
WHERE combined.year BETWEEN 2000 AND 2002
GROUP BY combined.year, combined.gender
ORDER BY total_net_amount DESC
