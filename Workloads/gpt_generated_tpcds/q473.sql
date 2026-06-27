WITH sales AS (
    SELECT
        ss_sold_date_sk,
        ss_ticket_number,
        ss_item_sk,
        ss_cdemo_sk,
        ss_ext_sales_price,
        ss_ext_discount_amt,
        ss_net_profit
    FROM store_sales
),
returns AS (
    SELECT
        sr_ticket_number,
        sr_item_sk,
        sr_return_amt
    FROM store_returns
)
SELECT
    d.d_year,
    cd.cd_gender,
    cd.cd_education_status,
    COUNT(DISTINCT s.ss_ticket_number) AS num_transactions,
    SUM(s.ss_ext_sales_price) AS total_sales,
    COALESCE(SUM(r.sr_return_amt), 0) AS total_returns,
    SUM(s.ss_ext_sales_price) - COALESCE(SUM(r.sr_return_amt), 0) AS net_sales,
    SUM(s.ss_net_profit) AS total_profit,
    CASE
        WHEN SUM(s.ss_ext_sales_price) = 0 THEN 0
        ELSE SUM(s.ss_ext_discount_amt) / SUM(s.ss_ext_sales_price)
    END AS avg_discount_rate
FROM sales s
JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd ON s.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN returns r
    ON r.sr_ticket_number = s.ss_ticket_number
    AND r.sr_item_sk = s.ss_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY
    d.d_year,
    cd.cd_gender,
    cd.cd_education_status
ORDER BY
    d.d_year,
    cd.cd_gender,
    cd.cd_education_status
