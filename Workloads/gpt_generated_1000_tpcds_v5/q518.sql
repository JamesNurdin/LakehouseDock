WITH sales_returns_agg AS (
    SELECT
        cd.cd_education_status,
        cd.cd_dep_employed_count,
        ss.ss_store_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(sr.sr_return_tax) AS total_return_tax
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_employed_count >= 2
        AND cd.cd_education_status IN ('Advanced Degree', '4 yr Degree', 'Secondary')
        AND sr.sr_return_tax > 5.00
        AND sr.sr_return_ship_cost BETWEEN 20 AND 500
        AND ss.ss_wholesale_cost < 100
    GROUP BY
        cd.cd_education_status,
        cd.cd_dep_employed_count,
        ss.ss_store_sk
)
SELECT
    education_status,
    dep_employed_count,
    store_sk,
    distinct_tickets,
    total_sales,
    total_returns,
    total_profit,
    total_return_tax,
    (total_returns / NULLIF(total_sales, 0)) AS return_rate
FROM (
    SELECT
        cd_education_status AS education_status,
        cd_dep_employed_count AS dep_employed_count,
        ss_store_sk AS store_sk,
        distinct_tickets,
        total_sales,
        total_returns,
        total_profit,
        total_return_tax
    FROM sales_returns_agg
) agg
WHERE total_sales > 1000
    AND total_profit > 0
    AND (total_returns / NULLIF(total_sales, 0)) < 0.2
ORDER BY total_sales DESC, education_status
LIMIT 100
