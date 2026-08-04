WITH ws_sample AS (
    SELECT ws_bill_cdemo_sk,
           ws_quantity,
           ws_ext_sales_price,
           ws_net_profit
    FROM web_sales TABLESAMPLE BERNOULLI (10)
),
ws_expanded AS (
    SELECT cd.cd_demo_sk,
           CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_category,
           u.idx,
           CASE u.idx WHEN 1 THEN 'quantity' WHEN 2 THEN 'ext_sales_price' END AS metric_name,
           u.metric_value
    FROM ws_sample ws
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN UNNEST(ARRAY[ws.ws_quantity, ws.ws_ext_sales_price]) WITH ORDINALITY AS u(metric_value, idx)
),
ws_agg AS (
    SELECT gender_category,
           CAST(SUM(metric_value) AS double) AS total_metric
    FROM ws_expanded
    GROUP BY gender_category
),
sr_sample AS (
    SELECT sr_cdemo_sk,
           sr_return_quantity,
           sr_return_amt,
           sr_net_loss
    FROM store_returns TABLESAMPLE BERNOULLI (5)
),
sr_join AS (
    SELECT cd.cd_demo_sk,
           CASE WHEN cd.cd_credit_rating = 'Excellent' THEN 'High' ELSE 'Low' END AS credit_category,
           sr.sr_return_quantity,
           sr.sr_return_amt,
           sr.sr_net_loss
    FROM sr_sample sr
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
),
sr_agg AS (
    SELECT credit_category,
           CAST(SUM(sr_net_loss) AS double) AS total_metric
    FROM sr_join
    GROUP BY credit_category
)
SELECT gender_category,
       total_metric
FROM ws_agg
EXCEPT
SELECT credit_category,
       total_metric
FROM sr_agg
ORDER BY gender_category
OFFSET 0
LIMIT 100
