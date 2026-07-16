WITH sales_raw AS (
    SELECT 'Catalog' AS channel,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_quantity AS quantity,
           cs.cs_sales_price AS sales_price,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_order_number AS order_number
    FROM catalog_sales cs
    UNION ALL
    SELECT 'Store' AS channel,
           ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_customer_sk,
           ss.ss_quantity,
           ss.ss_sales_price,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_ticket_number
    FROM store_sales ss
    UNION ALL
    SELECT 'Web' AS channel,
           ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_quantity,
           ws.ws_sales_price,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_order_number
    FROM web_sales ws
),
sales_enriched AS (
    SELECT
        sr.channel,
        sr.date_sk,
        d.d_year,
        d.d_month_seq,
        sr.item_sk,
        sr.customer_sk,
        sr.quantity,
        sr.sales_price,
        sr.net_paid,
        sr.net_profit,
        COALESCE((
            SELECT p.p_promo_name
            FROM promotion p
            WHERE p.p_item_sk = sr.item_sk
              AND p.p_start_date_sk <= sr.date_sk
              AND p.p_end_date_sk >= sr.date_sk
            ORDER BY p.p_start_date_sk DESC
            LIMIT 1
        ), 'No Promo') AS promo_name,
        COALESCE(CONCAT(c.c_first_name, ' ', c.c_last_name), 'Anonymous') AS customer_name,
        CASE
            WHEN sr.net_profit IS NULL THEN 'Unknown'
            WHEN sr.net_profit > 1000 THEN 'High'
            WHEN sr.net_profit < 0 THEN 'Loss'
            ELSE 'Normal'
        END AS profit_category,
        CASE WHEN EXISTS (
            SELECT 1 FROM sales_raw sr2
            WHERE sr2.customer_sk = sr.customer_sk
              AND sr2.channel = sr.channel
              AND sr2.date_sk > sr.date_sk
        ) THEN 'Repeat' ELSE 'First' END AS customer_status,
        ROW_NUMBER() OVER (PARTITION BY sr.channel, sr.item_sk ORDER BY sr.date_sk DESC) AS rn_item
    FROM sales_raw sr
    LEFT JOIN date_dim d ON sr.date_sk = d.d_date_sk
    LEFT JOIN customer c ON sr.customer_sk = c.c_customer_sk
),
sales_agg AS (
    SELECT
        channel,
        d_year,
        d_month_seq,
        SUM(net_profit) AS total_profit,
        COUNT(*) AS total_sales,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        GROUPING(d_year) AS g_year,
        GROUPING(d_month_seq) AS g_month
    FROM sales_enriched
    GROUP BY GROUPING SETS ((channel, d_year, d_month_seq), (channel, d_year), (channel))
),
returns_raw AS (
    SELECT 'Catalog' AS channel,
           cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT 'Store' AS channel,
           sr.sr_returned_date_sk,
           sr.sr_item_sk,
           sr.sr_net_loss
    FROM store_returns sr
    UNION ALL
    SELECT 'Web' AS channel,
           wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_net_loss
    FROM web_returns wr
),
returns_agg AS (
    SELECT
        channel,
        d_year,
        d_month_seq,
        SUM(net_loss) AS total_return_loss,
        GROUPING(d_year) AS g_year,
        GROUPING(d_month_seq) AS g_month
    FROM (
        SELECT
            rr.channel,
            rr.date_sk,
            d.d_year,
            d.d_month_seq,
            rr.net_loss
        FROM returns_raw rr
        LEFT JOIN date_dim d ON rr.date_sk = d.d_date_sk
    ) r
    GROUP BY GROUPING SETS ((channel, d_year, d_month_seq), (channel, d_year), (channel))
),
combined AS (
    SELECT
        COALESCE(sa.channel, ra.channel) AS channel,
        COALESCE(sa.d_year, ra.d_year) AS d_year,
        COALESCE(sa.d_month_seq, ra.d_month_seq) AS d_month_seq,
        COALESCE(sa.total_profit, 0) AS total_profit,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        COALESCE(sa.total_profit, 0) - COALESCE(ra.total_return_loss, 0) AS net_profit_after_returns,
        COALESCE(sa.total_sales, 0) AS total_sales,
        COALESCE(sa.distinct_customers, 0) AS distinct_customers,
        COALESCE(sa.g_year, ra.g_year) AS g_year,
        COALESCE(sa.g_month, ra.g_month) AS g_month
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.channel = ra.channel
       AND (sa.d_year = ra.d_year OR (sa.d_year IS NULL AND ra.d_year IS NULL))
       AND (sa.d_month_seq = ra.d_month_seq OR (sa.d_month_seq IS NULL AND ra.d_month_seq IS NULL))
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY net_profit_after_returns DESC) AS rank_by_profit
    FROM combined
)
SELECT
    channel,
    CASE
        WHEN g_year = 0 AND g_month = 0 THEN CONCAT('M', CAST(d_month_seq AS VARCHAR), '-Y', CAST(d_year AS VARCHAR))
        WHEN g_year = 0 AND g_month = 1 THEN CONCAT('Y', CAST(d_year AS VARCHAR))
        ELSE 'ALL'
    END AS period,
    total_profit,
    total_return_loss,
    net_profit_after_returns,
    total_sales,
    distinct_customers,
    rank_by_profit
FROM ranked
WHERE rank_by_profit <= 10
ORDER BY channel, rank_by_profit
