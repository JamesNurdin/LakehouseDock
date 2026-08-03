WITH filtered_store AS (
        SELECT s_store_sk,
               s_store_name,
               s_closed_date_sk
        FROM store
        WHERE s_store_sk IN (
            SELECT ss_store_sk
            FROM store_sales
            WHERE ss_quantity > 10
        )
    ),
    sampled_inventory AS (
        SELECT inv_date_sk,
               inv_item_sk,
               inv_warehouse_sk,
               inv_quantity_on_hand
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    )
SELECT
    d.d_date,
    c.c_customer_id,
    fs.s_store_name,
    ss.ss_net_paid,
    wss.ws_net_paid,
    (ss.ss_net_paid + wss.ws_net_paid) AS total_net_paid,
    RANK() OVER (PARTITION BY c.c_customer_id ORDER BY (ss.ss_net_paid + wss.ws_net_paid) DESC) AS sales_rank,
    (SELECT max(ib_upper_bound) FROM income_band) AS max_income_upper,
    wp_ret.total_returns
FROM date_dim d
JOIN customer c
    ON c.c_first_sales_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN filtered_store fs
    ON fs.s_closed_date_sk = d.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
   AND ss.ss_customer_sk = c.c_customer_sk
   AND ss.ss_store_sk = fs.s_store_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
JOIN sampled_inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
   AND wp.wp_customer_sk = c.c_customer_sk
JOIN LATERAL (
        SELECT SUM(wr.wr_return_quantity) AS total_returns
        FROM web_returns wr
        WHERE wr.wr_web_page_sk = wp.wp_web_page_sk
    ) wp_ret ON TRUE
JOIN web_sales wss
    ON wss.ws_sold_date_sk = d.d_date_sk
   AND wss.ws_bill_customer_sk = c.c_customer_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_order_number = wss.ws_order_number
JOIN ship_mode sm
    ON wss.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
WHERE
    d.d_year = 2001
    AND c.c_birth_month = 5
    AND t.t_sub_shift = 'morning'
    AND p.p_discount_active = 'Y'
    AND ib.ib_lower_bound >= 30000
ORDER BY total_net_paid DESC
LIMIT 100
