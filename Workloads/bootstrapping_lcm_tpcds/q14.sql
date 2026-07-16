SELECT
    s.s_store_id,
    s.s_store_name,
    d_inv.d_year,
    d_inv.d_moy,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    COUNT(CASE WHEN d_sales.d_year > d_inv.d_year THEN 1 END) AS customers_sales_later_year,
    ROUND(
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) * 1.0 /
        NULLIF(SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END), 0),
        2
    ) AS male_female_ratio,
    MIN(d_inv.d_date) AS earliest_date,
    MAX(d_sales.d_date) AS latest_sales_date
FROM inventory i
JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_inv.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_inv.d_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_inv.d_year,
    d_inv.d_moy
HAVING SUM(i.inv_quantity_on_hand) > 0
ORDER BY total_inventory_qty DESC
LIMIT 20
