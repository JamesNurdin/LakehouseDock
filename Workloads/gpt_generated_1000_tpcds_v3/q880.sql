SELECT
    cc.cc_name AS call_center_name,
    d_sale.d_year AS sales_year,
    cp.cp_department AS catalog_department,
    r.r_reason_desc AS store_return_reason,
    ws.web_name AS web_site_name,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(inv1.inv_quantity_on_hand) AS total_inventory_on_hand
FROM store_sales ss
JOIN date_dim d_sale
    ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN customer_demographics cd_cust
    ON ss.ss_cdemo_sk = cd_cust.cd_demo_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN inventory inv1
    ON inv1.inv_date_sk = d_sale.d_date_sk
JOIN warehouse w
    ON inv1.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_sale.d_date_sk
   AND cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sale.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sale.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = ss.ss_item_sk
      AND wr2.wr_returned_date_sk = d_sale.d_date_sk
)
GROUP BY
    cc.cc_name,
    d_sale.d_year,
    cp.cp_department,
    r.r_reason_desc,
    ws.web_name
ORDER BY total_store_sales DESC
LIMIT 100
