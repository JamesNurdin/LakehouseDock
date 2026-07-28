WITH base_join AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid AS catalog_net_paid,
        cs.cs_ext_discount_amt AS catalog_discount,
        cr.cr_net_loss AS catalog_return_loss,
        cr.cr_refunded_cash AS catalog_refunded_cash,
        t.t_hour,
        t.t_shift,
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        p.p_promo_sk,
        p.p_discount_active,
        p.p_cost AS promo_cost,
        ss.ss_ticket_number,
        ss.ss_net_paid AS store_net_paid,
        ss.ss_ext_discount_amt AS store_discount,
        sr.sr_net_loss AS store_return_loss,
        s.s_store_sk,
        s.s_state,
        ws.ws_order_number,
        ws.ws_net_paid AS web_net_paid,
        ws.ws_ext_discount_amt AS web_discount,
        wr.wr_net_loss AS web_return_loss,
        wp.wp_web_page_sk,
        wsite.web_site_sk,
        wsite.web_gmt_offset,
        wsite.web_rec_end_date
    FROM catalog_sales cs
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_item_sk = cs.cs_item_sk
     AND cr.cr_order_number = cs.cs_order_number
     AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN store_sales ss
      ON ss.ss_sold_time_sk = t.t_time_sk
     AND ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_return_time_sk = t.t_time_sk
     AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws
      ON ws.ws_sold_time_sk = t.t_time_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
     AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE t.t_hour = 14
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND wsite.web_gmt_offset = -5.00
      AND wsite.web_rec_end_date = DATE '2000-08-15'
),
scalar_totals AS (
    SELECT (SELECT COUNT(DISTINCT c2.c_customer_sk) FROM customer c2) AS total_customers
)
SELECT
    bj.t_hour,
    bj.t_shift,
    bj.s_state,
    bj.web_gmt_offset,
    COUNT(DISTINCT bj.c_customer_sk) AS distinct_customers,
    SUM(bj.catalog_net_paid) AS sum_catalog_net_paid,
    SUM(bj.store_net_paid) AS sum_store_net_paid,
    SUM(bj.web_net_paid) AS sum_web_net_paid,
    SUM(bj.catalog_return_loss) AS sum_catalog_return_loss,
    SUM(bj.store_return_loss) AS sum_store_return_loss,
    SUM(bj.web_return_loss) AS sum_web_return_loss,
    AVG(bj.promo_cost) AS avg_promo_cost,
    st.total_customers,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_order_number = bj.cs_order_number
              AND cr2.cr_refunded_cash > 100
        ) THEN 'HIGH_REFUND'
        ELSE 'NORMAL_REFUND'
    END AS refund_category
FROM base_join bj
CROSS JOIN scalar_totals st
GROUP BY bj.t_hour, bj.t_shift, bj.s_state, bj.web_gmt_offset, st.total_customers, bj.cs_order_number
ORDER BY sum_catalog_net_paid DESC
LIMIT 100
