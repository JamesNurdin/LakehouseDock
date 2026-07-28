WITH joined_data AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_item_id,
        i.i_current_price,
        cr.cr_return_amount,
        cr.cr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'large_return' ELSE 'regular_return' END AS return_type,
        w.w_warehouse_sq_ft,
        p.p_discount_active,
        r.r_reason_desc,
        cc.cc_name,
        cp.cp_type,
        ws.web_name
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN promotion p
      ON p.p_item_sk = i.i_item_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    /* Additional dimension joins to satisfy the requirement of using every selected table */
    JOIN customer c_ref
      ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_address ca_ref
      ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN household_demographics hd_ref
      ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer c_ret
      ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_address ca_ret
      ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN household_demographics hd_ret
      ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer c_wr_refunded
      ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    JOIN customer_address ca_wr_refunded
      ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    JOIN household_demographics hd_wr_refunded
      ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    JOIN customer c_wr_returning
      ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
    JOIN customer_address ca_wr_returning
      ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    JOIN household_demographics hd_wr_returning
      ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_current_price > 20
      AND w.w_warehouse_sq_ft > 500000
)
SELECT
    d_year,
    i_category,
    COUNT(*) AS return_records,
    SUM(cr_return_amount + wr_return_amt) AS total_return_amount,
    AVG(cr_net_loss + wr_net_loss) AS avg_net_loss,
    SUM(CASE WHEN return_type = 'large_return' THEN 1 ELSE 0 END) AS large_return_cnt
FROM joined_data
GROUP BY d_year, i_category
HAVING AVG(cr_net_loss + wr_net_loss) > 0
ORDER BY total_return_amount DESC
LIMIT 100
