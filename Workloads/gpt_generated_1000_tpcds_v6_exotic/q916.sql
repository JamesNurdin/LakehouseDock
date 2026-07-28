/*
Goal: Compare monthly totals of web sales (male customers with active discounts) and store returns (female customers) for the year 2002, providing subtotals by month, source, and overall.
*/
WITH ws_data AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        cd.cd_gender AS gender,
        ws.ws_ext_sales_price AS amount,
        'web_sales' AS src
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        d.d_year = 2002
        AND cd.cd_gender = 'M'
        AND p.p_discount_active = 'Y'
),
sr_data AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        cd.cd_gender AS gender,
        sr.sr_return_amt AS amount,
        'store_returns' AS src
    FROM
        store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE
        d.d_year = 2002
        AND cd.cd_gender = 'F'
)
SELECT
    year,
    month,
    src,
    SUM(amount) AS total_amount
FROM (
    SELECT year, month, src, amount FROM ws_data
    UNION ALL
    SELECT year, month, src, amount FROM sr_data
) u
GROUP BY GROUPING SETS (
    (year, month, src),
    (year, month),
    (year, src),
    (year),
    ()
)
ORDER BY year, month, src
LIMIT 100
