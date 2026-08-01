WITH base AS (
    SELECT
        cr.cr_return_amount,
        cs.cs_net_paid,
        sr.sr_return_amt,
        ws.ws_net_paid,
        c.c_customer_id,
        i.i_category,
        d.d_year,
        r.r_reason_desc
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN tpcds.date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
      ON cr.cr_item_sk = i.i_item_sk
     AND cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_returned_date_sk = d.d_date_sk
     AND sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND c.c_email_address LIKE '%@example.com'
)
SELECT
    i_category,
    d_year,
    r_reason_desc,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cs_net_paid) AS total_sales_net,
    SUM(sr_return_amt) AS total_store_return,
    SUM(ws_net_paid) AS total_web_sales,
    COUNT(DISTINCT c_customer_id) AS distinct_customers
FROM base
GROUP BY i_category, d_year, r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
