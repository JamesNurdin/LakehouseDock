WITH promo_lateral AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid AS total_sales,
        cs.cs_quantity,
        cc.cc_state,
        i.i_category,
        i.i_wholesale_cost,
        i.i_formulation,
        i.i_rec_start_date,
        cc.cc_rec_start_date,
        w.w_state,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        r_cr.r_reason_desc,
        sr.sr_net_loss,
        wr.wr_net_loss,
        promo.p_discount_active,
        wp_l.wp_type
    FROM catalog_sales cs
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    -- LATERAL join to get the most expensive promotion for the item
    CROSS JOIN LATERAL (
        SELECT p.p_discount_active, p.p_promo_id
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
        ORDER BY p.p_cost DESC
        LIMIT 1
    ) promo
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c_bill.c_customer_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c_bill.c_customer_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    -- LATERAL join to fetch a matching web page for the return
    CROSS JOIN LATERAL (
        SELECT wp.wp_type, wp.wp_url
        FROM web_page wp
        WHERE wp.wp_web_page_sk = wr.wr_web_page_sk
          AND wp.wp_customer_sk = c_bill.c_customer_sk
        LIMIT 1
    ) wp_l
    WHERE cc.cc_state = 'CA'
      AND i.i_wholesale_cost > 5.00
      AND i.i_formulation LIKE '%seashell%'
      AND w.w_state = 'TX'
      AND promo.p_discount_active = 'Y'
      AND cs.cs_quantity >= 5
      AND i.i_rec_start_date >= DATE '2001-01-01'
      AND cc.cc_rec_start_date >= DATE '2005-01-01'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = i.i_item_sk
            AND sr2.sr_customer_sk = c_bill.c_customer_sk
            AND sr2.sr_net_loss > 0
      )
)
SELECT
    i_category,
    cc_state,
    r_reason_desc,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(total_sales) AS total_sales,
    SUM(sr_net_loss) AS total_store_returns_loss,
    SUM(wr_net_loss) AS total_web_returns_loss,
    CASE WHEN SUM(total_sales) > (SUM(sr_net_loss) + SUM(wr_net_loss))
         THEN 'Profit' ELSE 'Loss' END AS profit_status
FROM promo_lateral
GROUP BY ROLLUP (i_category, cc_state, r_reason_desc)
ORDER BY i_category, cc_state, r_reason_desc
LIMIT 100
