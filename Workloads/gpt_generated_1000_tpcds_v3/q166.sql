WITH ws_customer_agg AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_ws_net_paid,
        SUM(ws_net_profit) AS total_ws_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    d_sales.d_quarter_seq,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(ws_agg.total_ws_net_paid) AS total_net_paid,
    SUM(ws_agg.total_ws_net_profit) AS total_net_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    CASE WHEN SUM(ws_agg.total_ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_indicator,
    (SELECT AVG(ws_net_paid) FROM web_sales) AS avg_net_paid_all
FROM ws_customer_agg ws_agg
JOIN customer c
    ON c.c_customer_sk = ws_agg.customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca_curr
    ON c.c_current_addr_sk = ca_curr.ca_address_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_sales
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp_sales
    ON ws.ws_web_page_sk = wp_sales.wp_web_page_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN date_dim d_sr_return
    ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
JOIN customer_address ca_sr_addr
    ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN web_page wp_return
    ON wr.wr_web_page_sk = wp_return.wp_web_page_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE d_sales.d_year = 2002
GROUP BY
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    d_sales.d_quarter_seq
ORDER BY total_net_profit DESC
LIMIT 100
