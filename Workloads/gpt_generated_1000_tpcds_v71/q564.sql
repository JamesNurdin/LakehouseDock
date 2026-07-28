WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        d_sales.d_year,
        d_sales.d_month_seq,
        cc.cc_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit)               AS store_net_profit,
        SUM(ws.ws_net_profit)               AS web_net_profit,
        SUM(inv.inv_quantity_on_hand)       AS inventory_qty,
        (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) AS total_profit,
        RANK() OVER (PARTITION BY d_sales.d_year, d_sales.d_month_seq
                     ORDER BY (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) DESC) AS profit_rank
    FROM
        store_sales ss
        JOIN date_dim d_sales
            ON ss.ss_sold_date_sk = d_sales.d_date_sk
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN date_dim d_sr_return
            ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
        JOIN web_sales ws
            ON ws.ws_item_sk = i.i_item_sk
            AND ws.ws_sold_date_sk = d_sales.d_date_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
        JOIN date_dim d_wr_return
            ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
        JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d_sales.d_date_sk
        JOIN household_demographics hd2
            ON hd.hd_demo_sk = hd2.hd_demo_sk
        JOIN income_band ib
            ON hd2.hd_income_band_sk = ib.ib_income_band_sk
        JOIN call_center cc
            ON cc.cc_open_date_sk = d_sales.d_date_sk
            AND cc.cc_closed_date_sk = d_sr_return.d_date_sk
    WHERE
        d_sales.d_year = 2001
        AND i.i_current_price > 50.00
        AND ib.ib_upper_bound < 50000
    GROUP BY
        i.i_item_id,
        i.i_category,
        d_sales.d_year,
        d_sales.d_month_seq,
        cc.cc_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    i_item_id,
    i_category,
    d_year,
    d_month_seq,
    cc_name,
    ib_lower_bound,
    ib_upper_bound,
    store_net_profit,
    web_net_profit,
    inventory_qty,
    total_profit,
    profit_rank
FROM sales_agg
ORDER BY profit_rank ASC, total_profit DESC
LIMIT 100
