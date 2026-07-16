WITH
catalog_sales_agg AS (
    SELECT
        cs.cs_call_center_sk AS cc_sk,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY cs.cs_call_center_sk, d.d_year
),
catalog_returns_agg AS (
    SELECT
        cr.cr_call_center_sk AS cc_sk,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amt,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
        SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_call_center_sk, d.d_year
),
cs_with_returns AS (
    SELECT
        cs.cc_sk,
        cs.d_year,
        cs.total_net_paid,
        cs.total_net_profit,
        cs.distinct_orders,
        cs.total_quantity,
        cs.avg_sales_price,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.total_return_loss, 0) AS total_return_loss,
        COALESCE(cr.distinct_return_orders, 0) AS distinct_return_orders,
        COALESCE(cr.total_return_qty, 0) AS total_return_qty,
        cs.total_net_profit - COALESCE(cr.total_return_loss, 0) AS net_profit_after_returns,
        cs.total_net_paid - COALESCE(cr.total_return_amt, 0) AS net_paid_after_returns,
        CASE WHEN cs.total_net_paid = 0 THEN NULL ELSE (cs.total_net_paid - COALESCE(cr.total_return_amt, 0)) / cs.total_net_paid END AS net_paid_ratio
    FROM catalog_sales_agg cs
    LEFT JOIN catalog_returns_agg cr
        ON cs.cc_sk = cr.cc_sk AND cs.d_year = cr.d_year
),
store_sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY ss.ss_store_sk, d.d_year
),
store_returns_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_store_sk, d.d_year
),
store_with_returns AS (
    SELECT
        ss.store_sk,
        ss.d_year,
        ss.total_net_paid,
        ss.total_net_profit,
        ss.distinct_tickets,
        ss.total_quantity,
        ss.avg_sales_price,
        COALESCE(sr.total_return_amt, 0) AS total_return_amt,
        COALESCE(sr.total_return_loss, 0) AS total_return_loss,
        COALESCE(sr.distinct_return_tickets, 0) AS distinct_return_tickets,
        COALESCE(sr.total_return_qty, 0) AS total_return_qty,
        ss.total_net_profit - COALESCE(sr.total_return_loss, 0) AS net_profit_after_returns,
        ss.total_net_paid - COALESCE(sr.total_return_amt, 0) AS net_paid_after_returns,
        CASE WHEN ss.total_net_paid = 0 THEN NULL ELSE (ss.total_net_paid - COALESCE(sr.total_return_amt, 0)) / ss.total_net_paid END AS net_paid_ratio
    FROM store_sales_agg ss
    LEFT JOIN store_returns_agg sr
        ON ss.store_sk = sr.store_sk AND ss.d_year = sr.d_year
),
web_sales_agg AS (
    SELECT
        ws.ws_web_page_sk AS page_sk,
        d.d_year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY ws.ws_web_page_sk, d.d_year
),
web_returns_agg AS (
    SELECT
        wr.wr_web_page_sk AS page_sk,
        d.d_year,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY wr.wr_web_page_sk, d.d_year
),
web_with_returns AS (
    SELECT
        ws.page_sk,
        ws.d_year,
        ws.total_net_paid,
        ws.total_net_profit,
        ws.distinct_orders,
        ws.total_quantity,
        ws.avg_sales_price,
        COALESCE(wr.total_return_amt, 0) AS total_return_amt,
        COALESCE(wr.total_return_loss, 0) AS total_return_loss,
        COALESCE(wr.distinct_return_orders, 0) AS distinct_return_orders,
        COALESCE(wr.total_return_qty, 0) AS total_return_qty,
        ws.total_net_profit - COALESCE(wr.total_return_loss, 0) AS net_profit_after_returns,
        ws.total_net_paid - COALESCE(wr.total_return_amt, 0) AS net_paid_after_returns,
        CASE WHEN ws.total_net_paid = 0 THEN NULL ELSE (ws.total_net_paid - COALESCE(wr.total_return_amt, 0)) / ws.total_net_paid END AS net_paid_ratio
    FROM web_sales_agg ws
    LEFT JOIN web_returns_agg wr
        ON ws.page_sk = wr.page_sk AND ws.d_year = wr.d_year
),
combined AS (
    SELECT
        'catalog' AS channel,
        COALESCE(cc.cc_name, CONCAT('CC_', CAST(cs.cc_sk AS VARCHAR))) AS entity_name,
        cs.d_year,
        cs.total_net_paid,
        cs.total_net_profit,
        cs.net_paid_after_returns,
        cs.net_profit_after_returns,
        cs.net_paid_ratio,
        cs.distinct_orders,
        cs.total_quantity,
        cs.avg_sales_price,
        cs.total_return_amt,
        cs.total_return_qty,
        ROW_NUMBER() OVER (PARTITION BY cs.d_year ORDER BY cs.net_profit_after_returns DESC) AS profit_rank
    FROM cs_with_returns cs
    LEFT JOIN call_center cc ON cs.cc_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT
        'store' AS channel,
        COALESCE(s.s_store_name, CONCAT('Store_', CAST(st.store_sk AS VARCHAR))) AS entity_name,
        st.d_year,
        st.total_net_paid,
        st.total_net_profit,
        st.net_paid_after_returns,
        st.net_profit_after_returns,
        st.net_paid_ratio,
        st.distinct_tickets,
        st.total_quantity,
        st.avg_sales_price,
        st.total_return_amt,
        st.total_return_qty,
        ROW_NUMBER() OVER (PARTITION BY st.d_year ORDER BY st.net_profit_after_returns DESC) AS profit_rank
    FROM store_with_returns st
    LEFT JOIN store s ON st.store_sk = s.s_store_sk
    UNION ALL
    SELECT
        'web' AS channel,
        COALESCE(wp.wp_url, CONCAT('WP_', CAST(wb.page_sk AS VARCHAR))) AS entity_name,
        wb.d_year,
        wb.total_net_paid,
        wb.total_net_profit,
        wb.net_paid_after_returns,
        wb.net_profit_after_returns,
        wb.net_paid_ratio,
        wb.distinct_orders,
        wb.total_quantity,
        wb.avg_sales_price,
        wb.total_return_amt,
        wb.total_return_qty,
        ROW_NUMBER() OVER (PARTITION BY wb.d_year ORDER BY wb.net_profit_after_returns DESC) AS profit_rank
    FROM web_with_returns wb
    LEFT JOIN web_page wp ON wb.page_sk = wp.wp_web_page_sk
),
year_stats AS (
    SELECT
        d_year,
        COALESCE(AVG(total_net_profit), 0) AS avg_net_profit_all_channels
    FROM combined
    GROUP BY d_year
)
SELECT
    c.channel,
    c.entity_name,
    c.d_year,
    c.total_net_paid,
    c.total_net_profit,
    c.net_paid_after_returns,
    c.net_profit_after_returns,
    c.net_paid_ratio,
    c.distinct_orders,
    c.total_quantity,
    c.avg_sales_price,
    c.total_return_amt,
    c.total_return_qty,
    c.profit_rank,
    ys.avg_net_profit_all_channels,
    (SELECT SUM(c2.distinct_orders) FROM combined c2 WHERE c2.d_year = c.d_year) AS total_orders_by_year,
    CASE WHEN c.net_profit_after_returns < 0 THEN 'Loss' ELSE 'Profit' END AS profit_status
FROM combined c
LEFT JOIN year_stats ys ON c.d_year = ys.d_year
WHERE c.profit_rank <= 5
ORDER BY c.d_year, c.channel, c.profit_rank
