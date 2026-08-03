WITH base_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_sales_price,
        d.d_year,
        i.i_category,
        cc.cc_name,
        cc.cc_state,
        wp.wp_type,
        wp.wp_autogen_flag
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
      ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND wp.wp_autogen_flag = 'Y'
      AND cc.cc_state = 'CA'
)
SELECT
    d_year,
    i_category,
    cc_name,
    wp_type,
    r.r_reason_desc,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    AVG(ws_sales_price) AS avg_sales_price,
    MAX(wr.wr_return_amt) AS max_return_amt
FROM base_sales
JOIN web_returns wr
  ON base_sales.ws_order_number = wr.wr_order_number
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
GROUP BY
    d_year,
    i_category,
    cc_name,
    wp_type,
    r.r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
