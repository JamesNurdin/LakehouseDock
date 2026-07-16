SELECT
    d_sold.d_year,
    d_sold.d_moy AS sale_month,
    d_ship.d_moy AS ship_month,
    s.s_state,
    ca_bill.ca_country AS billing_country,
    ca_ship.ca_country AS shipping_country,
    p.p_promo_name,
    p.p_channel_tv,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(*) AS order_count,
    AVG(cs.cs_quantity) AS avg_quantity,
    CASE
        WHEN SUM(cs.cs_quantity) = 0 THEN NULL
        ELSE SUM(cs.cs_net_paid) / SUM(cs.cs_quantity)
    END AS avg_price_per_item
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND p.p_channel_tv = 'Y'
  AND d_p_start.d_date <= d_sold.d_date
  AND d_p_end.d_date >= d_sold.d_date
GROUP BY
    d_sold.d_year,
    d_sold.d_moy,
    d_ship.d_moy,
    s.s_state,
    ca_bill.ca_country,
    ca_ship.ca_country,
    p.p_promo_name,
    p.p_channel_tv
ORDER BY total_net_paid DESC
LIMIT 100
