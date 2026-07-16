WITH
sales_by_channel AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS total_qty,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        MAX(cs.cs_sold_date_sk) AS max_sold_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS ((d.d_date, d.d_year, d.d_month_seq), (d.d_year, d.d_month_seq), ())
    UNION ALL
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS total_qty,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        MAX(ss.ss_sold_date_sk) AS max_sold_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS ((d.d_date, d.d_year, d.d_month_seq), (d.d_year, d.d_month_seq), ())
    UNION ALL
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS total_qty,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        MAX(ws.ws_sold_date_sk) AS max_sold_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS ((d.d_date, d.d_year, d.d_month_seq), (d.d_year, d.d_month_seq), ())
),
customer_return_flags AS (
    SELECT
        c.c_customer_sk,
        MAX(CASE WHEN sr.sr_customer_sk IS NOT NULL THEN 1 ELSE 0 END) AS has_store_return,
        MAX(CASE WHEN cr.cr_returning_customer_sk IS NOT NULL THEN 1 ELSE 0 END) AS has_catalog_return,
        MAX(CASE WHEN wr.wr_refunded_customer_sk IS NOT NULL THEN 1 ELSE 0 END) AS has_web_return
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_refunded_customer_sk
    GROUP BY c.c_customer_sk
),
customer_profit AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(
            (SELECT SUM(cs.cs_net_paid) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = c.c_customer_sk),
            0
        ) +
        COALESCE(
            (SELECT SUM(ss.ss_net_paid) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk),
            0
        ) +
        COALESCE(
            (SELECT SUM(ws.ws_net_paid) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk),
            0
        ) AS total_paid,
        GREATEST(
            (SELECT MAX(d.d_date) FROM date_dim d JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk WHERE cs.cs_bill_customer_sk = c.c_customer_sk),
            (SELECT MAX(d2.d_date) FROM date_dim d2 JOIN store_sales ss ON ss.ss_sold_date_sk = d2.d_date_sk WHERE ss.ss_customer_sk = c.c_customer_sk),
            (SELECT MAX(d3.d_date) FROM date_dim d3 JOIN web_sales ws ON ws.ws_sold_date_sk = d3.d_date_sk WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
        ) AS latest_purchase_date
    FROM customer c
),
ranked_customers AS (
    SELECT
        cp.c_customer_sk,
        cp.c_customer_id,
        cp.total_paid,
        cp.latest_purchase_date,
        crf.has_store_return,
        crf.has_catalog_return,
        crf.has_web_return,
        COALESCE(
            NULLIF(cp.total_paid, 0) /
            NULLIF((crf.has_store_return + crf.has_catalog_return + crf.has_web_return), 0),
            0
        ) AS avg_paid_per_return_flag,
        ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('month', cp.latest_purchase_date) ORDER BY cp.total_paid DESC) AS month_rank,
        RANK() OVER (ORDER BY cp.total_paid DESC) AS global_rank,
        CONCAT('CUST-', COALESCE(cp.c_customer_id, 'UNKNOWN')) AS cust_label,
        CASE
            WHEN cp.latest_purchase_date IS NULL THEN 'NoPurchase'
            WHEN cp.total_paid > 10000 THEN 'VIP'
            ELSE 'Regular'
        END AS tier
    FROM customer_profit cp
    LEFT JOIN customer_return_flags crf ON cp.c_customer_sk = crf.c_customer_sk
)
SELECT
    rc.cust_label,
    rc.c_customer_sk,
    rc.total_paid,
    rc.latest_purchase_date,
    rc.tier,
    rc.month_rank,
    rc.global_rank,
    rc.avg_paid_per_return_flag,
    CASE
        WHEN rc.avg_paid_per_return_flag > 500 THEN 'HighValue'
        ELSE 'Standard'
    END AS value_category,
    COALESCE(
        (SELECT SUM(sbc.net_profit) FROM sales_by_channel sbc WHERE sbc.channel = 'catalog' AND sbc.d_year = EXTRACT(year FROM rc.latest_purchase_date)),
        0
    ) AS catalog_year_profit,
    COALESCE(
        (SELECT SUM(sbc.net_profit) FROM sales_by_channel sbc WHERE sbc.channel = 'store' AND sbc.d_year = EXTRACT(year FROM rc.latest_purchase_date)),
        0
    ) AS store_year_profit,
    COALESCE(
        (SELECT SUM(sbc.net_profit) FROM sales_by_channel sbc WHERE sbc.channel = 'web' AND sbc.d_year = EXTRACT(year FROM rc.latest_purchase_date)),
        0
    ) AS web_year_profit
FROM ranked_customers rc
WHERE rc.global_rank <= 100
ORDER BY rc.global_rank
