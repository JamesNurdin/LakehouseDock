WITH store_ret_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_addr_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        SUM(sr.sr_return_amt)      AS total_return_amt,
        SUM(sr.sr_net_loss)        AS total_net_loss,
        COUNT(*)                    AS cnt_returns
    FROM store_returns sr
    GROUP BY
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_addr_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk
)
SELECT
    s.s_store_name,
    sm.sm_type                          AS ship_mode_type,
    d_sold.d_quarter_name,
    d_sold.d_year,
    r.r_reason_desc,
    cd.cd_gender,
    hd.hd_buy_potential,
    SUM(sr_agg.total_return_amt)       AS total_store_return_amount,
    SUM(wr.wr_return_amt)              AS total_web_return_amount,
    SUM(ws.ws_net_profit)               AS total_web_sales_profit,
    SUM(ws.ws_ext_sales_price)          AS total_web_sales_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    COUNT(DISTINCT sr_agg.sr_store_sk)  AS distinct_store_returns
FROM store_ret_agg sr_agg
INNER JOIN store s               ON sr_agg.sr_store_sk      = s.s_store_sk
INNER JOIN reason r              ON sr_agg.sr_reason_sk     = r.r_reason_sk
INNER JOIN date_dim d_return     ON sr_agg.sr_returned_date_sk = d_return.d_date_sk
INNER JOIN time_dim t_return     ON sr_agg.sr_return_time_sk   = t_return.t_time_sk
INNER JOIN customer c            ON sr_agg.sr_customer_sk   = c.c_customer_sk
INNER JOIN customer_address ca   ON sr_agg.sr_addr_sk       = ca.ca_address_sk
INNER JOIN customer_demographics cd ON sr_agg.sr_cdemo_sk   = cd.cd_demo_sk
INNER JOIN household_demographics hd ON sr_agg.sr_hdemo_sk   = hd.hd_demo_sk
INNER JOIN inventory i           ON d_return.d_date_sk      = i.inv_date_sk
-- Web sales side
INNER JOIN web_sales ws          ON ws.ws_bill_customer_sk = c.c_customer_sk
INNER JOIN date_dim d_sold       ON ws.ws_sold_date_sk      = d_sold.d_date_sk
INNER JOIN date_dim d_ship       ON ws.ws_ship_date_sk      = d_ship.d_date_sk
INNER JOIN time_dim t_sold       ON ws.ws_sold_time_sk      = t_sold.t_time_sk
INNER JOIN ship_mode sm          ON ws.ws_ship_mode_sk      = sm.sm_ship_mode_sk
-- Web returns side
INNER JOIN web_returns wr       ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk      = ws.ws_item_sk
INNER JOIN reason r_wr          ON wr.wr_reason_sk = r_wr.r_reason_sk
INNER JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
INNER JOIN time_dim t_wr_return ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
INNER JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
INNER JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
INNER JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
INNER JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
GROUP BY
    s.s_store_name,
    sm.sm_type,
    d_sold.d_quarter_name,
    d_sold.d_year,
    r.r_reason_desc,
    cd.cd_gender,
    hd.hd_buy_potential
ORDER BY total_store_return_amount DESC
LIMIT 100
