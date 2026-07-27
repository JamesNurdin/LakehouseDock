WITH sales_agg AS (
    SELECT
        ws_order_number,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_quantity,
        MAX(ws_sold_date_sk) AS max_sold_date_sk
    FROM web_sales
    GROUP BY ws_order_number
)
SELECT
    wr.wr_order_number,
    cd.cd_gender,
    substring(cd.cd_gender FROM 1 FOR 1) AS gender_initial,
    concat('CR_', cd.cd_credit_rating) AS credit_rating_concat,
    regexp_extract(cd.cd_credit_rating, '([0-9]+)') AS credit_rating_digits,
    CASE
        WHEN regexp_like(cd.cd_credit_rating, '^A[0-9]{2}$') THEN 'A_Rating'
        ELSE 'Other'
    END AS rating_category,
    sa.total_profit,
    sa.total_quantity,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount
FROM web_returns wr
JOIN sales_agg sa
    ON wr.wr_order_number = sa.ws_order_number
JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_marital_status LIKE 'S%'
  AND cd.cd_education_status LIKE '%College%'
  AND regexp_like(cd.cd_credit_rating, '^A[0-9]{2}$')
GROUP BY
    wr.wr_order_number,
    cd.cd_gender,
    substring(cd.cd_gender FROM 1 FOR 1),
    concat('CR_', cd.cd_credit_rating),
    regexp_extract(cd.cd_credit_rating, '([0-9]+)'),
    CASE
        WHEN regexp_like(cd.cd_credit_rating, '^A[0-9]{2}$') THEN 'A_Rating'
        ELSE 'Other'
    END,
    sa.total_profit,
    sa.total_quantity
ORDER BY total_return_amount DESC
LIMIT 100
