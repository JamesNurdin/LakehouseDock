WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        i.i_category,
        i.i_item_id,
        p.p_promo_name,
        p.p_discount_active,
        ca.ca_address_sk,
        cd.cd_demo_sk
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
)
SELECT
    d_sales.d_year AS year,
    i_sales.i_category AS category,
    cc.cc_name AS call_center_name,
    p_main.p_promo_name AS promotion_name,
    SUM(sb.ss_net_paid) AS total_sales_net_paid,
    SUM(sb.ss_quantity) AS total_units_sold,
    SUM(sb.ss_net_profit) AS total_sales_net_profit,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_return_loss,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_return_loss,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_return_loss,
    AVG(sb.ss_net_paid) AS avg_sales_net_paid,
    (SELECT AVG(inner_ss.ss_net_paid) FROM store_sales inner_ss) AS avg_overall_net_paid
FROM sales_base sb
JOIN date_dim d_sales
    ON sb.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i_sales
    ON sb.ss_item_sk = i_sales.i_item_sk
JOIN promotion p_main
    ON sb.ss_promo_sk = p_main.p_promo_sk
    AND p_main.p_item_sk = i_sales.i_item_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = sb.ss_item_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN reason r_catalog
    ON cr.cr_reason_sk = r_catalog.r_reason_sk
LEFT JOIN date_dim d_cr_date
    ON cr.cr_returned_date_sk = d_cr_date.d_date_sk
LEFT JOIN time_dim t_cr_time
    ON cr.cr_returned_time_sk = t_cr_time.t_time_sk
LEFT JOIN customer_demographics cd_cr_refunded
    ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
LEFT JOIN customer_address ca_cr_refunded
    ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
LEFT JOIN customer_demographics cd_cr_returning
    ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
LEFT JOIN customer_address ca_cr_returning
    ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
LEFT JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
LEFT JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
LEFT JOIN date_dim d_p_start
    ON p_main.p_start_date_sk = d_p_start.d_date_sk
LEFT JOIN date_dim d_p_end
    ON p_main.p_end_date_sk = d_p_end.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = sb.ss_ticket_number
    AND sr.sr_item_sk = sb.ss_item_sk
LEFT JOIN date_dim d_sr_return
    ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
LEFT JOIN time_dim t_sr_return
    ON sr.sr_return_time_sk = t_sr_return.t_time_sk
LEFT JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
LEFT JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = sb.ss_item_sk
LEFT JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
LEFT JOIN time_dim t_wr_return
    ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
LEFT JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
LEFT JOIN customer_demographics cd_wr_refund
    ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
LEFT JOIN customer_address ca_wr_refund
    ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
LEFT JOIN customer_demographics cd_wr_returning
    ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
LEFT JOIN customer_address ca_wr_returning
    ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
WHERE p_main.p_promo_name IN (
    SELECT DISTINCT p2.p_promo_name
    FROM promotion p2
    WHERE p2.p_discount_active = 'Y'
)
GROUP BY
    d_sales.d_year,
    i_sales.i_category,
    cc.cc_name,
    p_main.p_promo_name
ORDER BY
    d_sales.d_year DESC,
    total_store_return_loss DESC
LIMIT 100
