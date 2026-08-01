WITH joined_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cc.cc_name,
        cc.cc_tax_percentage,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_city,
        site.web_name,
        d_sold.d_date,
        d_sold.d_year,
        d_ship.d_date AS ship_date,
        d_ship.d_year AS ship_year
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    WHERE
        cc.cc_tax_percentage > 0.05
        AND cc.cc_name LIKE 'California%'
        AND c.c_preferred_cust_flag = 'Y'
        AND cd.cd_gender = 'F'
        AND d_sold.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
        AND ws.ws_ext_sales_price > 1000
        AND ws.ws_net_profit > (
            SELECT AVG(ws2.ws_net_profit)
            FROM web_sales ws2
            WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
        )
),
agg_data AS (
    SELECT
        cc_name,
        w_warehouse_name,
        w_city,
        web_name,
        d_year,
        ws_warehouse_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM joined_data
    GROUP BY
        cc_name,
        w_warehouse_name,
        w_city,
        web_name,
        d_year,
        ws_warehouse_sk
)
SELECT
    a.cc_name,
    a.w_warehouse_name,
    a.w_city,
    a.web_name,
    a.d_year AS sold_year,
    a.total_sales,
    a.avg_profit,
    a.distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY a.w_warehouse_name ORDER BY a.total_sales DESC) AS warehouse_sales_rank,
    (SELECT COUNT(*) FROM web_sales ws3 WHERE ws3.ws_warehouse_sk = a.ws_warehouse_sk) AS total_orders_in_warehouse
FROM agg_data a
ORDER BY a.total_sales DESC
LIMIT 100
