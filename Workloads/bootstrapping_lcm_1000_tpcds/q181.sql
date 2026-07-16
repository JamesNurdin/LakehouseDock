SELECT
    d_sales.d_year,
    CASE 
        WHEN d_sales.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_sales.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_sales.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter_label,
    s.s_division_name,
    hd.hd_buy_potential,
    wp.wp_type,
    CASE WHEN d_sales.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    MAX(d_closed.d_date) AS store_closed_date,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(CASE WHEN d_sales.d_holiday = 'Y' THEN ss.ss_ext_sales_price ELSE 0 END) AS holiday_sales,
    SUM(ss.ss_ext_sales_price) / NULLIF(SUM(ss.ss_quantity), 0) AS avg_price_per_quantity,
    SUM(ss.ss_ext_discount_amt) / NULLIF(SUM(ss.ss_ext_list_price), 0) AS discount_rate
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sales.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND hd.hd_buy_potential = 'HIGH'
GROUP BY
    d_sales.d_year,
    CASE 
        WHEN d_sales.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_sales.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_sales.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    s.s_division_name,
    hd.hd_buy_potential,
    wp.wp_type,
    CASE WHEN d_sales.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END
ORDER BY total_sales DESC
LIMIT 100
