WITH base AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_category,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cr.cr_net_loss,
        ss.ss_ticket_number
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.catalog_sales cs
      ON cs.cs_item_sk = i.i_item_sk
     AND cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
    JOIN tpcds.catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    JOIN tpcds.reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'WA'
      AND i.i_class_id = 15
      AND d.d_year = 2001
      AND wp.wp_autogen_flag = 'N'
)
SELECT
    d_year,
    s_state,
    i_category,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cr_net_loss) AS total_catalog_return_loss,
    COUNT(DISTINCT ss_ticket_number) AS store_transactions,
    CASE WHEN SUM(ss_net_paid) > 0 THEN 'POS' ELSE 'NEG' END AS sales_sign
FROM base
GROUP BY d_year, s_state, i_category
ORDER BY total_store_sales DESC
LIMIT 100
