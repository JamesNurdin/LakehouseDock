SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    store.s_state,
    hd_bill.hd_buy_potential,
    CASE WHEN web_page.wp_type = 'home' THEN 'Home' ELSE 'Other' END AS page_category,
    COUNT(*) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    SUM(CASE WHEN cs.cs_coupon_amt > 0 THEN 1 ELSE 0 END) AS orders_with_coupon,
    SUM(CASE WHEN d_ship.d_weekend = 'Y' THEN cs.cs_net_paid ELSE 0 END) AS weekend_net_paid,
    SUM(web_page.wp_image_count) AS total_image_count,
    AVG(web_page.wp_char_count) AS avg_char_count,
    SUM(store.s_floor_space) AS total_floor_space,
    AVG(hd_ship.hd_vehicle_count) AS avg_vehicle_count
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN store
    ON store.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page
    ON web_page.wp_creation_date_sk = d_sold.d_date_sk
    AND web_page.wp_access_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year BETWEEN 1999 AND 2001
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    store.s_state,
    hd_bill.hd_buy_potential,
    CASE WHEN web_page.wp_type = 'home' THEN 'Home' ELSE 'Other' END
HAVING COUNT(*) > 5
ORDER BY total_net_paid DESC
LIMIT 100
