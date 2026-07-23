WITH aggregated AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        cc.cc_name AS call_center_name,
        cp.cp_department AS catalog_department,
        s.s_store_name AS store_name,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_ext_tax) AS total_sales_tax,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_quantity) AS total_cs_quantity,
        SUM(ws.ws_quantity) AS total_ws_quantity,
        SUM(sr.sr_return_quantity) AS total_sr_quantity,
        SUM(cr.cr_return_quantity) AS total_cr_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
        MAX(cs.cs_sold_date_sk) AS max_sold_date_sk
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
      AND s.s_state = 'TX'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_end_date <= DATE '2020-12-31'
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name,
        cc.cc_name,
        cp.cp_department,
        s.s_store_name
)
SELECT
    a.w_warehouse_id,
    a.w_warehouse_name,
    a.call_center_name,
    a.catalog_department,
    a.store_name,
    a.total_sales,
    a.total_sales_tax,
    a.total_return_amount,
    a.total_store_return_amount,
    a.total_web_sales,
    (a.total_cs_quantity + a.total_ws_quantity + a.total_sr_quantity + a.total_cr_quantity) AS total_quantity,
    a.avg_discount,
    a.order_count,
    a.min_sold_date_sk,
    a.max_sold_date_sk,
    ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated a
ORDER BY a.total_sales DESC
LIMIT 100
