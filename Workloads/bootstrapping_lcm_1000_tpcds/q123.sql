SELECT
    (d_sold.d_year * 100 + d_sold.d_month_seq) AS year_month_key,
    s.s_state,
    wp.wp_type,
    CASE
        WHEN hd_bill.hd_income_band_sk IS NULL THEN 'Unknown'
        ELSE CAST(hd_bill.hd_income_band_sk AS VARCHAR)
    END AS income_band,
    COUNT(*) AS order_count,
    SUM(cs.cs_sales_price * cs.cs_quantity) AS total_sales_amount,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(hd_ship.hd_vehicle_count) AS total_vehicle_count
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
WHERE cs.cs_sales_price > 0
GROUP BY
    (d_sold.d_year * 100 + d_sold.d_month_seq),
    s.s_state,
    wp.wp_type,
    CASE
        WHEN hd_bill.hd_income_band_sk IS NULL THEN 'Unknown'
        ELSE CAST(hd_bill.hd_income_band_sk AS VARCHAR)
    END
HAVING SUM(cs.cs_sales_price) > 5000
ORDER BY total_sales_amount DESC
LIMIT 50
