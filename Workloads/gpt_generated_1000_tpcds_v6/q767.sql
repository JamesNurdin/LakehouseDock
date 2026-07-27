WITH date_info AS (
    SELECT d_date_sk, d_year, d_quarter_name
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
)
SELECT
    t.year,
    t.quarter,
    t.metric_type,
    t.amount,
    t.cnt,
    (
        SELECT AVG(cs.cs_sales_price)
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE i.i_brand = 'ableanti'
    ) AS avg_item_price
FROM (
    SELECT
        di.d_year AS year,
        di.d_quarter_name AS quarter,
        'sales' AS metric_type,
        SUM(cs.cs_net_paid) AS amount,
        COUNT(DISTINCT cs.cs_order_number) AS cnt
    FROM catalog_sales cs
    JOIN date_info di ON cs.cs_sold_date_sk = di.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_brand = 'ableanti'
    GROUP BY di.d_year, di.d_quarter_name

    UNION ALL

    SELECT
        di.d_year AS year,
        di.d_quarter_name AS quarter,
        'returns' AS metric_type,
        SUM(sr.sr_return_amt) AS amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS cnt
    FROM store_returns sr
    JOIN date_info di ON sr.sr_returned_date_sk = di.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_brand = 'ableanti'
    GROUP BY di.d_year, di.d_quarter_name
) t
ORDER BY t.year DESC, t.quarter, t.metric_type
LIMIT 100
