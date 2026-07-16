WITH
    sales_union AS (
        SELECT
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_bill_customer_sk AS customer_sk,
            cs.cs_item_sk AS item_sk,
            cs.cs_quantity AS quantity,
            cs.cs_net_paid AS net_paid,
            cs.cs_ext_tax AS ext_tax,
            cs.cs_net_profit AS net_profit,
            'catalog' AS channel,
            cs.cs_order_number AS order_number,
            cs.cs_call_center_sk AS call_center_sk,
            NULL AS web_page_sk,
            NULL AS store_sk
        FROM catalog_sales cs
        UNION ALL
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_customer_sk,
            ss.ss_item_sk,
            ss.ss_quantity,
            ss.ss_net_paid,
            ss.ss_ext_tax,
            ss.ss_net_profit,
            'store' AS channel,
            ss.ss_ticket_number,
            NULL,
            NULL,
            ss.ss_store_sk
        FROM store_sales ss
        UNION ALL
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_bill_customer_sk,
            ws.ws_item_sk,
            ws.ws_quantity,
            ws.ws_net_paid,
            ws.ws_ext_tax,
            ws.ws_net_profit,
            'web' AS channel,
            ws.ws_order_number,
            NULL,
            ws.ws_web_page_sk,
            NULL
        FROM web_sales ws
    ),
    returns_union AS (
        SELECT
            cr.cr_returned_date_sk AS date_sk,
            cr.cr_returning_customer_sk AS customer_sk,
            cr.cr_item_sk AS item_sk,
            cr.cr_return_quantity AS quantity,
            cr.cr_return_amount AS net_paid,
            cr.cr_return_tax AS ext_tax,
            -cr.cr_net_loss AS net_profit,
            'catalog' AS channel,
            cr.cr_order_number AS order_number
        FROM catalog_returns cr
        UNION ALL
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_customer_sk,
            sr.sr_item_sk,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_return_tax,
            -sr.sr_net_loss,
            'store' AS channel,
            sr.sr_ticket_number
        FROM store_returns sr
        UNION ALL
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_refunded_customer_sk,
            wr.wr_item_sk,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            wr.wr_return_tax,
            -wr.wr_net_loss,
            'web' AS channel,
            wr.wr_order_number
        FROM web_returns wr
    ),
    latest_order AS (
        SELECT
            c.c_customer_sk,
            MAX(d.d_date) AS latest_order_date
        FROM customer c
        LEFT JOIN sales_union s ON c.c_customer_sk = s.customer_sk
        LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
        GROUP BY c.c_customer_sk
    ),
    agg_sales AS (
        SELECT
            s.customer_sk,
            d.d_year,
            d.d_month_seq,
            s.item_sk,
            i.i_category,
            i.i_class,
            i.i_brand,
            s.channel,
            SUM(s.quantity) AS total_quantity,
            SUM(s.net_paid) AS total_paid,
            SUM(s.net_profit) AS total_profit,
            COUNT(DISTINCT s.order_number) AS distinct_orders,
            ROW_NUMBER() OVER (PARTITION BY s.customer_sk ORDER BY SUM(s.net_profit) DESC) AS profit_rank
        FROM sales_union s
        LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
        LEFT JOIN item i ON s.item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND (d.d_month_seq BETWEEN 12 AND 24 OR COALESCE(d.d_holiday, 'N') = 'Y')
        GROUP BY
            s.customer_sk,
            d.d_year,
            d.d_month_seq,
            s.item_sk,
            i.i_category,
            i.i_class,
            i.i_brand,
            s.channel
    ),
    agg_returns AS (
        SELECT
            r.customer_sk,
            d.d_year,
            d.d_month_seq,
            r.item_sk,
            i.i_category,
            i.i_class,
            i.i_brand,
            r.channel,
            SUM(r.quantity) AS return_quantity,
            SUM(r.net_paid) AS return_amount,
            SUM(r.net_profit) AS return_profit,
            COUNT(DISTINCT r.order_number) AS distinct_return_orders
        FROM returns_union r
        LEFT JOIN date_dim d ON r.date_sk = d.d_date_sk
        LEFT JOIN item i ON r.item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY
            r.customer_sk,
            d.d_year,
            d.d_month_seq,
            r.item_sk,
            i.i_category,
            i.i_class,
            i.i_brand,
            r.channel
    ),
    combined AS (
        SELECT
            a.customer_sk,
            COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
            a.d_year,
            a.d_month_seq,
            a.item_sk,
            a.i_category,
            a.i_class,
            a.i_brand,
            a.channel,
            a.total_quantity,
            a.total_paid,
            a.total_profit,
            COALESCE(r.return_quantity, 0) AS return_quantity,
            COALESCE(r.return_amount, 0) AS return_amount,
            (a.total_profit - COALESCE(r.return_profit, 0)) AS net_profit_adj,
            a.distinct_orders,
            COALESCE(r.distinct_return_orders, 0) AS distinct_return_orders,
            a.profit_rank,
            COALESCE(lo.latest_order_date, DATE '1970-01-01') AS latest_order_date
        FROM agg_sales a
        LEFT JOIN agg_returns r
            ON a.customer_sk = r.customer_sk
            AND a.item_sk = r.item_sk
            AND a.channel = r.channel
            AND a.d_year = r.d_year
            AND a.d_month_seq = r.d_month_seq
        LEFT JOIN customer c ON a.customer_sk = c.c_customer_sk
        LEFT JOIN latest_order lo ON a.customer_sk = lo.c_customer_sk
    )
SELECT
    full_name,
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    channel,
    total_quantity,
    total_paid,
    net_profit_adj,
    return_quantity,
    return_amount,
    distinct_orders,
    distinct_return_orders,
    profit_rank,
    latest_order_date,
    CONCAT('Customer ', full_name, ' achieved net profit $', CAST(net_profit_adj AS VARCHAR)) AS profit_summary
FROM combined
WHERE profit_rank <= 10
   OR net_profit_adj > 10000
ORDER BY net_profit_adj DESC
LIMIT 100
