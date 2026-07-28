/* goal: Analyze yearly sales performance by category and gender, comparing store, catalog, and web channels while filtering for high‑risk red‑item customers in California during 2001, and include the maximum current price for the same item color as a scalar subquery. */
WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_color,
        cd.cd_gender,
        cd.cd_credit_rating,
        cc.cc_state,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price AS store_ext_sales,
        cs.cs_order_number,
        cs.cs_ext_sales_price AS catalog_ext_sales,
        ws.ws_order_number AS web_order_number,
        ws.ws_ext_sales_price AS web_ext_sales,
        ws.ws_sales_price,
        cr.cr_return_amount
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_sales cs        
         ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc          
         ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp         
         ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr      
         ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN web_sales ws            
         ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp             
         ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite           
         ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'red'
      AND cd.cd_credit_rating = 'High Risk'
      AND cc.cc_state = 'CA'
      AND ws.ws_sales_price > 100.00
)
SELECT
    b.d_year,
    b.i_category,
    b.cd_gender,
    COUNT(DISTINCT b.ss_ticket_number)               AS store_sales_cnt,
    SUM(b.store_ext_sales)                            AS store_sales_amt,
    COUNT(DISTINCT b.cs_order_number)                AS catalog_sales_cnt,
    SUM(b.catalog_ext_sales)                         AS catalog_sales_amt,
    COUNT(DISTINCT b.web_order_number)               AS web_sales_cnt,
    SUM(b.web_ext_sales)                             AS web_sales_amt,
    SUM(b.cr_return_amount)                         AS total_return_amt,
    (
        SELECT MAX(i2.i_current_price)
        FROM item i2
        WHERE i2.i_color = b.i_color
    )                                                AS max_price_same_color
FROM base b
GROUP BY
    b.d_year,
    b.i_category,
    b.cd_gender,
    b.i_color,
    b.cc_state
ORDER BY store_sales_amt DESC
LIMIT 100
