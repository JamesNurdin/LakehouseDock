WITH ss AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_ext_tax,
        ss.ss_net_profit
    FROM store_sales ss
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    cc.cc_name,
    w.w_city,
    wsit.web_name,
    wp.wp_type,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ss.ss_quantity) AS total_store_quantity,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(ws.ws_quantity) AS total_web_quantity,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    MIN(ss.ss_net_profit) AS min_store_net_profit,
    MAX(ss.ss_net_profit) AS max_store_net_profit
FROM ss
INNER JOIN store_returns sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
INNER JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
INNER JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
INNER JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
INNER JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
INNER JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sold.d_date_sk
INNER JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
INNER JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
INNER JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
INNER JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
INNER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE w.w_zip = '36098'
  AND wp.wp_autogen_flag = 'N'
  AND wsit.web_country = 'United States'
  AND cc.cc_state = 'CA'
GROUP BY
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    cc.cc_name,
    w.w_city,
    wsit.web_name,
    wp.wp_type
ORDER BY total_store_sales DESC
LIMIT 100
