WITH
sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_ext_tax AS tax_amount,
        cs.cs_net_profit AS profit,
        cs.cs_call_center_sk AS call_center_sk,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_net_profit,
        NULL,
        'store'
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_net_profit,
        NULL,
        'web'
    FROM web_sales ws
),
returns_union AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_returning_customer_sk AS customer_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_order_number AS order_number,
        cr.cr_return_quantity AS quantity,
        -cr.cr_return_amt_inc_tax AS sales_amount,
        -cr.cr_return_tax AS tax_amount,
        -cr.cr_net_loss AS profit,
        cr.cr_call_center_sk AS call_center_sk,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_customer_sk,
        sr.sr_item_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        -sr.sr_return_amt_inc_tax,
        -sr.sr_return_tax,
        -sr.sr_net_loss,
        NULL,
        'store'
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_item_sk,
        wr.wr_order_number,
        wr.wr_return_quantity,
        -wr.wr_return_amt_inc_tax,
        -wr.wr_return_tax,
        -wr.wr_net_loss,
        NULL,
        'web'
    FROM web_returns wr
),
all_transactions AS (
    SELECT * FROM sales_union
    UNION ALL
    SELECT * FROM returns_union
),
customer_year_agg AS (
    SELECT
        c.c_customer_sk AS cust_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year AS year,
        SUM(at.sales_amount) AS total_sales,
        SUM(at.tax_amount) AS total_tax,
        SUM(at.profit) AS total_profit,
        SUM(at.quantity) AS total_quantity,
        COUNT(DISTINCT at.order_number) AS distinct_orders,
        MAX(at.date_sk) AS latest_date_sk,
        array_agg(DISTINCT at.channel) AS channels
    FROM all_transactions at
    LEFT JOIN customer c ON at.customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON at.date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
),
customer_ranked AS (
    SELECT
        ca.*,
        ROW_NUMBER() OVER (PARTITION BY ca.cust_sk ORDER BY ca.total_sales DESC) AS year_rank,
        CONCAT(ca.c_first_name, ' ', ca.c_last_name) AS full_name,
        CASE
            WHEN ca.total_sales > 20000 THEN 'Platinum'
            WHEN ca.total_sales > 10000 THEN 'Gold'
            WHEN ca.total_sales > 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS sales_tier,
        CASE WHEN ca.total_sales = 0 THEN NULL ELSE ca.total_profit / NULLIF(ca.total_sales, 0) END AS profit_margin,
        CASE
            WHEN (SELECT d2.d_date FROM date_dim d2 WHERE d2.d_date_sk = ca.latest_date_sk) IS NULL THEN FALSE
            WHEN date_diff('day', (SELECT d2.d_date FROM date_dim d2 WHERE d2.d_date_sk = ca.latest_date_sk), DATE '2024-10-01') <= 30 THEN TRUE
            ELSE FALSE
        END AS recent_activity
    FROM customer_year_agg ca
),
best_year_per_customer AS (
    SELECT *
    FROM customer_ranked
    WHERE year_rank = 1
),
call_center_per_customer AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        MAX(cc.cc_name) AS call_center_name
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY cs.cs_bill_customer_sk
)
SELECT
    byc.c_customer_id,
    byc.full_name,
    byc.year,
    byc.total_sales,
    byc.total_tax,
    byc.total_profit,
    byc.total_quantity,
    byc.distinct_orders,
    byc.sales_tier,
    byc.profit_margin,
    byc.recent_activity,
    COALESCE(ccpc.call_center_name, 'NO CALL CENTER') AS call_center_name,
    CONCAT('$', format('%.2f', byc.total_sales)) AS total_sales_formatted,
    CONCAT('$', format('%.2f', byc.total_profit)) AS total_profit_formatted,
    array_join(byc.channels, ', ') AS channels_used
FROM best_year_per_customer byc
LEFT JOIN call_center_per_customer ccpc
    ON ccpc.cust_sk = byc.cust_sk
ORDER BY byc.total_sales DESC
LIMIT 100
