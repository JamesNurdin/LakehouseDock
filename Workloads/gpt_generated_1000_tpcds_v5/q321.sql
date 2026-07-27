WITH sales_agg AS (
    SELECT
        d_sold.d_year AS sales_year,
        cc.cc_state AS state,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_sales,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 100000 THEN 'High' ELSE 'Medium' END AS profit_level,
        (
            SELECT AVG(ws2.ws_ext_sales_price)
            FROM web_sales ws2
        ) AS overall_avg_sales
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer cust
        ON ws.ws_bill_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_size = 'large'
      AND t.t_hour BETWEEN 9 AND 17
      AND cc.cc_state = 'CA'
      AND ws.ws_ext_sales_price > 100
    GROUP BY d_sold.d_year, cc.cc_state, i.i_category
)
SELECT
    sales_year,
    state,
    category,
    total_sales,
    avg_sales,
    order_cnt,
    total_profit,
    profit_level,
    overall_avg_sales,
    SUM(total_sales) OVER (PARTITION BY sales_year ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_category
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
