WITH sales AS (
        SELECT
            cs.cs_sold_date_sk      AS sold_date_sk,
            cs.cs_sold_time_sk      AS sold_time_sk,
            cs.cs_call_center_sk    AS call_center_sk,
            cs.cs_catalog_page_sk   AS catalog_page_sk,
            cs.cs_warehouse_sk      AS warehouse_sk,
            cs.cs_bill_cdemo_sk     AS bill_cdemo_sk,
            cs.cs_order_number      AS order_number,
            cs.cs_ext_sales_price   AS sales_price,
            cs.cs_net_profit        AS net_profit
        FROM catalog_sales cs
    ),
    returns AS (
        SELECT
            cr.cr_returned_date_sk   AS returned_date_sk,
            cr.cr_returned_time_sk   AS returned_time_sk,
            cr.cr_call_center_sk     AS call_center_sk,
            cr.cr_catalog_page_sk    AS catalog_page_sk,
            cr.cr_warehouse_sk       AS warehouse_sk,
            cr.cr_refunded_cdemo_sk  AS refunded_cdemo_sk,
            cr.cr_order_number       AS order_number,
            cr.cr_return_amount      AS return_amount,
            cr.cr_fee                AS return_fee,
            cr.cr_reason_sk          AS reason_sk
        FROM catalog_returns cr
    ),
    store_ret AS (
        SELECT
            sr.sr_returned_date_sk AS returned_date_sk,
            sr.sr_return_time_sk   AS returned_time_sk,
            sr.sr_cdemo_sk         AS cdemo_sk,
            sr.sr_reason_sk        AS reason_sk,
            sr.sr_return_amt       AS return_amt,
            sr.sr_ticket_number    AS ticket_number
        FROM store_returns sr
    )
SELECT
    d_sold.d_year                               AS year,
    cc.cc_name                                  AS call_center_name,
    w.w_city                                    AS warehouse_city,
    SUM(s.sales_price)                          AS total_sales,
    SUM(r.return_amount)                        AS total_catalog_return,
    SUM(st.return_amt)                          AS total_store_return,
    COUNT(DISTINCT s.order_number)              AS distinct_orders,
    AVG(CASE WHEN r.return_fee > 0 THEN r.return_fee END) AS avg_catalog_return_fee,
    ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(s.sales_price) DESC) AS sales_rank
FROM sales s
LEFT JOIN returns r
    ON r.order_number = s.order_number
JOIN date_dim d_sold
    ON s.sold_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_ret
    ON r.returned_date_sk = d_ret.d_date_sk
LEFT JOIN time_dim t_sold
    ON s.sold_time_sk = t_sold.t_time_sk
LEFT JOIN time_dim t_ret
    ON r.returned_time_sk = t_ret.t_time_sk
JOIN call_center cc
    ON s.call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON s.catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON s.warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
    ON s.bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_ret st
    ON st.returned_date_sk = d_sold.d_date_sk
LEFT JOIN customer_demographics cd_store
    ON st.cdemo_sk = cd_store.cd_demo_sk
LEFT JOIN reason r_store
    ON st.reason_sk = r_store.r_reason_sk
WHERE d_sold.d_year = 2001
  AND w.w_state = 'CA'
  AND cd.cd_gender = 'M'
GROUP BY d_sold.d_year, cc.cc_name, w.w_city
ORDER BY total_sales DESC
