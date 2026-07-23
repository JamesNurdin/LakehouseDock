WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        td.t_time_sk,
        td.t_hour,
        i.i_item_sk,
        i.i_brand_id,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ca.ca_address_sk,
        ca.ca_state,
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        p.p_promo_sk,
        p.p_discount_active,
        inv.inv_quantity_on_hand,
        w.w_warehouse_sk,
        w.w_state,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_sales_price AS web_sales_amount,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        wr.wr_fee,
        wr.wr_return_quantity,
        ss.ss_ext_sales_price AS store_sales_amount,
        ss.ss_net_profit,
        CASE
            WHEN ss.ss_net_profit > 100 THEN 'High'
            WHEN ss.ss_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_item_sk = ss.ss_item_sk
           AND sr.sr_return_time_sk = td.t_time_sk
           AND sr.sr_customer_sk = c.c_customer_sk
           AND sr.sr_addr_sk = ca.ca_address_sk
           AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
           AND ws.ws_sold_time_sk = td.t_time_sk
           AND ws.ws_bill_customer_sk = c.c_customer_sk
           AND ws.ws_ship_customer_sk = c.c_customer_sk
           AND ws.ws_bill_addr_sk = ca.ca_address_sk
           AND ws.ws_ship_addr_sk = ca.ca_address_sk
           AND ws.ws_warehouse_sk = w.w_warehouse_sk
           AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = i.i_item_sk
           AND wr.wr_returned_time_sk = td.t_time_sk
           AND wr.wr_refunded_customer_sk = c.c_customer_sk
           AND wr.wr_refunded_addr_sk = ca.ca_address_sk
           AND wr.wr_returning_customer_sk = c.c_customer_sk
           AND wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND i.i_brand_id > 10
        AND c.c_birth_year BETWEEN 1970 AND 1990
        AND ca.ca_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND inv.inv_quantity_on_hand > 0
        AND ws.ws_quantity > 0
        AND wr.wr_fee > 10
),
store_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        td.t_time_sk,
        td.t_hour,
        base.profit_category,
        COUNT(DISTINCT base.ss_ticket_number) AS num_transactions,
        SUM(base.store_sales_amount) AS total_store_sales,
        SUM(COALESCE(base.web_sales_amount, 0)) AS total_web_sales,
        SUM(COALESCE(base.sr_return_quantity, 0)) AS total_store_return_qty,
        SUM(COALESCE(base.wr_return_quantity, 0)) AS total_web_return_qty,
        SUM(base.inv_quantity_on_hand) AS total_inventory,
        SUM(base.ss_net_profit) AS total_store_net_profit,
        SUM(COALESCE(base.ws_net_profit, 0)) AS total_web_net_profit,
        SUM(base.sr_net_loss) AS total_store_net_loss,
        SUM(COALESCE(base.wr_fee, 0)) AS total_web_return_fee
    FROM base
    JOIN store s ON base.s_store_sk = s.s_store_sk
    JOIN time_dim td ON base.t_time_sk = td.t_time_sk
    GROUP BY
        s.s_store_id,
        s.s_state,
        td.t_time_sk,
        td.t_hour,
        base.profit_category
)
SELECT
    sa.s_store_id,
    sa.s_state,
    sa.t_time_sk,
    sa.t_hour,
    sa.profit_category,
    sa.num_transactions,
    sa.total_store_sales,
    sa.total_web_sales,
    sa.total_store_return_qty,
    sa.total_web_return_qty,
    sa.total_inventory,
    sa.total_store_net_profit,
    sa.total_web_net_profit,
    SUM(sa.total_store_net_profit) OVER (PARTITION BY sa.s_store_id ORDER BY sa.t_time_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_store_net_profit,
    CASE WHEN SUM(sa.total_store_net_profit) OVER (PARTITION BY sa.s_store_id ORDER BY sa.t_time_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 5000 THEN 'Above Target' ELSE 'Below Target' END AS cum_profit_flag,
    (SELECT AVG(b.store_sales_amount) FROM base b) AS avg_store_sales_amount,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost
FROM store_agg sa
WHERE sa.total_store_net_profit > 1000
ORDER BY sa.s_store_id, sa.t_time_sk
