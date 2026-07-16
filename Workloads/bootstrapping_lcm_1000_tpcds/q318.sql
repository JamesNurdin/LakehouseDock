SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    s.s_state,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_ship.cd_education_status,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_net_profit) AS avg_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay,
    CASE
        WHEN SUM(cs.cs_net_paid) > 200000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_paid) > 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS revenue_category,
    (SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_net_paid), 0)) AS discount_ratio
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
    AND wp.wp_access_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year BETWEEN 1998 AND 2000
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_ship.cd_education_status,
    wp.wp_type
HAVING SUM(cs.cs_net_paid) > 50000
ORDER BY total_net_paid DESC
LIMIT 100
