WITH base AS (
    SELECT
        c.c_customer_id,
        i.i_category,
        d_sales.d_year,
        ss.ss_net_profit                  AS store_net_profit,
        ws.ws_net_profit                  AS web_net_profit,
        inv.inv_quantity_on_hand          AS inventory_qty,
        ib.ib_lower_bound,
        p.p_discount_active,
        sm.sm_type,
        cp.cp_type,
        sr.sr_return_quantity
    FROM
        store_sales ss
        JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
        JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                             AND sr.sr_item_sk = ss.ss_item_sk
        JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
        JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                           AND inv.inv_date_sk = d_sales.d_date_sk
        JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
        JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
        JOIN date_dim d_cp ON cp.cp_end_date_sk = d_cp.d_date_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                         AND ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
        JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                             AND wr.wr_item_sk = i.i_item_sk
        JOIN date_dim d_wr_ret ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
        JOIN time_dim t_wr_ret ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
    WHERE
        d_sales.d_year = 2001
        AND i.i_current_price > 20
        AND p.p_discount_active = 'Y'
        AND ib.ib_lower_bound >= 60000
        AND sm.sm_type = 'AIR'
        AND cp.cp_type = 'monthly'
        AND sr.sr_return_quantity > 0
),
agg AS (
    SELECT
        c_customer_id,
        i_category,
        d_year,
        SUM(store_net_profit) AS store_net_profit,
        SUM(web_net_profit)   AS web_net_profit,
        SUM(inventory_qty)    AS total_inventory,
        SUM(store_net_profit) + SUM(web_net_profit) AS total_net_profit
    FROM base
    GROUP BY c_customer_id, i_category, d_year
)
SELECT
    c_customer_id,
    i_category,
    d_year,
    store_net_profit,
    web_net_profit,
    total_inventory,
    total_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (
        PARTITION BY d_year
        ORDER BY total_net_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
