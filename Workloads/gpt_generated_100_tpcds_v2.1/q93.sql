WITH sales_by_demo_hour AS (
    SELECT
        cd_bill.cd_credit_rating AS bill_credit_rating,
        cd_bill.cd_marital_status AS bill_marital_status,
        t_dim.t_hour AS sale_hour,
        COUNT(*) AS order_count,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amt
    FROM catalog_sales cs
    JOIN time_dim t_dim
        ON cs.cs_sold_time_sk = t_dim.t_time_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE cd_bill.cd_credit_rating IN ('Good', 'Low Risk')
      AND cd_bill.cd_marital_status = 'S'
      AND cd_ship.cd_marital_status = 'M'
      AND cs.cs_net_paid_inc_tax > 1000
      AND cs.cs_ext_list_price BETWEEN 500 AND 10000
      AND t_dim.t_am_pm = 'PM'
      AND t_dim.t_second >= 10
    GROUP BY
        cd_bill.cd_credit_rating,
        cd_bill.cd_marital_status,
        t_dim.t_hour
)
SELECT
    bill_credit_rating,
    bill_marital_status,
    SUM(total_net_paid_inc_tax) AS sum_net_paid_inc_tax,
    AVG(order_count) AS avg_orders_per_hour,
    COUNT(*) AS hour_groups
FROM sales_by_demo_hour
GROUP BY
    bill_credit_rating,
    bill_marital_status
HAVING SUM(total_net_paid_inc_tax) > 5000
ORDER BY sum_net_paid_inc_tax DESC
LIMIT 100
