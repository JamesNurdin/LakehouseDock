SELECT
    ca.ca_county,
    ca.ca_state,
    cd.cd_gender,
    d_sales.d_year,
    CASE
        WHEN ss.ss_net_profit > 0 THEN 'Profit'
        WHEN ss.ss_net_profit = 0 THEN 'Break-even'
        ELSE 'Loss'
    END AS profit_category,
    CASE
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    MIN(d_sales.d_date) AS first_sale_date,
    MAX(t.t_hour) AS max_hour
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
WHERE ca.ca_county IN ('Williams County', 'York County')
  AND ca.ca_state = 'TX'
  AND cd.cd_gender = 'M'
  AND d_sales.d_year = 2001
  AND t.t_hour BETWEEN 9 AND 17
  AND cp.cp_department = 'Electronics'
GROUP BY
    ca.ca_county,
    ca.ca_state,
    cd.cd_gender,
    d_sales.d_year,
    CASE
        WHEN ss.ss_net_profit > 0 THEN 'Profit'
        WHEN ss.ss_net_profit = 0 THEN 'Break-even'
        ELSE 'Loss'
    END,
    CASE
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END
ORDER BY total_sales DESC
LIMIT 100
