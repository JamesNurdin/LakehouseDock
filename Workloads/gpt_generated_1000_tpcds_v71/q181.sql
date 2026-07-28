WITH sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_customer_sk,
        c.c_customer_id,
        i.i_item_id,
        st.s_store_name,
        p.p_promo_name,
        td.t_hour,
        td.t_sub_shift
    FROM store_sales ss
    JOIN time_dim td               ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
    JOIN store st                  ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
)
SELECT
    st.s_store_name,
    i.i_item_id,
    p.p_promo_name,
    COUNT(DISTINCT s.ss_ticket_number)                                 AS sales_txns,
    SUM(s.ss_quantity)                                                  AS qty_sold,
    SUM(s.ss_net_profit)                                                AS net_profit,
    COALESCE(SUM(sr.sr_return_quantity), 0)                            AS store_return_qty,
    COALESCE(SUM(cr.cr_return_quantity), 0)                            AS catalog_return_qty,
    COALESCE(SUM(wr.wr_return_quantity), 0)                            AS web_return_qty,
    COALESCE(SUM(sr.sr_net_loss), 0) + COALESCE(SUM(cr.cr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_loss
FROM sales s
JOIN store_returns sr           ON sr.sr_ticket_number = s.ss_ticket_number
JOIN time_dim td_ret            ON sr.sr_return_time_sk = td_ret.t_time_sk
JOIN reason r_sr                ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN catalog_returns cr   ON cr.cr_item_sk = s.ss_item_sk
                                 AND cr.cr_refunded_customer_sk = s.ss_customer_sk
LEFT JOIN reason r_cr          ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN web_returns wr       ON wr.wr_item_sk = s.ss_item_sk
LEFT JOIN time_dim td_web_ret   ON wr.wr_returned_time_sk = td_web_ret.t_time_sk
LEFT JOIN reason r_wr           ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN web_page wp           ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN customer c_wp         ON wp.wp_customer_sk = c_wp.c_customer_sk
LEFT JOIN store st               ON s.ss_store_sk = st.s_store_sk
LEFT JOIN item i                 ON s.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p            ON s.ss_promo_sk = p.p_promo_sk
GROUP BY
    st.s_store_name,
    i.i_item_id,
    p.p_promo_name
ORDER BY total_net_loss DESC
LIMIT 100
