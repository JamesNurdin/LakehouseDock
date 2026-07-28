WITH joined AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_tax_percentage,
        st.s_tax_percentage AS store_tax_percentage,
        p.p_discount_active,
        ca.ca_zip,
        i.i_current_price,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        sr.sr_net_loss,
        cr.cr_return_amount
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store st
        ON st.s_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_site we
        ON we.web_open_date_sk = d.d_date_sk
    LEFT JOIN tpcds.promotion p
        ON p.p_start_date_sk = d.d_date_sk
    LEFT JOIN tpcds.item i
        ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN tpcds.customer c
        ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN tpcds.customer_address ca
        ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE d.d_year = 2001
      AND ca.ca_zip = '51387'
      AND i.i_current_price > 5.00
      AND cc.cc_tax_percentage > 5.00
)
SELECT
    d_year,
    d_month_seq,
    cc_tax_percentage,
    store_tax_percentage,
    p_discount_active,
    ca_zip,
    i_current_price,
    COUNT(*) AS transaction_cnt,
    SUM(ws_net_paid) AS total_net_paid,
    AVG(ws_ext_sales_price) AS avg_ext_sales_price,
    MIN(ws_sales_price) AS min_sales_price,
    MAX(ws_sales_price) AS max_sales_price,
    SUM(sr_net_loss) AS total_store_net_loss,
    SUM(cr_return_amount) AS total_catalog_return_amount
FROM joined
GROUP BY
    d_year,
    d_month_seq,
    cc_tax_percentage,
    store_tax_percentage,
    p_discount_active,
    ca_zip,
    i_current_price
HAVING SUM(ws_net_paid) > 50000
ORDER BY d_year, d_month_seq, total_net_paid DESC
