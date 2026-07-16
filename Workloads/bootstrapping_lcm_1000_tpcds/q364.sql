WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        wsite.web_site_id,
        wsite.web_name,
        wsite.web_city,
        wsite.web_state,
        d_sold.d_year,
        d_sold.d_month_seq,
        sum(ws.ws_ext_sales_price) AS total_sales_price,
        sum(ws.ws_quantity) AS total_quantity_sold,
        sum(ws.ws_net_profit) AS total_net_profit,
        sum(cr.cr_return_amount) AS total_return_amount,
        sum(cr.cr_return_quantity) AS total_return_quantity,
        sum(cr.cr_net_loss) AS total_net_loss,
        avg(date_diff('day', d_ship.d_date, d_sold.d_date)) AS avg_days_between_sale_and_ship,
        max(d_site_open.d_date) AS site_open_date,
        max(d_site_close.d_date) AS site_close_date
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sold.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d_site_open ON wsite.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close ON wsite.web_close_date_sk = d_site_close.d_date_sk
    WHERE d_sold.d_year BETWEEN 2000 AND 2005
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        wsite.web_site_id,
        wsite.web_name,
        wsite.web_city,
        wsite.web_state,
        d_sold.d_year,
        d_sold.d_month_seq
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.store_city,
    a.store_state,
    a.web_site_id,
    a.web_name,
    a.web_city,
    a.web_state,
    a.d_year,
    a.d_month_seq,
    a.total_sales_price,
    a.total_quantity_sold,
    a.total_net_profit,
    a.total_return_amount,
    a.total_return_quantity,
    a.total_net_loss,
    a.avg_days_between_sale_and_ship,
    a.total_sales_price - a.total_return_amount AS net_sales_minus_returns,
    a.total_return_quantity / nullif(a.total_quantity_sold, 0) AS return_quantity_ratio,
    date_diff('day', a.site_open_date, a.site_close_date) AS site_lifespan_days,
    rank() OVER (PARTITION BY a.d_year ORDER BY a.total_net_profit DESC) AS profit_rank_by_year
FROM aggregated a
ORDER BY a.total_net_profit DESC
LIMIT 100
