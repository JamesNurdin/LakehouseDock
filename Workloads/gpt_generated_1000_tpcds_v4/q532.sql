WITH avg_dep_employed AS (
    SELECT avg(cd_dep_employed_count) AS avg_dep
    FROM customer_demographics
),
filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_net_profit,
        ws.ws_coupon_amt
    FROM web_sales ws
    WHERE EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_order_number = ws.ws_order_number
          AND ws2.ws_coupon_amt > 100
    )
)
SELECT
    CONCAT(CAST(d.d_year AS varchar), '-', LPAD(CAST(d.d_month_seq AS varchar), 2, '0')) AS year_month,
    SUM(fs.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT fs.ws_order_number) AS distinct_orders,
    REGEXP_EXTRACT(d.d_day_name, '(\\w+)') AS day_name_extracted
FROM filtered_sales fs
JOIN date_dim d
  ON fs.ws_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd
  ON fs.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN avg_dep_employed a
  ON 1 = 1
WHERE
    REGEXP_LIKE(cd.cd_gender, '^M')
    AND d.d_day_name LIKE '%day%'
    AND cd.cd_dep_employed_count > a.avg_dep
GROUP BY
    CONCAT(CAST(d.d_year AS varchar), '-', LPAD(CAST(d.d_month_seq AS varchar), 2, '0')),
    REGEXP_EXTRACT(d.d_day_name, '(\\w+)')
ORDER BY total_net_profit DESC
LIMIT 100
