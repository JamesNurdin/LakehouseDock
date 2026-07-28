WITH sales_agg AS (
    SELECT
        d.d_date AS d_date,
        c.c_customer_id AS c_customer_id,
        s.s_store_name AS s_store_name,
        i.i_item_id AS i_item_id,
        ws.ws_net_paid AS ws_net_paid,
        ss.ss_net_paid AS ss_net_paid,
        cr.cr_net_loss AS cr_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_size = 'large'
      AND s.s_state = 'CA'
      AND wsite.web_mkt_id IN (1, 3)
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    d_date,
    c_customer_id,
    s_store_name,
    i_item_id,
    SUM(ws_net_paid) OVER (PARTITION BY d_date) AS total_ws_net_paid_day,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY ws_net_paid DESC) AS rank_by_ws_net_paid,
    SUM(ss_net_paid) OVER (PARTITION BY d_date) AS total_ss_net_paid_day,
    SUM(cr_net_loss) OVER (PARTITION BY d_date) AS total_return_loss_day
FROM sales_agg
ORDER BY d_date DESC, rank_by_ws_net_paid
LIMIT 100
