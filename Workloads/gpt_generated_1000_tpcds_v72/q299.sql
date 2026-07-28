WITH joined AS (
    SELECT
        d.d_date,
        s.s_store_id,
        s.s_store_name,
        i.i_item_id,
        i.i_product_name,
        c.c_customer_id,
        ss.ss_net_paid,
        cr.cr_order_number,
        r.r_reason_desc,
        wr.wr_net_loss,
        cc.cc_company_name,
        sm.sm_type,
        p.p_promo_name,
        ca.ca_state
    FROM store_sales ss
    JOIN date_dim d                     ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t                     ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i                         ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c                     ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca           ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s                        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p                    ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv                  ON i.i_item_sk = inv.inv_item_sk
                                         AND d.d_date_sk = inv.inv_date_sk
    JOIN catalog_returns cr            ON cr.cr_returned_date_sk = d.d_date_sk
                                         AND cr.cr_returned_time_sk = t.t_time_sk
                                         AND cr.cr_item_sk = i.i_item_sk
                                         AND cr.cr_refunded_customer_sk = c.c_customer_sk
                                         AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
                                         AND cr.cr_refunded_addr_sk = ca.ca_address_sk
                                         AND cr.cr_returning_customer_sk = c.c_customer_sk
                                         AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
                                         AND cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN call_center cc                ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp                ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r                      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr               ON wr.wr_returned_date_sk = d.d_date_sk
                                         AND wr.wr_returned_time_sk = t.t_time_sk
                                         AND wr.wr_item_sk = i.i_item_sk
                                         AND wr.wr_refunded_customer_sk = c.c_customer_sk
                                         AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
                                         AND wr.wr_refunded_addr_sk = ca.ca_address_sk
                                         AND wr.wr_returning_customer_sk = c.c_customer_sk
                                         AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
                                         AND wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN web_page wp                   ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2000
      AND i.i_formulation LIKE '%steel%'
      AND s.s_state = 'CA'
      AND cc.cc_company_name = 'CompanyA'
      AND r.r_reason_desc = 'Damaged'
      AND wr.wr_net_loss > 0
)
SELECT
    d_date,
    s_store_id,
    s_store_name,
    i_item_id,
    i_product_name,
    c_customer_id,
    SUM(ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT cr_order_number) AS distinct_return_orders,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM joined
GROUP BY
    d_date,
    s_store_id,
    s_store_name,
    i_item_id,
    i_product_name,
    c_customer_id
ORDER BY total_net_paid DESC, sales_rank
LIMIT 100
