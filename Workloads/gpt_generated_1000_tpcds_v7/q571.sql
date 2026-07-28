WITH all_data AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_net_paid,
       cs.cs_order_number,
       cs.cs_quantity,
       cs.cs_ext_sales_price,
       cs.cs_ext_discount_amt,
       cs.cs_ext_tax,
       cs.cs_ext_ship_cost,
       cs.cs_net_paid_inc_tax,
       cs.cs_net_paid_inc_ship,
       cs.cs_net_paid_inc_ship_tax,
       cs.cs_net_profit,
       cc.cc_call_center_id,
       cp.cp_catalog_page_id,
       cp.cp_end_date_sk,
       p.p_promo_id,
       p.p_cost,
       i.i_item_id,
       i.i_brand,
       i.i_category,
       w.w_warehouse_id,
       sm.sm_ship_mode_id,
       sm.sm_type,
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       c.c_birth_year,
       ca.ca_city,
       sr.sr_ticket_number,
       s.s_store_id,
       s.s_state,
       r.r_reason_desc,
       cr.cr_return_quantity,
       ws.ws_net_paid AS ws_net_paid,
       wp.wp_url,
       we.web_city,
       we.web_suite_number
   FROM tpcds.catalog_sales cs
   JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
                                AND sr.sr_customer_sk = c.c_customer_sk
                                AND sr.sr_addr_sk = ca.ca_address_sk
   JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
   JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_refunded_customer_sk = c.c_customer_sk
                                 AND cr.cr_refunded_addr_sk = ca.ca_address_sk
                                 AND cr.cr_order_number = cs.cs_order_number
   JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
                           AND ws.ws_bill_customer_sk = c.c_customer_sk
                           AND ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
   WHERE c.c_birth_year BETWEEN 1930 AND 1950
     AND we.web_city = 'Chicago'
     AND cp.cp_end_date_sk > 2450900
     AND i.i_brand = 'BrandX'
     AND sm.sm_type = 'AIR'
     AND cs.cs_sold_date_sk BETWEEN 2451000 AND 2452000
     AND EXISTS (
         SELECT 1 FROM tpcds.store_returns sr2
         WHERE sr2.sr_store_sk = s.s_store_sk
           AND sr2.sr_return_quantity > 5
     )
)
SELECT
    customer_id,
    first_name,
    last_name,
    birth_year,
    total_catalog_sales,
    total_web_sales,
    total_sales,
    avg_promo_cost,
    CASE WHEN total_sales > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS spender_category,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        c_id AS customer_id,
        f_name AS first_name,
        l_name AS last_name,
        b_year AS birth_year,
        SUM(cs_net) AS total_catalog_sales,
        SUM(ws_net) AS total_web_sales,
        SUM(cs_net) + SUM(ws_net) AS total_sales,
        AVG(promo_cost) AS avg_promo_cost
    FROM (
        SELECT
            c_customer_id AS c_id,
            c_first_name AS f_name,
            c_last_name AS l_name,
            c_birth_year AS b_year,
            cs_net_paid AS cs_net,
            ws_net_paid AS ws_net,
            p_cost AS promo_cost
        FROM all_data
    ) sub
    GROUP BY c_id, f_name, l_name, b_year
) final
ORDER BY sales_rank
LIMIT 20
