WITH
sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
intersect_orders AS (
    SELECT ss_ticket_number AS order_num FROM store_sales
    INTERSECT
    SELECT ws_order_number FROM web_sales
),
joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        i.i_category,
        s.s_store_name,
        ca.ca_state,
        r.r_reason_desc,
        wr.wr_return_amt,
        ws.ws_net_paid AS web_net_paid,
        ws.ws_bill_customer_sk AS ws_customer_sk,
        cs.cs_net_paid_inc_tax AS catalog_net_paid,
        lt.extra_discount
    FROM sampled_store_sales ss
    FULL OUTER JOIN web_sales ws
        ON ws.ws_item_sk = ss.ss_item_sk
    LEFT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = ss.ss_item_sk
    LEFT JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT ss.ss_ext_sales_price * 0.05 AS extra_discount
    ) lt
    WHERE ss.ss_ticket_number IN (SELECT order_num FROM intersect_orders)
      AND EXISTS (SELECT 1 FROM reason r2 WHERE r2.r_reason_desc = r.r_reason_desc)
)
SELECT
    s_store_name,
    i_category,
    COUNT(DISTINCT ss_customer_sk) AS uniq_store_customers,
    COUNT(DISTINCT ca_state) AS uniq_states,
    SUM(ss_net_paid) AS total_store_sales,
    COUNT(DISTINCT ws_customer_sk) AS uniq_web_customers,
    SUM(web_net_paid) AS total_web_sales,
    SUM(extra_discount) AS total_extra_discount,
    COUNT(DISTINCT r_reason_desc) AS uniq_return_reasons
FROM joined_data
GROUP BY ROLLUP (s_store_name, i_category)
ORDER BY s_store_name NULLS LAST, i_category
LIMIT 100
