WITH brand_year_sales AS (
    SELECT
        i.i_brand,
        d1.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit
    FROM
        store_sales ss
        JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
        JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN catalog_sales cs ON
            cs.cs_sold_date_sk = d1.d_date_sk
            AND cs.cs_sold_time_sk = t1.t_time_sk
            AND cs.cs_item_sk = i.i_item_sk
            AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
            AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
            AND cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws ON
            ws.ws_sold_date_sk = d1.d_date_sk
            AND ws.ws_sold_time_sk = t1.t_time_sk
            AND ws.ws_item_sk = i.i_item_sk
            AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
            AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
            AND ws.ws_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        d1.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        AND i.i_brand = 'Brand#45'
        AND cd.cd_gender = 'M'
        AND hd.hd_buy_potential = '>10000'
        AND sm.sm_type = 'AIR'
    GROUP BY
        i.i_brand,
        d1.d_year
)
SELECT
    i_brand AS brand,
    AVG(total_profit) AS avg_yearly_profit,
    SUM(total_sales) AS sum_sales_across_years,
    SUM(order_cnt) AS total_orders
FROM
    brand_year_sales
GROUP BY
    i_brand
HAVING
    AVG(total_profit) > 1000
ORDER BY
    avg_yearly_profit DESC
LIMIT 100
