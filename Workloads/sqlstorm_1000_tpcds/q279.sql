WITH
    sales AS (
        SELECT
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_item_sk AS item_sk,
            ca.ca_state AS state,
            d.d_year AS year,
            d.d_month_seq AS month,
            i.i_category AS category,
            'Catalog' AS channel,
            cs.cs_ext_sales_price AS sales_amount,
            cs.cs_ext_discount_amt AS discount_amount,
            cs.cs_net_paid AS net_paid,
            cs.cs_net_profit AS profit,
            cs.cs_order_number AS order_number,
            cs.cs_quantity AS quantity
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    ),
    store_sales_agg AS (
        SELECT
            ss.ss_sold_date_sk AS date_sk,
            ss.ss_item_sk AS item_sk,
            ca.ca_state AS state,
            d.d_year AS year,
            d.d_month_seq AS month,
            i.i_category AS category,
            'Store' AS channel,
            ss.ss_ext_sales_price AS sales_amount,
            ss.ss_ext_discount_amt AS discount_amount,
            ss.ss_net_paid AS net_paid,
            ss.ss_net_profit AS profit,
            ss.ss_ticket_number AS order_number,
            ss.ss_quantity AS quantity
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_sold_date_sk AS date_sk,
            ws.ws_item_sk AS item_sk,
            ca.ca_state AS state,
            d.d_year AS year,
            d.d_month_seq AS month,
            i.i_category AS category,
            'Web' AS channel,
            ws.ws_ext_sales_price AS sales_amount,
            ws.ws_ext_discount_amt AS discount_amount,
            ws.ws_net_paid AS net_paid,
            ws.ws_net_profit AS profit,
            ws.ws_order_number AS order_number,
            ws.ws_quantity AS quantity
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    ),
    combined_sales AS (
        SELECT * FROM sales
        UNION ALL
        SELECT * FROM store_sales_agg
        UNION ALL
        SELECT * FROM web_sales_agg
    ),
    returns AS (
        SELECT
            cr.cr_returned_date_sk AS date_sk,
            cr.cr_item_sk AS item_sk,
            ca.ca_state AS state,
            d.d_year AS year,
            d.d_month_seq AS month,
            i.i_category AS category,
            'Catalog' AS channel,
            cr.cr_return_amount AS return_amount,
            cr.cr_return_quantity AS return_quantity
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        UNION ALL
        SELECT
            sr.sr_returned_date_sk AS date_sk,
            sr.sr_item_sk AS item_sk,
            ca.ca_state AS state,
            d.d_year AS year,
            d.d_month_seq AS month,
            i.i_category AS category,
            'Store' AS channel,
            sr.sr_return_amt AS return_amount,
            sr.sr_return_quantity AS return_quantity
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        UNION ALL
        SELECT
            wr.wr_returned_date_sk AS date_sk,
            wr.wr_item_sk AS item_sk,
            ca.ca_state AS state,
            d.d_year AS year,
            d.d_month_seq AS month,
            i.i_category AS category,
            'Web' AS channel,
            wr.wr_return_amt AS return_amount,
            wr.wr_return_quantity AS return_quantity
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    ),
    agg AS (
        SELECT
            cs.year,
            cs.month,
            cs.state,
            cs.category,
            cs.channel,
            SUM(cs.sales_amount) AS total_sales,
            SUM(cs.discount_amount) AS total_discount,
            SUM(cs.net_paid) AS total_net_paid,
            SUM(cs.profit) AS total_profit,
            COUNT(DISTINCT cs.order_number) AS orders,
            SUM(cs.quantity) AS total_quantity
        FROM combined_sales cs
        GROUP BY
            cs.year,
            cs.month,
            cs.state,
            cs.category,
            cs.channel
    ),
    return_agg AS (
        SELECT
            r.year,
            r.month,
            r.state,
            r.category,
            r.channel,
            SUM(r.return_amount) AS total_return_amount,
            SUM(r.return_quantity) AS total_return_quantity
        FROM returns r
        GROUP BY
            r.year,
            r.month,
            r.state,
            r.category,
            r.channel
    )
SELECT
    a.year,
    a.month,
    a.state,
    a.category,
    a.channel,
    a.total_sales,
    a.total_discount,
    a.total_net_paid,
    a.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    a.total_net_paid - COALESCE(r.total_return_amount, 0) AS net_revenue,
    ROUND(CASE WHEN a.total_sales = 0 THEN 0 ELSE (a.total_discount / a.total_sales) * 100 END, 2) AS discount_pct,
    ROUND(CASE WHEN a.total_sales = 0 THEN 0 ELSE (a.total_profit / a.total_sales) * 100 END, 2) AS profit_margin_pct,
    SUM(a.total_profit) OVER (
        PARTITION BY a.channel, a.state, a.year
        ORDER BY a.month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS profit_ytd,
    RANK() OVER (PARTITION BY a.year, a.state, a.channel ORDER BY a.total_profit DESC) AS profit_rank_in_state_channel_year
FROM agg a
LEFT JOIN return_agg r
    ON a.year = r.year
    AND a.month = r.month
    AND a.state = r.state
    AND a.category = r.category
    AND a.channel = r.channel
WHERE a.year BETWEEN 1998 AND 2002
ORDER BY a.year, a.month, a.state, a.category, a.channel
LIMIT 500
