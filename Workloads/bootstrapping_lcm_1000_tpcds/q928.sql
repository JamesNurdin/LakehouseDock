SELECT
    s.s_state,
    s.s_city,
    sold_d.d_year AS sales_year,
    sold_d.d_month_seq AS sales_month,
    ship_d.d_month_seq AS ship_month,
    return_d.d_year AS return_year,
    return_d.d_month_seq AS return_month,
    refunded_cd.cd_gender AS refunded_gender,
    returning_cd.cd_marital_status AS returning_marital_status,
    bill_cd.cd_credit_rating AS bill_credit_rating,
    ship_cd.cd_education_status AS ship_education_status,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_net_loss) AS total_returns_loss,
    SUM(cs.cs_quantity) AS total_sales_quantity,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_sales_orders,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    AVG(date_diff('day', sold_d.d_date, ship_d.d_date)) AS avg_days_to_ship,
    CASE
        WHEN SUM(cs.cs_net_profit) > SUM(cr.cr_net_loss) THEN 'PROFITABLE'
        ELSE 'UNPROFITABLE'
    END AS profit_status,
    (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) AS net_gain,
    (SUM(cr.cr_return_quantity) / NULLIF(SUM(cs.cs_quantity), 0)) * 100 AS return_quantity_pct
FROM
    catalog_sales cs
    JOIN date_dim sold_d ON cs.cs_sold_date_sk = sold_d.d_date_sk
    JOIN date_dim ship_d ON cs.cs_ship_date_sk = ship_d.d_date_sk
    JOIN customer_demographics bill_cd ON cs.cs_bill_cdemo_sk = bill_cd.cd_demo_sk
    JOIN customer_demographics ship_cd ON cs.cs_ship_cdemo_sk = ship_cd.cd_demo_sk
    JOIN catalog_returns cr ON cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_order_number = cr.cr_order_number
    JOIN date_dim return_d ON cr.cr_returned_date_sk = return_d.d_date_sk
    JOIN customer_demographics refunded_cd ON cr.cr_refunded_cdemo_sk = refunded_cd.cd_demo_sk
    JOIN customer_demographics returning_cd ON cr.cr_returning_cdemo_sk = returning_cd.cd_demo_sk
    JOIN store s ON s.s_closed_date_sk = return_d.d_date_sk
WHERE
    sold_d.d_year BETWEEN 2000 AND 2002
    AND s.s_state IS NOT NULL
GROUP BY
    s.s_state,
    s.s_city,
    sold_d.d_year,
    sold_d.d_month_seq,
    ship_d.d_month_seq,
    return_d.d_year,
    return_d.d_month_seq,
    refunded_cd.cd_gender,
    returning_cd.cd_marital_status,
    bill_cd.cd_credit_rating,
    ship_cd.cd_education_status
HAVING
    SUM(cs.cs_net_profit) > 0
ORDER BY
    net_gain DESC
LIMIT 100
