WITH sales_summary AS (
    SELECT
        d_sold.d_date AS sold_date,
        d_sold.d_year,
        d_sold.d_month_seq,
        store.s_store_id,
        store.s_city,
        store.s_state,
        web_page.wp_type,
        COUNT(DISTINCT web_sales.ws_order_number) AS order_count,
        SUM(web_sales.ws_quantity) AS total_quantity_sold,
        SUM(web_sales.ws_ext_sales_price) AS total_sales_amount,
        SUM(web_sales.ws_net_profit) AS total_net_profit,
        COALESCE(SUM(web_returns.wr_return_quantity), 0) AS total_quantity_returned,
        COALESCE(SUM(web_returns.wr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(web_returns.wr_net_loss), 0) AS total_net_loss,
        (SUM(web_sales.ws_ext_sales_price) - COALESCE(SUM(web_returns.wr_return_amt), 0)) AS net_sales_after_returns,
        CASE WHEN SUM(web_sales.ws_quantity) > 0 THEN
            (SUM(web_sales.ws_ext_sales_price) - COALESCE(SUM(web_returns.wr_return_amt), 0)) / SUM(web_sales.ws_quantity)
        END AS avg_net_price_per_item
    FROM web_sales
    JOIN date_dim AS d_sold
        ON web_sales.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim AS d_ship
        ON web_sales.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page
        ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
    JOIN date_dim AS d_creation
        ON web_page.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim AS d_access
        ON web_page.wp_access_date_sk = d_access.d_date_sk
    LEFT JOIN web_returns
        ON web_returns.wr_order_number = web_sales.ws_order_number
       AND web_returns.wr_item_sk = web_sales.ws_item_sk
       AND web_returns.wr_web_page_sk = web_page.wp_web_page_sk
    LEFT JOIN date_dim AS d_returned
        ON web_returns.wr_returned_date_sk = d_returned.d_date_sk
    JOIN store
        ON store.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2022
    GROUP BY
        d_sold.d_date,
        d_sold.d_year,
        d_sold.d_month_seq,
        store.s_store_id,
        store.s_city,
        store.s_state,
        web_page.wp_type
)
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY net_sales_after_returns DESC) AS sales_rank
FROM sales_summary
ORDER BY sales_rank
LIMIT 100
