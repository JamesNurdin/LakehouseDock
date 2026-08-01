WITH base_sales AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM tpcds.store_sales ss
)
SELECT
    d_sold.d_year,
    s.s_store_name,
    i.i_product_name,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    ca.ca_city,
    cc.cc_name,
    cp.cp_catalog_number,
    w.w_warehouse_name,
    wr.wr_return_amt,
    total_by_item.item_sales_total,
    cust_sales.sales_cnt,
    CASE t.metric_idx
        WHEN 1 THEN 'quantity'
        WHEN 2 THEN 'net_profit'
        ELSE 'unknown'
    END AS metric_type,
    t.metric_val
FROM base_sales ss
JOIN tpcds.date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN tpcds.catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_date_sk = d_sold.d_date_sk
JOIN tpcds.item i_cr
    ON cr.cr_item_sk = i_cr.i_item_sk
JOIN tpcds.date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
JOIN tpcds.warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
JOIN tpcds.web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
   AND wp.wp_customer_sk = c.c_customer_sk
JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
   AND wr.wr_item_sk = i.i_item_sk
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.item i_wr
    ON wr.wr_item_sk = i_wr.i_item_sk
JOIN tpcds.date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN LATERAL (
    SELECT SUM(ss2.ss_ext_sales_price) AS item_sales_total
    FROM tpcds.store_sales ss2
    WHERE ss2.ss_item_sk = i.i_item_sk
      AND ss2.ss_sold_date_sk = d_sold.d_date_sk
) total_by_item ON TRUE
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS sales_cnt
    FROM tpcds.store_sales ss3
    WHERE ss3.ss_customer_sk = c.c_customer_sk
      AND ss3.ss_sold_date_sk = d_sold.d_date_sk
) cust_sales ON TRUE
LEFT JOIN LATERAL (
    SELECT ARRAY[CAST(ss.ss_quantity AS DOUBLE), CAST(ss.ss_net_profit AS DOUBLE)] AS metric_arr
) metrics ON TRUE
CROSS JOIN UNNEST(metrics.metric_arr) WITH ORDINALITY AS t(metric_val, metric_idx)
WHERE d_sold.d_year = 2001
  AND s.s_state = 'CA'
  AND i.i_category = 'Books'
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_sales ss4
        WHERE ss4.ss_store_sk = s.s_store_sk
          AND ss4.ss_sold_date_sk = d_sold.d_date_sk
          AND ss4.ss_quantity > 5
    )
GROUP BY
    d_sold.d_year,
    s.s_store_name,
    i.i_product_name,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    ca.ca_city,
    cc.cc_name,
    cp.cp_catalog_number,
    w.w_warehouse_name,
    wr.wr_return_amt,
    total_by_item.item_sales_total,
    cust_sales.sales_cnt,
    t.metric_idx,
    t.metric_val
ORDER BY total_by_item.item_sales_total DESC
LIMIT 100
