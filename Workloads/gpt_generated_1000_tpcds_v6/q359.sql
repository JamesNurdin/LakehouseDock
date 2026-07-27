WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        c.c_birth_country,
        hd.hd_buy_potential,
        d_sold.d_year AS sold_year,
        d_ship.d_month_seq,
        site.web_name,
        w.w_warehouse_name,
        s.s_store_name
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year = 2001
      AND d_ship.d_month_seq BETWEEN 1200 AND 1210
      AND c.c_birth_country IN ('KOREA', 'FIJI')
      AND hd.hd_buy_potential = '5001-10000'
      AND ws.ws_net_paid_inc_tax > 500
)
SELECT
    agg.s_store_name,
    agg.w_warehouse_name,
    agg.web_name,
    agg.sold_year,
    agg.orders_cnt,
    agg.total_qty,
    agg.avg_net_paid,
    agg.min_net_paid,
    agg.max_net_paid,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_name ORDER BY agg.orders_cnt DESC) AS rn
FROM (
    SELECT
        s_store_name,
        w_warehouse_name,
        web_name,
        sold_year,
        ws_web_site_sk,
        COUNT(DISTINCT ws_order_number) AS orders_cnt,
        SUM(ws_quantity) AS total_qty,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid,
        MIN(ws_net_paid_inc_tax) AS min_net_paid,
        MAX(ws_net_paid_inc_tax) AS max_net_paid
    FROM sales_data
    WHERE EXISTS (
        SELECT 1
        FROM call_center cc
        JOIN date_dim d_cc
            ON cc.cc_closed_date_sk = d_cc.d_date_sk
        WHERE cc.cc_name = 'Call Center 1'
          AND d_cc.d_year = 2001
          AND cc.cc_market_manager = 'John Doe'
          AND cc.cc_gmt_offset = 5.00
    )
    GROUP BY s_store_name, w_warehouse_name, web_name, sold_year, ws_web_site_sk
) agg
ORDER BY agg.orders_cnt DESC
LIMIT 100
