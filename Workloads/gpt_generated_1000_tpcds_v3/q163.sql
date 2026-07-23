WITH dim_item AS (
    SELECT
        i_item_sk,
        i_category,
        i_brand,
        i_units,
        i_container,
        i_rec_start_date
    FROM item
    WHERE i_units = 'Box'
      AND i_category = 'Sports'
      AND i_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    dim_item.i_category,
    dim_item.i_brand,
    store.s_state,
    reason.r_reason_desc,
    SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
    SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns,
    COUNT(DISTINCT customer.c_customer_sk) AS distinct_customers,
    AVG(COALESCE(cs.cs_ext_discount_amt, 0)) AS avg_catalog_discount,
    MIN(COALESCE(ss.ss_quantity, 0)) AS min_store_quantity,
    MAX(COALESCE(ws.ws_quantity, 0)) AS max_web_quantity
FROM dim_item
JOIN catalog_sales cs
    ON cs.cs_item_sk = dim_item.i_item_sk
JOIN store_sales ss
    ON ss.ss_item_sk = dim_item.i_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = dim_item.i_item_sk
JOIN customer
    ON customer.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = customer.c_current_cdemo_sk
JOIN store
    ON store.s_store_sk = ss.ss_store_sk
JOIN store_returns sr
    ON sr.sr_item_sk = dim_item.i_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason
    ON reason.r_reason_sk = sr.sr_reason_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = dim_item.i_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN call_center cc
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN inventory inv
    ON inv.inv_item_sk = dim_item.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
WHERE
    w.w_state = 'CA'
    AND reason.r_reason_desc = 'Package was damaged'
    AND dim_item.i_rec_start_date >= DATE '2001-01-01'
GROUP BY
    dim_item.i_category,
    dim_item.i_brand,
    store.s_state,
    reason.r_reason_desc
ORDER BY total_catalog_sales DESC
LIMIT 100
