WITH joined_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_reason_sk,
        r_cr.r_reason_desc AS cr_reason_desc,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_coupon_amt,
        d_cr.d_year,
        d_cr.d_month_seq,
        c_refunded.c_customer_id AS refunded_customer_id,
        c_returning.c_customer_id AS returning_customer_id,
        cd_refunded.cd_gender AS refunded_gender,
        ca_refunded.ca_state AS refunded_state,
        sr.sr_return_amt AS store_return_amount,
        sr.sr_reason_sk AS store_reason_sk,
        r_sr.r_reason_desc AS store_reason_desc,
        d_sr.d_year AS store_return_year,
        ws.ws_net_paid,
        ws.ws_sales_price,
        ws.ws_coupon_amt,
        wp.wp_url,
        ws_site.web_name,
        ws_site.web_manager,
        wr.wr_return_amt AS web_return_amount,
        reason_wr.r_reason_desc AS web_return_reason_desc,
        d_wr.d_year AS web_return_year,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c_returning.c_customer_sk
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c_refunded.c_customer_sk
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN reason reason_wr
        ON wr.wr_reason_sk = reason_wr.r_reason_sk
    WHERE d_cr.d_year = 2000
      AND ws_site.web_manager = 'Adam Stonge'
      AND ws.ws_coupon_amt > 1000
      AND ca_refunded.ca_state = 'CA'
      AND r_cr.r_reason_desc LIKE '%Customer%'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_customer_sk = c_returning.c_customer_sk
            AND sr2.sr_returned_date_sk = d_cr.d_date_sk
      )
)
SELECT
    jd.d_year,
    jd.web_manager,
    COUNT(DISTINCT jd.returning_customer_id) AS returning_customers,
    SUM(jd.cr_return_amount) AS total_return_amount,
    AVG(jd.cs_net_profit) AS avg_net_profit,
    SUM(jd.ws_coupon_amt) AS total_coupon_amount,
    COUNT(*) FILTER (WHERE jd.store_reason_desc = 'Customer Not Satisfied') AS store_returns_customer_not_satisfied,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = (SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2000)
    ) AS avg_ws_net_paid_2000
FROM joined_data jd
GROUP BY jd.d_year, jd.web_manager
HAVING SUM(jd.cr_return_amount) > 10000
ORDER BY total_return_amount DESC
LIMIT 100
