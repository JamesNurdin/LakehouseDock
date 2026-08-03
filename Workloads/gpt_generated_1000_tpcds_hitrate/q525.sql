WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        cr.cr_return_quantity AS cr_return_quantity,
        cr.cr_return_amount AS cr_return_amount,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        sr.sr_return_quantity AS sr_return_quantity,
        sr.sr_return_amt AS sr_return_amt,
        r.r_reason_desc,
        i.i_brand,
        i.i_category,
        s.s_state,
        d.d_year,
        c.c_preferred_cust_flag,
        array[ss.ss_quantity, sr.sr_return_quantity] AS qty_array
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk
        AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = ss.ss_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#45'
      AND s.s_state = 'CA'
      AND r.r_reason_desc = 'Damaged'
      AND c.c_preferred_cust_flag = 'Y'
),
common_customers AS (
    SELECT ss_customer_sk AS cust_sk FROM store_sales
    WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    INTERSECT
    SELECT ws_bill_customer_sk FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
)
SELECT
    b.i_brand,
    b.s_state,
    b.r_reason_desc,
    COUNT(DISTINCT b.ss_customer_sk) AS distinct_customers,
    SUM(b.ss_net_paid) AS total_store_sales,
    AVG(b.cs_net_paid) AS avg_catalog_sales,
    SUM(b.ws_net_paid) AS total_web_sales,
    MIN(u.qty) AS min_qty,
    MAX(u.qty) AS max_qty,
    (SELECT AVG(ss_net_profit) FROM store_sales) AS overall_avg_profit
FROM base b
JOIN common_customers cc ON b.ss_customer_sk = cc.cust_sk
CROSS JOIN LATERAL (
    SELECT q AS qty FROM UNNEST(b.qty_array) AS t(q)
) AS u
GROUP BY GROUPING SETS (
    (b.i_brand, b.s_state, b.r_reason_desc),
    (b.i_brand, b.s_state),
    (b.r_reason_desc)
)
ORDER BY total_store_sales DESC
LIMIT 100
