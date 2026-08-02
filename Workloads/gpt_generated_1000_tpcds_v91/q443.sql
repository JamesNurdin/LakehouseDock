WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
),
sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_gmt_offset,
        site.web_name AS site_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
        SUM(COALESCE(ia.total_qty_on_hand, 0)) AS total_qty_on_hand
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN inv_agg ia
        ON ia.inv_warehouse_sk = w.w_warehouse_sk
       AND ia.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_page cp_start
        ON cp_start.cp_start_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_page cp_end
        ON cp_end.cp_end_date_sk = d_ship.d_date_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN web_sales ws2
            ON wr2.wr_order_number = ws2.ws_order_number
           AND wr2.wr_item_sk = ws2.ws_item_sk
        WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
    )
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_gmt_offset,
        site.web_name,
        d_sold.d_year,
        d_sold.d_month_seq
)
SELECT
    sa.w_warehouse_name,
    sa.w_city,
    sa.site_name,
    sa.d_year,
    sa.d_month_seq,
    CASE WHEN sa.w_gmt_offset > 0 THEN 'Eastern' ELSE 'Western' END AS region,
    sa.total_net_profit,
    sa.total_return_loss,
    sa.total_qty_on_hand,
    (SELECT COUNT(*) FROM web_sales) AS total_sales_count,
    ROW_NUMBER() OVER (PARTITION BY sa.w_warehouse_sk ORDER BY sa.total_net_profit DESC) AS warehouse_rank
FROM sales_agg sa
ORDER BY sa.total_net_profit DESC
LIMIT 100
