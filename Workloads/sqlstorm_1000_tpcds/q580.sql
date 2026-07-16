WITH
date_range AS (
    SELECT
        d_date_sk,
        d_date,
        DATE_TRUNC('month', d_date) AS month_start,
        format_datetime(d_date, 'yyyyMM') AS month_key
    FROM date_dim
    WHERE d_year = 2000
),
sales_combined AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        'store' AS channel,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_store_sk AS location_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_sold_date_sk,
        'catalog',
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_call_center_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        'web',
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_web_page_sk
    FROM web_sales ws
),
returns_combined AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        'store' AS channel,
        sr.sr_item_sk AS item_sk,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_return_quantity AS return_qty,
        sr.sr_return_amt AS return_amt,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    UNION ALL
    SELECT
        cr.cr_returned_date_sk,
        'catalog',
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        'web',
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
),
sales_monthly AS (
    SELECT
        d.month_start,
        d.month_key,
        s.channel,
        SUM(s.quantity) AS total_quantity,
        SUM(s.net_paid) AS total_sales,
        SUM(s.net_profit) AS total_profit,
        SUM(s.net_paid) - SUM(s.net_profit) AS total_cost_est,
        COUNT(*) AS total_orders,
        CASE
            WHEN SUM(s.net_paid) > 1000000 THEN 'high'
            WHEN SUM(s.net_paid) > 500000 THEN 'medium'
            ELSE 'low'
        END AS sales_volume_category,
        CONCAT(s.channel, '_', d.month_key) AS channel_month_key,
        MIN(s.location_sk) AS loc_sk,
        COUNT(DISTINCT s.customer_sk) AS distinct_customers
    FROM sales_combined s
    JOIN date_range d ON s.date_sk = d.d_date_sk
    GROUP BY d.month_start, d.month_key, s.channel
),
returns_monthly AS (
    SELECT
        d.month_start,
        r.channel,
        SUM(r.return_qty) AS total_return_qty,
        SUM(r.return_amt) AS total_return_amt,
        SUM(r.net_loss) AS total_net_loss
    FROM returns_combined r
    JOIN date_range d ON r.date_sk = d.d_date_sk
    GROUP BY d.month_start, r.channel
)
SELECT
    sm.month_start,
    sm.channel,
    sm.total_quantity,
    sm.total_sales,
    sm.total_profit,
    sm.total_cost_est,
    sm.total_orders,
    sm.sales_volume_category,
    sm.channel_month_key,
    COALESCE(rm.total_return_qty, 0) AS total_return_qty,
    COALESCE(rm.total_return_amt, 0) AS total_return_amt,
    COALESCE(rm.total_net_loss, 0) AS total_net_loss,
    sm.total_sales - COALESCE(rm.total_return_amt, 0) AS net_sales_after_returns,
    sm.total_profit - COALESCE(rm.total_net_loss, 0) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY sm.month_start ORDER BY sm.total_profit DESC) AS profit_rank,
    (SELECT AVG(prev.total_profit)
     FROM sales_monthly prev
     WHERE prev.channel = sm.channel
       AND prev.month_start < sm.month_start) AS avg_prior_profit,
    (SELECT COUNT(*)
     FROM sales_combined s2
     JOIN date_dim d2 ON s2.date_sk = d2.d_date_sk
     WHERE s2.channel = sm.channel
       AND DATE_TRUNC('month', d2.d_date) = sm.month_start
       AND s2.quantity > 5) AS high_quantity_orders,
    CASE
        WHEN sm.channel = 'catalog' THEN
            (SELECT COALESCE(cc.cc_manager, 'N/A')
             FROM call_center cc
             WHERE cc.cc_call_center_sk = sm.loc_sk)
        WHEN sm.channel = 'store' THEN
            (SELECT COALESCE(st.s_manager, 'N/A')
             FROM store st
             WHERE st.s_store_sk = sm.loc_sk)
        WHEN sm.channel = 'web' THEN
            (SELECT COALESCE(wp.wp_type, 'N/A')
             FROM web_page wp
             WHERE wp.wp_web_page_sk = sm.loc_sk)
        ELSE NULL
    END AS location_info,
    CONCAT('Month: ', CAST(sm.month_start AS VARCHAR),
           ', Channel: ', COALESCE(sm.channel, 'unknown'),
           ', Profit: ', CAST(sm.total_profit AS VARCHAR),
           ', Rank: ', CAST(RANK() OVER (PARTITION BY sm.month_start ORDER BY sm.total_profit DESC) AS VARCHAR)) AS report_desc,
    COALESCE(NULLIF(sm.sales_volume_category, 'low'), 'medium') AS adjusted_volume_category,
    sm.distinct_customers
FROM sales_monthly sm
LEFT JOIN returns_monthly rm
    ON sm.month_start = rm.month_start
   AND sm.channel = rm.channel
WHERE sm.total_sales > 0
ORDER BY sm.month_start, sm.channel
