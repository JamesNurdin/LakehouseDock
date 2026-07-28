WITH joined AS (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_quantity,
        sm.sm_type,
        w.w_warehouse_name,
        s.s_store_name,
        wp.wp_type AS web_page_type,
        cp.cp_type AS catalog_page_type,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        t.t_hour,
        CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                              AND inv.inv_date_sk = d.d_date_sk
                              AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                                 AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                               AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND hd.hd_buy_potential = '1001-5000'
      AND sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 8 AND 12
)
SELECT
    d_year,
    i_category,
    i_brand,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(CASE WHEN ws_net_profit > 0 THEN ws_ext_sales_price ELSE 0 END) AS profit_sales,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
FROM joined
GROUP BY ROLLUP (d_year, i_category, i_brand)
ORDER BY d_year, i_category, i_brand
LIMIT 100
