WITH combined_sales AS (
    SELECT
        t.t_hour AS hour_of_day,
        i.i_category AS category,
        ss.ss_sales_price * ss.ss_quantity AS sales_amount,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS qty
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
      AND i.i_brand = 'BrandX'
      AND c.c_preferred_cust_flag = 'Y'
    UNION ALL
    SELECT
        t.t_hour AS hour_of_day,
        i.i_category AS category,
        ws.ws_sales_price * ws.ws_quantity AS sales_amount,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS qty
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
      AND i.i_brand = 'BrandX'
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    hour_of_day,
    category,
    SUM(sales_amount) AS total_sales,
    SUM(net_profit) AS total_profit,
    SUM(qty) AS total_qty,
    ROUND(SUM(net_profit) / NULLIF(SUM(sales_amount), 0), 2) AS profit_margin,
    RANK() OVER (ORDER BY SUM(net_profit) DESC) AS profit_rank
FROM combined_sales
GROUP BY hour_of_day, category
HAVING SUM(sales_amount) > 10000
ORDER BY profit_rank
LIMIT 10
