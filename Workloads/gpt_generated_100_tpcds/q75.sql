WITH sales_agg AS (
    SELECT
        w.web_name AS web_site_name,
        d_sold.d_year,
        d_sold.d_moy AS month,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS discount_rate,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        COUNT(*) AS total_transactions
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d_open
        ON w.web_open_date_sk = d_open.d_date_sk
    LEFT JOIN date_dim d_close
        ON w.web_close_date_sk = d_close.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d_sold.d_year = 2022
      AND d_sold.d_date >= d_open.d_date
      AND (d_close.d_date IS NULL OR d_sold.d_date <= d_close.d_date)
    GROUP BY
        w.web_name,
        d_sold.d_year,
        d_sold.d_moy,
        i.i_category
)
SELECT
    web_site_name,
    d_year,
    month,
    i_category,
    total_sales,
    total_profit,
    total_discount,
    discount_rate,
    distinct_customers,
    total_transactions
FROM sales_agg
ORDER BY web_site_name, d_year, month, i_category
