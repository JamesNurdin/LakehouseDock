WITH base AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_category AS i_category,
        i.i_current_price,
        cd.cd_marital_status,
        ca.ca_location_type,
        s.s_country,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        cr.cr_net_loss,
        sr.sr_net_loss,
        ws.ws_net_paid,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_paid_inc_ship,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_ext_ship_cost,
        td.t_hour,
        td.t_meal_time,
        wp.wp_type,
        web.web_state,
        i.i_rec_start_date,
        i.i_rec_end_date
    FROM time_dim td
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON i.i_item_sk = cr.cr_item_sk
    JOIN store s ON s.s_store_sk = sr.sr_store_sk
    JOIN customer c1 ON c1.c_customer_sk = cr.cr_refunded_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    JOIN customer_address ca ON ca.ca_address_sk = cr.cr_refunded_addr_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site web ON web.web_site_sk = ws.ws_web_site_sk
    WHERE i.i_current_price > 20.00
      AND cd.cd_marital_status = 'M'
      AND ca.ca_location_type = 'single family'
      AND s.s_country = 'United States'
      AND ws.ws_net_profit > 0
      AND web.web_state = 'CA'
      AND i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_end_date < DATE '2002-01-01'
)
SELECT
    store_id,
    i_category,
    SUM(total_loss) AS sum_total_loss,
    AVG(profit) AS avg_profit,
    RANK() OVER (ORDER BY SUM(total_loss) DESC) AS loss_rank
FROM (
    SELECT
        store_id,
        i_category,
        (COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0) - COALESCE(ws_net_profit, 0)) AS total_loss,
        ws_net_profit AS profit
    FROM base
) t
GROUP BY store_id, i_category
HAVING SUM(total_loss) > 1000
ORDER BY sum_total_loss DESC
LIMIT 100
