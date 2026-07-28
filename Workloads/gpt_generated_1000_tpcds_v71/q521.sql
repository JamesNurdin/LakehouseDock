WITH sales_cte AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_catalog_page_sk,
        cs.cs_net_profit AS profit,
        cs.cs_ext_sales_price AS ext_sales,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_net_profit > 0
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    cp.cp_department,
    ws.web_county,
    SUM(s.profit) AS total_profit,
    AVG(s.ext_sales) AS avg_ext_sales,
    COUNT(DISTINCT s.cs_order_number) AS distinct_orders,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_profit
FROM sales_cte s
JOIN date_dim d_sold
    ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON s.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer cust_bill
    ON s.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship
    ON s.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_address ca_bill
    ON s.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON s.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_start.d_date_sk
JOIN date_dim d_open
    ON ws.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
    ON ws.web_close_date_sk = d_close.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2001
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    cp.cp_department,
    ws.web_county
ORDER BY total_profit DESC
LIMIT 100
