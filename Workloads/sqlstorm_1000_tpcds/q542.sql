WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel,
        CAST(NULL AS integer) AS store_sk,
        cs.cs_call_center_sk AS call_center_sk,
        CAST(NULL AS integer) AS web_page_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        'store' AS channel,
        ss.ss_store_sk,
        CAST(NULL AS integer),
        CAST(NULL AS integer)
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        'web' AS channel,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        ws.ws_web_page_sk
    FROM web_sales ws
),
sales_base AS (
    SELECT
        us.*,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        COALESCE(s.s_store_name, c.cc_name, wp.wp_url) AS location_name
    FROM unified_sales us
    LEFT JOIN date_dim d ON us.date_sk = d.d_date_sk
    LEFT JOIN store s ON us.store_sk = s.s_store_sk
    LEFT JOIN call_center c ON us.call_center_sk = c.cc_call_center_sk
    LEFT JOIN web_page wp ON us.web_page_sk = wp.wp_web_page_sk
),
sales_item AS (
    SELECT
        sb.*,
        i.i_category,
        i.i_brand,
        i.i_class
    FROM sales_base sb
    LEFT JOIN item i ON sb.item_sk = i.i_item_sk
),
ranked_sales AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY channel, d_year, d_month_seq, i_category ORDER BY net_profit DESC) AS profit_rank
    FROM sales_item
)
SELECT
    channel,
    d_year,
    d_month_seq,
    i_category,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    COUNT(DISTINCT order_number) AS distinct_orders,
    approx_percentile(net_profit, 0.5) AS median_profit,
    MAX(CASE WHEN profit_rank = 1 THEN net_profit END) AS top_profit,
    SUM(CASE WHEN profit_rank <= 10 THEN net_profit ELSE 0 END) AS top10_profit_sum
FROM ranked_sales
WHERE profit_rank <= 10
GROUP BY
    channel,
    d_year,
    d_month_seq,
    i_category
ORDER BY
    channel,
    d_year,
    d_month_seq,
    i_category
