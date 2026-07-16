WITH
    sales_union AS (
        SELECT
            cs_bill_customer_sk AS customer_sk,
            cs_sold_date_sk AS date_sk,
            cs_net_paid AS net_paid,
            cs_net_profit AS net_profit,
            cs_quantity AS quantity,
            'Catalog' AS sales_channel,
            cs_order_number AS order_number
        FROM catalog_sales
        UNION ALL
        SELECT
            ss_customer_sk AS customer_sk,
            ss_sold_date_sk AS date_sk,
            ss_net_paid AS net_paid,
            ss_net_profit AS net_profit,
            ss_quantity AS quantity,
            'Store' AS sales_channel,
            ss_ticket_number AS order_number
        FROM store_sales
        UNION ALL
        SELECT
            ws_bill_customer_sk AS customer_sk,
            ws_sold_date_sk AS date_sk,
            ws_net_paid AS net_paid,
            ws_net_profit AS net_profit,
            ws_quantity AS quantity,
            'Web' AS sales_channel,
            ws_order_number AS order_number
        FROM web_sales
    ),
    returns_union AS (
        SELECT
            sr_customer_sk AS customer_sk,
            sr_returned_date_sk AS date_sk,
            sr_return_amt_inc_tax AS return_amount,
            sr_net_loss AS net_loss,
            sr_return_quantity AS return_quantity,
            sr_ticket_number AS return_ticket,
            'Store' AS return_channel
        FROM store_returns
        UNION ALL
        SELECT
            cr_returning_customer_sk AS customer_sk,
            cr_returned_date_sk AS date_sk,
            cr_return_amt_inc_tax AS return_amount,
            cr_net_loss AS net_loss,
            cr_return_quantity AS return_quantity,
            cr_order_number AS return_ticket,
            'Catalog' AS return_channel
        FROM catalog_returns
        UNION ALL
        SELECT
            wr_refunded_customer_sk AS customer_sk,
            wr_returned_date_sk AS date_sk,
            wr_return_amt_inc_tax AS return_amount,
            wr_net_loss AS net_loss,
            wr_return_quantity AS return_quantity,
            wr_order_number AS return_ticket,
            'Web' AS return_channel
        FROM web_returns
    ),
    customer_aggregates AS (
        SELECT
            c.c_customer_sk,
            COALESCE(c.c_first_name, 'Unknown') || ' ' || COALESCE(c.c_last_name, 'Customer') AS full_name,
            SUM(s.net_paid) AS total_paid,
            SUM(s.net_profit) AS total_profit,
            SUM(s.quantity) AS total_quantity,
            COUNT(DISTINCT s.order_number) AS distinct_orders,
            COUNT(DISTINCT s.sales_channel) AS sales_channels,
            MAX(s.date_sk) AS last_sale_date_sk,
            MIN(s.date_sk) AS first_sale_date_sk
        FROM customer c
        LEFT JOIN sales_union s ON c.c_customer_sk = s.customer_sk
        GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ),
    return_aggregates AS (
        SELECT
            c.c_customer_sk,
            COALESCE(c.c_first_name, 'Unknown') || ' ' || COALESCE(c.c_last_name, 'Customer') AS full_name,
            SUM(r.return_amount) AS total_return_amount,
            SUM(r.net_loss) AS total_return_loss,
            SUM(r.return_quantity) AS total_return_quantity,
            COUNT(DISTINCT r.return_ticket) AS distinct_return_tickets,
            COUNT(DISTINCT r.return_channel) AS return_channels,
            MAX(r.date_sk) AS last_return_date_sk,
            MIN(r.date_sk) AS first_return_date_sk
        FROM customer c
        LEFT JOIN returns_union r ON c.c_customer_sk = r.customer_sk
        GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ),
    combined AS (
        SELECT
            ca.c_customer_sk,
            ca.full_name,
            ca.total_paid,
            ca.total_profit,
            ca.total_quantity,
            ca.distinct_orders,
            ca.sales_channels,
            ca.first_sale_date_sk,
            ca.last_sale_date_sk,
            ra.total_return_amount,
            ra.total_return_loss,
            ra.total_return_quantity,
            ra.distinct_return_tickets,
            ra.return_channels,
            ra.first_return_date_sk,
            ra.last_return_date_sk,
            (ca.total_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
            CASE
                WHEN ca.total_paid IS NULL THEN 0
                ELSE ca.total_paid
            END - COALESCE(ra.total_return_amount, 0) AS net_revenue
        FROM customer_aggregates ca
        LEFT JOIN return_aggregates ra ON ca.c_customer_sk = ra.c_customer_sk
    ),
    ranked AS (
        SELECT
            c.*,
            ROW_NUMBER() OVER (ORDER BY net_profit_after_returns DESC NULLS LAST) AS profit_rank,
            RANK() OVER (PARTITION BY sales_channels ORDER BY net_revenue DESC) AS channel_rank,
            NTILE(10) OVER (ORDER BY net_revenue) AS revenue_decile
        FROM combined c
    )
SELECT
    r.c_customer_sk,
    r.full_name,
    CONCAT('CUST-', LPAD(CAST(r.c_customer_sk AS VARCHAR), 10, '0')) AS formatted_customer_id,
    r.sales_channels,
    r.return_channels,
    r.total_paid,
    r.total_return_amount,
    r.net_revenue,
    r.total_profit,
    r.total_return_loss,
    r.net_profit_after_returns,
    r.profit_rank,
    r.channel_rank,
    r.revenue_decile,
    CASE
        WHEN r.net_profit_after_returns > 1000 THEN 'HIGH'
        WHEN r.net_profit_after_returns BETWEEN 0 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    COALESCE(d.d_year, 0) AS last_sale_year,
    COALESCE(r_last.d_year, 0) AS last_return_year,
    (SELECT AVG(ss.ss_net_paid) FROM store_sales ss WHERE ss.ss_customer_sk = r.c_customer_sk) AS avg_store_net_paid,
    (SELECT MAX(ss.ss_quantity) FROM store_sales ss WHERE ss.ss_customer_sk = r.c_customer_sk) AS max_store_quantity,
    CASE
        WHEN r.total_paid IS NULL THEN r.total_return_amount
        WHEN r.total_return_amount IS NULL THEN r.total_paid
        ELSE r.total_paid - r.total_return_amount
    END AS net_balance_calc
FROM ranked r
LEFT JOIN date_dim d ON r.last_sale_date_sk = d.d_date_sk
LEFT JOIN date_dim r_last ON r.last_return_date_sk = r_last.d_date_sk
WHERE (r.sales_channels > 0 OR r.return_channels > 0)
  AND (r.total_paid IS NOT NULL OR r.total_return_amount IS NOT NULL)
ORDER BY r.profit_rank
LIMIT 100
