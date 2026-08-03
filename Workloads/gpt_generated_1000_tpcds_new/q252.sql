WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        p.p_discount_active,
        hd.hd_vehicle_count,
        we.web_mkt_id,
        i.i_current_price,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ws.ws_net_profit,
        ss.ss_sold_date_sk,
        ws.ws_sold_date_sk,
        ss.ss_sold_time_sk,
        ws.ws_sold_time_sk,
        cr.cr_returned_date_sk,
        cc.cc_call_center_sk,
        inv.inv_quantity_on_hand,
        wp.wp_web_page_sk,
        we.web_site_sk
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE
        d.d_year = 1910
        AND hd.hd_vehicle_count >= 1
        AND we.web_mkt_id IN (1, 2, 3)
        AND p.p_discount_active = 'Y'
        AND i.i_current_price > 100
),
order_set AS (
    SELECT ss.ss_ticket_number AS order_id
    FROM tpcds.store_sales ss
    EXCEPT
    SELECT wr.wr_order_number AS order_id
    FROM tpcds.web_returns wr
),
base_nr AS (
    SELECT b.*
    FROM base b
    JOIN order_set os
        ON b.ss_ticket_number = os.order_id
),
agg1 AS (
    SELECT
        d_year,
        i_brand,
        SUM(ss_net_profit) AS ss_profit,
        SUM(ws_net_profit) AS ws_profit,
        COUNT(*) AS txn_cnt
    FROM base_nr
    GROUP BY d_year, i_brand
),
agg2 AS (
    SELECT
        d_year,
        i_brand,
        profit_type,
        profit_amount
    FROM (
        SELECT
            d_year,
            i_brand,
            ARRAY[ss_profit, ws_profit] AS profit_arr,
            ARRAY['store', 'web'] AS type_arr
        FROM agg1
    ) t
    CROSS JOIN UNNEST(t.profit_arr, t.type_arr) AS u(profit_amount, profit_type)
)
SELECT
    d_year,
    i_brand,
    profit_type,
    AVG(profit_amount) AS avg_profit,
    SUM(profit_amount) AS total_profit
FROM agg2
GROUP BY d_year, i_brand, profit_type
ORDER BY d_year DESC, i_brand, profit_type
