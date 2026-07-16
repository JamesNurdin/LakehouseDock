SELECT
    ship_date.d_year AS ship_year,
    ship_date.d_moy AS ship_month,
    cd_ship.cd_gender AS ship_gender,
    cd_ship.cd_marital_status AS ship_marital_status,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    AVG(date_diff('day', sold_date.d_date, ship_date.d_date)) AS avg_ship_delay_days,
    SUM(cs.cs_ext_sales_price) AS total_sales
FROM catalog_sales cs
JOIN date_dim ship_date
    ON cs.cs_ship_date_sk = ship_date.d_date_sk
JOIN date_dim sold_date
    ON cs.cs_sold_date_sk = sold_date.d_date_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
WHERE ship_date.d_year = 2002
  AND ship_date.d_quarter_name = 'Q4'
  AND cd_bill.cd_credit_rating = 'Excellent'
  AND cd_bill.cd_purchase_estimate > 500
  AND cs.cs_quantity >= 2
  AND cs.cs_ext_discount_amt > 0
GROUP BY
    ship_date.d_year,
    ship_date.d_moy,
    cd_ship.cd_gender,
    cd_ship.cd_marital_status
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 10
