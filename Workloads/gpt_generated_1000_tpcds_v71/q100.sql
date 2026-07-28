WITH joined_data AS (
   SELECT
       d.d_year AS d_year,
       d.d_date AS d_date,
       c.c_customer_sk AS c_customer_sk,
       c.c_customer_id AS c_customer_id,
       c.c_first_name AS c_first_name,
       c.c_last_name AS c_last_name,
       i.i_item_sk AS i_item_sk,
       i.i_category AS i_category,
       cs.cs_net_paid_inc_ship AS cs_net_paid_inc_ship,
       cs.cs_coupon_amt AS cs_coupon_amt,
       sr.sr_ticket_number AS sr_ticket_number,
       p.p_promo_id AS p_promo_id,
       w.w_state AS w_state
   FROM store_returns sr
   JOIN date_dim d
     ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i
     ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c
     ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   JOIN catalog_sales cs
     ON cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_item_sk = i.i_item_sk
    AND cs.cs_bill_customer_sk = c.c_customer_sk
    AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_returned_date_sk = d.d_date_sk
   JOIN inventory inv
     ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
   JOIN web_page wp
     ON wp.wp_customer_sk = c.c_customer_sk
    AND wp.wp_creation_date_sk = d.d_date_sk
   JOIN web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
    AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wr.wr_returned_date_sk = d.d_date_sk
   JOIN web_site ws
     ON ws.web_open_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Men'
     AND w.w_state = 'CA'
     AND cs.cs_net_paid_inc_ship > 1000.00
     AND p.p_discount_active = 'Y'
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year,
    SUM(cs_net_paid_inc_ship) AS total_sales,
    COUNT(DISTINCT sr_ticket_number) AS distinct_return_tickets,
    COUNT(DISTINCT p_promo_id) AS distinct_promos,
    RANK() OVER (PARTITION BY c_customer_id ORDER BY SUM(cs_net_paid_inc_ship) DESC) AS sales_rank
FROM joined_data
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year
ORDER BY total_sales DESC
LIMIT 100
