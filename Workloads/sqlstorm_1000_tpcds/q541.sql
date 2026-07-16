WITH date_range AS (
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
sales_union AS (
    SELECT 'store' AS channel,
           ss.ss_store_sk AS entity_sk,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_ticket_number AS ticket_no
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_range)

    UNION ALL

    SELECT 'web' AS channel,
           ws.ws_web_page_sk AS entity_sk,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_order_number AS ticket_no
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_range)

    UNION ALL

    SELECT 'catalog' AS channel,
           cs.cs_call_center_sk AS entity_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_order_number AS ticket_no
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_range)
),
rank_by_channel AS (
    SELECT
        channel,
        entity_sk,
        date_sk,
        net_paid,
        net_profit,
        ticket_no,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY net_paid DESC) AS channel_rank,
        SUM(net_paid) OVER (PARTITION BY channel ORDER BY date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_paid
    FROM sales_union
),
detailed_sales AS (
    SELECT
        r.channel,
        r.entity_sk,
        d.d_date,
        r.net_paid,
        r.net_profit,
        r.channel_rank,
        r.cum_net_paid,
        COALESCE(
            CASE
                WHEN r.channel = 'store' THEN (SELECT s.s_store_name FROM store s WHERE s.s_store_sk = r.entity_sk)
                WHEN r.channel = 'web' THEN (SELECT wp.wp_url FROM web_page wp WHERE wp.wp_web_page_sk = r.entity_sk)
                WHEN r.channel = 'catalog' THEN (SELECT cc.cc_name FROM call_center cc WHERE cc.cc_call_center_sk = r.entity_sk)
                ELSE NULL
            END,
            'N/A'
        ) AS entity_name,
        (
            SELECT COUNT(*)
            FROM store_returns sr
            WHERE r.channel = 'store'
              AND sr.sr_store_sk = r.entity_sk
              AND sr.sr_returned_date_sk = r.date_sk
        ) AS store_return_cnt,
        (
            SELECT COUNT(*)
            FROM web_returns wr
            WHERE r.channel = 'web'
              AND wr.wr_web_page_sk = r.entity_sk
              AND wr.wr_returned_date_sk = r.date_sk
        ) AS web_return_cnt,
        (
            SELECT COUNT(*)
            FROM catalog_returns cr
            WHERE r.channel = 'catalog'
              AND cr.cr_call_center_sk = r.entity_sk
              AND cr.cr_returned_date_sk = r.date_sk
        ) AS cat_return_cnt,
        CONCAT(r.channel, ':', COALESCE(CAST(r.entity_sk AS VARCHAR), 'NULL')) AS entity_key,
        CASE WHEN r.net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign
    FROM rank_by_channel r
    LEFT JOIN date_dim d ON r.date_sk = d.d_date_sk
),
final AS (
    SELECT *
    FROM detailed_sales
    WHERE net_paid > 0
      AND COALESCE(store_return_cnt,0) + COALESCE(web_return_cnt,0) + COALESCE(cat_return_cnt,0) < 5
),
final_agg AS (
    SELECT
        channel,
        entity_key,
        entity_name,
        EXTRACT(year FROM d_date) AS yr,
        EXTRACT(month FROM d_date) AS mon,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        COUNT(*) AS txn_count,
        MAX(channel_rank) AS max_rank,
        SUM(COALESCE(store_return_cnt,0)) AS total_store_returns,
        SUM(COALESCE(web_return_cnt,0)) AS total_web_returns,
        SUM(COALESCE(cat_return_cnt,0)) AS total_catalog_returns
    FROM final
    GROUP BY
        channel,
        entity_key,
        entity_name,
        EXTRACT(year FROM d_date),
        EXTRACT(month FROM d_date)
    HAVING SUM(net_paid) > 1000
)
SELECT
    channel,
    entity_key,
    entity_name,
    yr,
    mon,
    total_net_paid,
    total_net_profit,
    txn_count,
    max_rank,
    total_store_returns,
    total_web_returns,
    total_catalog_returns,
    ROW_NUMBER() OVER (PARTITION BY yr ORDER BY total_net_paid DESC) AS yr_rank,
    approx_percentile(total_net_paid, 0.95) OVER (PARTITION BY channel) AS p95_total_net_paid,
    SUM(total_net_paid) OVER (PARTITION BY channel, yr ORDER BY mon ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_month_net_paid
FROM final_agg
ORDER BY total_net_paid DESC
LIMIT 100
