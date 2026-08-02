WITH catalog_keys AS (
    SELECT cs_order_number AS order_number
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
        SELECT d_date_sk FROM tpcds.date_dim d WHERE d.d_year = 2001
    )
),
store_keys AS (
    SELECT ss_ticket_number AS order_number
    FROM tpcds.store_sales ss
    WHERE ss.ss_sold_date_sk IN (
        SELECT d_date_sk FROM tpcds.date_dim d WHERE d.d_year = 2001
    )
)
SELECT
    d_cs.d_year,
    i.i_brand,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(cs.cs_net_paid_inc_ship) AS catalog_net_sales,
    SUM(ss.ss_net_paid) AS store_net_sales,
    SUM(sr.sr_net_loss) AS store_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    (SUM(cs.cs_net_paid_inc_ship) - SUM(ss.ss_net_paid)) AS sales_gap,
    AVG(cs.cs_quantity) AS avg_quantity
FROM tpcds.catalog_sales cs
JOIN tpcds.date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN tpcds.time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
    AND ss.ss_ticket_number = cs.cs_order_number
JOIN tpcds.date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN tpcds.time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = i.i_item_sk
JOIN tpcds.date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN tpcds.time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
JOIN tpcds.web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wr.wr_item_sk = i.i_item_sk
JOIN tpcds.date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN tpcds.time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
WHERE d_cs.d_year = 2001
  AND i.i_brand_id = 21
  AND cd.cd_purchase_estimate >= 3000
  AND s.s_state = 'CA'
  AND r.r_reason_desc = 'Damaged'
  AND cs.cs_quantity > (SELECT AVG(cs2.cs_quantity) FROM tpcds.catalog_sales cs2)
  AND cs.cs_order_number IN (
        SELECT order_number FROM catalog_keys
        EXCEPT
        SELECT order_number FROM store_keys
    )
  AND EXISTS (
        SELECT 1 FROM tpcds.store_returns sr2
        WHERE sr2.sr_ticket_number = cs.cs_order_number
          AND sr2.sr_return_quantity > 0
    )
GROUP BY d_cs.d_year, i.i_brand, s.s_state
ORDER BY sales_gap DESC
LIMIT 100
