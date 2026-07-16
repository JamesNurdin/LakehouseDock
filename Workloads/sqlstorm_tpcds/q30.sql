WITH sales_base AS (
 SELECT cs.cs_sold_date_sk AS date_sk,
        cs.cs_order_number AS order_number,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel
 FROM catalog_sales cs
 UNION ALL
 SELECT ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        NULL,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        'store'
 FROM store_sales ss
 UNION ALL
 SELECT ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        NULL,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        'web'
 FROM web_sales ws
),
returns_base AS (
 SELECT cr.cr_order_number AS order_number,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel
 FROM catalog_returns cr
 UNION ALL
 SELECT sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_net_loss,
        'store'
 FROM store_returns sr
 UNION ALL
 SELECT wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss,
        'web'
 FROM web_returns wr
),
sales_with_returns AS (
 SELECT s.date_sk,
        s.order_number,
        s.item_sk,
        s.customer_sk,
        s.call_center_sk,
        s.quantity,
        s.net_paid,
        s.net_profit,
        s.channel,
        COALESCE(r.return_amount, 0) AS return_amount,
        COALESCE(r.net_loss, 0) AS net_loss,
        s.net_paid - COALESCE(r.return_amount, 0) AS net_paid_adj,
        s.net_profit - COALESCE(r.net_loss, 0) AS net_profit_adj
 FROM sales_base s
 LEFT JOIN returns_base r
   ON s.order_number = r.order_number AND s.channel = r.channel
),
enriched_sales AS (
 SELECT swr.*,
        d.d_year,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_preferred_cust_flag,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        ca.ca_city,
        ca.ca_state,
        cc.cc_name AS call_center_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE WHEN swr.net_profit_adj > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign
 FROM sales_with_returns swr
 LEFT JOIN date_dim d ON swr.date_sk = d.d_date_sk
 LEFT JOIN customer c ON swr.customer_sk = c.c_customer_sk
 LEFT JOIN item i ON swr.item_sk = i.i_item_sk
 LEFT JOIN call_center cc ON swr.call_center_sk = cc.cc_call_center_sk
 LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ranked_customers AS (
 SELECT es.*,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_profit_adj DESC) AS rank_year,
        RANK() OVER (PARTITION BY d_year ORDER BY net_profit_adj DESC) AS rank_dense_year,
        SUM(net_profit_adj) OVER (PARTITION BY customer_sk) AS total_profit_by_customer,
        (SELECT AVG(t2.net_profit_adj) FROM enriched_sales t2 WHERE t2.d_year = es.d_year) AS avg_profit_year,
        net_profit_adj / NULLIF((SELECT AVG(t2.net_profit_adj) FROM enriched_sales t2 WHERE t2.d_year = es.d_year),0) AS profit_vs_avg,
        CASE 
          WHEN net_profit_adj >= 5000 THEN 'VIP'
          WHEN net_profit_adj >= 1000 THEN 'PREMIUM'
          ELSE 'REGULAR'
        END AS profit_tier,
        CASE WHEN EXISTS (SELECT 1 FROM item i2 WHERE i2.i_item_sk = es.item_sk AND i2.i_brand = 'XYZ') THEN 1 ELSE 0 END AS has_brand_xyz,
        CONCAT(full_name, ' (', c_customer_id, ')') AS customer_display,
        (c_preferred_cust_flag = 'Y') AS is_preferred,
        COALESCE(ca_city, 'UNKNOWN') AS city,
        COALESCE(ca_state, 'UNKNOWN') AS state,
        COALESCE(call_center_name, 'NO_CC') AS call_center_name,
        (quantity * COALESCE(i_current_price, net_paid_adj)) AS est_revenue
 FROM enriched_sales es
 WHERE net_profit_adj IS NOT NULL
),
high_tier_customers AS (
 SELECT d_year,
        customer_sk,
        c_customer_id,
        full_name,
        c_email_address AS email,
        profit_tier,
        has_brand_xyz,
        net_paid_adj,
        net_profit_adj,
        total_profit_by_customer,
        rank_year,
        city,
        is_preferred,
        est_revenue
 FROM ranked_customers
 WHERE profit_tier IN ('VIP','PREMIUM')
),
email_customers AS (
 SELECT d_year,
        customer_sk,
        c_customer_id,
        full_name,
        c_email_address AS email,
        profit_tier,
        has_brand_xyz,
        net_paid_adj,
        net_profit_adj,
        total_profit_by_customer,
        rank_year,
        city,
        is_preferred,
        est_revenue
 FROM ranked_customers
 WHERE c_email_address IS NOT NULL AND c_email_address <> ''
),
final_customers AS (
 SELECT *
 FROM high_tier_customers
 INTERSECT
 SELECT *
 FROM email_customers
),
total_row AS (
 SELECT NULL AS d_year,
        NULL AS customer_sk,
        'TOTAL' AS c_customer_id,
        NULL AS full_name,
        NULL AS email,
        'TOTAL' AS profit_tier,
        NULL AS has_brand_xyz,
        SUM(net_paid_adj) AS net_paid_adj,
        SUM(net_profit_adj) AS net_profit_adj,
        SUM(total_profit_by_customer) AS total_profit_by_customer,
        NULL AS rank_year,
        NULL AS city,
        NULL AS is_preferred,
        SUM(est_revenue) AS est_revenue
 FROM final_customers
)
SELECT *
FROM final_customers
UNION ALL
SELECT *
FROM total_row
ORDER BY profit_tier DESC NULLS LAST, net_profit_adj DESC NULLS LAST
