WITH sales_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        wp.wp_type,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY d.d_year, d.d_month_seq, wp.wp_type
),
returns_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        wp.wp_type,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_quantity_returned
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY d.d_year, d.d_month_seq, wp.wp_type
),
inventory_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.wp_type,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_quantity_sold,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    i.total_inventory_quantity
FROM sales_by_month s
LEFT JOIN returns_by_month r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.wp_type = r.wp_type
LEFT JOIN inventory_by_month i
    ON s.d_year = i.d_year
    AND s.d_month_seq = i.d_month_seq
ORDER BY s.d_year, s.d_month_seq, s.wp_type
