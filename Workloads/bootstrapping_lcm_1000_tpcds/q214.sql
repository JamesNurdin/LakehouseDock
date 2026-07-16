SELECT
    ds_sold.d_year AS sale_year,
    ds_sold.d_month_seq AS sale_month,
    s.s_state,
    CASE 
        WHEN cd_bill.cd_gender = 'M' THEN 'Male'
        WHEN cd_bill.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    wp.wp_type,
    CASE 
        WHEN date_diff('day', ds_sold.d_date, ds_ship.d_date) <= 7 THEN '0-7 days'
        WHEN date_diff('day', ds_sold.d_date, ds_ship.d_date) <= 30 THEN '8-30 days'
        ELSE '31+ days'
    END AS shipping_time_bucket,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(*) AS total_transactions
FROM catalog_sales cs
JOIN date_dim ds_sold
    ON cs.cs_sold_date_sk = ds_sold.d_date_sk
JOIN date_dim ds_ship
    ON cs.cs_ship_date_sk = ds_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = ds_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = ds_sold.d_date_sk
JOIN date_dim ds_wp_access
    ON wp.wp_access_date_sk = ds_wp_access.d_date_sk
WHERE ds_sold.d_year BETWEEN 2015 AND 2020
  AND s.s_state IS NOT NULL
  AND cd_bill.cd_gender IS NOT NULL
  AND ds_wp_access.d_year = ds_sold.d_year
GROUP BY 
    ds_sold.d_year,
    ds_sold.d_month_seq,
    s.s_state,
    CASE 
        WHEN cd_bill.cd_gender = 'M' THEN 'Male'
        WHEN cd_bill.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END,
    wp.wp_type,
    CASE 
        WHEN date_diff('day', ds_sold.d_date, ds_ship.d_date) <= 7 THEN '0-7 days'
        WHEN date_diff('day', ds_sold.d_date, ds_ship.d_date) <= 30 THEN '8-30 days'
        ELSE '31+ days'
    END
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY sale_year, sale_month, s.s_state, gender, shipping_time_bucket
