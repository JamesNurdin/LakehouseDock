WITH male_demo AS (
    SELECT DISTINCT cd_demo_sk
    FROM customer_demographics
    WHERE cd_gender = 'M'
)
SELECT
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    p.p_promo_name,
    COUNT(DISTINCT c_bill.c_customer_id) AS unique_customers,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    (
        SELECT AVG(cs2.cs_ext_discount_amt)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_sold.d_year
    ) AS avg_discount_same_year
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN inventory inv_sold ON inv_sold.inv_date_sk = d_sold.d_date_sk
    AND inv_sold.inv_item_sk = cs.cs_item_sk
JOIN inventory inv_ship ON inv_ship.inv_date_sk = d_ship.d_date_sk
    AND inv_ship.inv_item_sk = cs.cs_item_sk
WHERE EXISTS (
    SELECT 1
    FROM male_demo md
    WHERE md.cd_demo_sk = cd_bill.cd_demo_sk
)
GROUP BY
    d_sold.d_year,
    d_ship.d_year,
    p.p_promo_name
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
