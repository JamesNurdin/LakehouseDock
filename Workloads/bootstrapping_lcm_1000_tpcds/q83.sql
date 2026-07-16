SELECT
    cs.cs_item_sk,
    c_bill.c_customer_id AS bill_customer_id,
    c_ship.c_customer_id AS ship_customer_id,
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    p.p_promo_name,
    s.s_store_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS order_count,
    AVG(cs.cs_quantity) AS avg_quantity,
    (SUM(cs.cs_net_paid) - SUM(cs.cs_ext_discount_amt)) AS net_paid_minus_discount,
    SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0) AS profit_margin,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_cust_first_sales
    ON c_bill.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
WHERE d_sold.d_year = 2020
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    cs.cs_item_sk,
    c_bill.c_customer_id,
    c_ship.c_customer_id,
    d_sold.d_year,
    d_ship.d_month_seq,
    p.p_promo_name,
    s.s_store_name,
    p.p_discount_active
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
