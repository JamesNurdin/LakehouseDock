SELECT
    sm.sm_type AS ship_mode_type,
    cd_bill.cd_marital_status AS billing_marital_status,
    cd_ship.cd_gender AS shipping_gender,
    COUNT(*) AS order_count,
    SUM(c.cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
    SUM(c.cs_net_profit) AS total_net_profit,
    AVG(c.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT c.cs_item_sk) AS distinct_items_sold
FROM
    catalog_sales c
JOIN
    customer_demographics cd_bill
    ON c.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN
    customer_demographics cd_ship
    ON c.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN
    ship_mode sm
    ON c.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    c.cs_ext_discount_amt BETWEEN 300.00 AND 1000.00
    AND c.cs_ship_date_sk BETWEEN 2450840 AND 2450900
    AND c.cs_net_paid_inc_ship_tax > 2000.00
GROUP BY
    sm.sm_type,
    cd_bill.cd_marital_status,
    cd_ship.cd_gender
HAVING
    SUM(c.cs_net_profit) > 0
ORDER BY
    total_net_profit DESC
LIMIT 100
