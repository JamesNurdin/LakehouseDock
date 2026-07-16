SELECT
    d_sold.d_year AS sold_year,
    cp.cp_department AS department,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
FROM
    catalog_sales cs
JOIN
    date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN
    catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN
    promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
JOIN
    customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN
    date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN
    inventory inv
      ON inv.inv_date_sk = d_ship.d_date_sk
WHERE
    cp.cp_type = 'monthly'
    AND p.p_cost > 5000
    AND cd.cd_marital_status = 'M'
    AND cd.cd_education_status = 'College'
    AND d_sold.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_sold.d_year,
    cp.cp_department
HAVING
    SUM(cs.cs_net_profit) > 10000
ORDER BY
    total_net_profit DESC
LIMIT 100
