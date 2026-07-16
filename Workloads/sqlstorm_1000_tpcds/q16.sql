WITH
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'store' AS channel_type,
        CAST(s.s_store_sk AS VARCHAR) AS channel_id,
        ss.ss_item_sk AS item_sk,
        i.i_product_name AS item_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
        COUNT(*) FILTER (WHERE EXISTS (
            SELECT 1 FROM store_returns sr
            WHERE sr.sr_ticket_number = ss.ss_ticket_number
              AND sr.sr_item_sk = ss.ss_item_sk
        )) AS orders_with_returns
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_store_sk, ss.ss_item_sk, i.i_product_name
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'catalog' AS channel_type,
        cc.cc_call_center_id AS channel_id,
        cs.cs_item_sk AS item_sk,
        i.i_product_name AS item_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        COUNT(*) FILTER (WHERE EXISTS (
            SELECT 1 FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
              AND cr.cr_item_sk = cs.cs_item_sk
        )) AS orders_with_returns
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_call_center_id, cs.cs_item_sk, i.i_product_name
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'web' AS channel_type,
        wp.wp_web_page_id AS channel_id,
        ws.ws_item_sk AS item_sk,
        i.i_product_name AS item_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        COUNT(*) FILTER (WHERE EXISTS (
            SELECT 1 FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_item_sk = ws.ws_item_sk
        )) AS orders_with_returns
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, wp.wp_web_page_id, ws.ws_item_sk, i.i_product_name
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
sales_with_rank AS (
    SELECT
        cs.d_year,
        cs.d_month_seq,
        cs.channel_type,
        cs.channel_id,
        cs.item_sk,
        cs.item_name,
        cs.total_net_paid,
        cs.total_net_profit,
        cs.total_quantity,
        cs.distinct_orders,
        cs.orders_with_returns,
        RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.total_net_profit DESC) AS profit_rank,
        SUM(cs.total_net_profit) OVER (PARTITION BY cs.d_year, cs.d_month_seq) AS month_total_profit,
        CASE WHEN cs.total_quantity = 0 THEN NULL ELSE cs.total_net_profit / cs.total_quantity END AS profit_per_unit,
        ROW_NUMBER() OVER (PARTITION BY cs.d_year, cs.d_month_seq ORDER BY cs.total_net_paid DESC) AS paid_rank,
        (SELECT MAX(d2.d_date)
         FROM date_dim d2
         JOIN combined_sales cs2
           ON cs2.d_year = d2.d_year
          AND cs2.d_month_seq = d2.d_month_seq
         WHERE cs2.item_sk = cs.item_sk) AS latest_sale_date,
        CONCAT('Channel: ', cs.channel_type, ' ID: ', COALESCE(cs.channel_id, 'N/A')) AS channel_desc,
        CASE
            WHEN cs.total_net_paid IS NULL OR cs.total_net_paid = 0 THEN NULL
            ELSE cs.total_net_profit / cs.total_net_paid
        END AS profit_to_paid_ratio
    FROM combined_sales cs
),
filtered_sales AS (
    SELECT *
    FROM sales_with_rank
    WHERE (profit_per_unit > 0.5 OR profit_rank <= 5)
      AND (orders_with_returns > 0 OR total_net_profit > 0)
)
SELECT
    d_year,
    d_month_seq,
    channel_desc,
    item_name,
    total_net_paid,
    total_net_profit,
    month_total_profit,
    profit_per_unit,
    profit_rank,
    paid_rank,
    distinct_orders,
    orders_with_returns,
    CASE WHEN orders_with_returns > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag,
    CASE
        WHEN total_net_profit IS NULL AND total_net_paid IS NULL THEN 'No Data'
        WHEN total_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profitability_status,
    profit_to_paid_ratio,
    COALESCE(latest_sale_date, DATE '1900-01-01') AS latest_sale_date
FROM filtered_sales
ORDER BY d_year, d_month_seq, profit_rank
LIMIT 100
