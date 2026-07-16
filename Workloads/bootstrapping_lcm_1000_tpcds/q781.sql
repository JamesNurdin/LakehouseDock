WITH aggregated AS (
    SELECT
        d_sold.d_year AS sale_year,
        s.s_store_name,
        w_open.web_name AS open_site_name,
        w_close.web_name AS close_site_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        COUNT(DISTINCT cr.cr_order_number) AS total_returns,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cr.cr_return_quantity) AS total_quantity_returned,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_site w_open
        ON w_open.web_open_date_sk = d_sold.d_date_sk
    JOIN web_site w_close
        ON w_close.web_close_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year BETWEEN 2000 AND 2002
    GROUP BY
        d_sold.d_year,
        s.s_store_name,
        w_open.web_name,
        w_close.web_name
)
SELECT
    sale_year,
    s_store_name,
    open_site_name,
    close_site_name,
    total_net_profit,
    total_net_loss,
    total_orders,
    total_returns,
    total_quantity_sold,
    total_quantity_returned,
    avg_sales_price,
    avg_return_amount,
    total_net_profit / NULLIF(total_orders, 0) AS profit_per_order,
    total_net_loss / NULLIF(total_returns, 0) AS loss_per_return,
    ROW_NUMBER() OVER (PARTITION BY sale_year ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY sale_year, profit_rank
LIMIT 100
