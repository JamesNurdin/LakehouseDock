WITH sales_agg AS (
    SELECT
        cc.cc_city AS city,
        i.i_category AS category,
        r.r_reason_desc AS return_reason,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(wr.wr_return_amt) AS total_web_returns
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN customer c_refund
        ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
    LEFT JOIN customer_address ca_refund
        ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_city = 'Georgetown'
      AND i.i_current_price BETWEEN 50 AND 200
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY cc.cc_city, i.i_category, r.r_reason_desc
    HAVING SUM(cs.cs_net_paid_inc_ship) > 10000
)
SELECT
    city,
    category,
    return_reason,
    total_sales,
    orders_cnt,
    avg_discount,
    total_catalog_returns,
    total_store_returns,
    total_web_returns
FROM sales_agg
WHERE total_sales > (
    SELECT AVG(total_sales) FROM sales_agg
)
ORDER BY total_sales DESC
LIMIT 100
