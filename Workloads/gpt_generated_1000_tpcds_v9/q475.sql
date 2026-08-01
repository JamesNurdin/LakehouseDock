WITH agg_inventory AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
agg_returns AS (
    SELECT sr.sr_customer_sk,
           SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    GROUP BY sr.sr_customer_sk
),
agg_sales AS (
    SELECT
        wp.wp_url,
        w.w_warehouse_name,
        agg.total_qty_on_hand,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COALESCE(r.total_return_amount, 0) AS total_return_amount
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN agg_inventory agg ON w.w_warehouse_sk = agg.inv_warehouse_sk
    LEFT JOIN agg_returns r ON c.c_customer_sk = r.sr_customer_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    WHERE
        w.w_country = 'United States'
        AND wp.wp_link_count > 10
        AND wp.wp_rec_start_date >= DATE '2000-01-01'
        AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
        AND t_ws.t_hour BETWEEN 12 AND 14
    GROUP BY
        wp.wp_url,
        w.w_warehouse_name,
        agg.total_qty_on_hand,
        r.total_return_amount
)
SELECT
    wp_url,
    w_warehouse_name,
    total_qty_on_hand,
    total_sales_amount,
    total_net_profit,
    total_return_amount,
    total_net_profit - total_return_amount AS net_gain,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_net_profit DESC) AS warehouse_profit_rank
FROM agg_sales
ORDER BY profit_rank
LIMIT 100
