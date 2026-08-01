WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        d_cs.d_year,
        d_cs.d_month_seq,
        SUM(cs.cs_net_profit) AS cs_net_profit,
        SUM(ss.ss_net_profit) AS ss_net_profit,
        SUM(ws.ws_net_profit) AS ws_net_profit,
        SUM(cr.cr_net_loss) AS cr_net_loss,
        SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) AS total_net_profit
    FROM
        catalog_sales cs
        JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN date_dim d_cs
            ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN customer c_bill
            ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer_demographics cd_bill
            ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN household_demographics hd_bill
            ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN income_band ib
            ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
        JOIN store_sales ss
            ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN date_dim d_store_closed
            ON s.s_closed_date_sk = d_store_closed.d_date_sk
        JOIN web_sales ws
            ON ws.ws_item_sk = i.i_item_sk
        JOIN date_dim d_ws
            ON ws.ws_sold_date_sk = d_ws.d_date_sk
        LEFT JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN date_dim d_wp_creation
            ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
        LEFT JOIN web_site wsite
            ON ws.ws_web_site_sk = wsite.web_site_sk
        LEFT JOIN date_dim d_web_open
            ON wsite.web_open_date_sk = d_web_open.d_date_sk
        LEFT JOIN ship_mode sm_cs
            ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
        LEFT JOIN ship_mode sm_ws
            ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        LEFT JOIN ship_mode sm_cr
            ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
        LEFT JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN date_dim d_cr
            ON cr.cr_returned_date_sk = d_cr.d_date_sk
    WHERE
        d_cs.d_year = 2002
        AND i.i_current_price > 50
        AND s.s_state = 'CA'
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        d_cs.d_year,
        d_cs.d_month_seq
)
SELECT
    s_store_sk,
    s_store_name,
    s_state,
    i_item_sk,
    i_product_name,
    i_current_price,
    d_year,
    d_month_seq,
    total_net_profit,
    CASE
        WHEN total_net_profit > 10000 THEN 'High'
        WHEN total_net_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY s_store_sk ORDER BY total_net_profit DESC) AS profit_rank,
    (SELECT SUM(cs_net_profit) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = sales_agg.i_item_sk) AS item_total_cs_profit,
    (SELECT SUM(cr_net_loss) FROM catalog_returns cr2 WHERE cr2.cr_item_sk = sales_agg.i_item_sk) AS item_total_return_loss
FROM
    sales_agg
ORDER BY
    profit_rank,
    total_net_profit DESC
LIMIT 100
