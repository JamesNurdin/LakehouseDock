WITH
store_agg AS (
    SELECT
        s.s_state AS state,
        d.d_year AS year,
        d.d_month_seq AS month_num,
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_ext_sales_price) AS revenue,
        SUM(ss.ss_quantity) AS quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        'store' AS channel
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_state, d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name
),
catalog_agg AS (
    SELECT
        cc.cc_state AS state,
        d.d_year AS year,
        d.d_month_seq AS month_num,
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_ext_sales_price) AS revenue,
        SUM(cs.cs_quantity) AS quantity,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY cc.cc_state, d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name
),
web_agg AS (
    SELECT
        w.web_state AS state,
        d.d_year AS year,
        d.d_month_seq AS month_num,
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_ext_sales_price) AS revenue,
        SUM(ws.ws_quantity) AS quantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        'web' AS channel
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY w.web_state, d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name
),
union_agg AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
),
ranked_items AS (
    SELECT
        state,
        year,
        month_num,
        channel,
        i_item_sk,
        i_product_name,
        profit,
        revenue,
        quantity,
        unique_customers,
        ROW_NUMBER() OVER (PARTITION BY state, year, month_num, channel ORDER BY profit DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY state, year, month_num, channel ORDER BY revenue DESC) AS revenue_rank,
        LAG(profit) OVER (PARTITION BY state, channel, i_item_sk ORDER BY year, month_num) AS prev_profit,
        SUM(profit) OVER (PARTITION BY channel ORDER BY year, month_num ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM union_agg
)
SELECT
    state,
    year,
    month_num,
    channel,
    i_item_sk,
    i_product_name,
    profit,
    revenue,
    quantity,
    unique_customers,
    profit_rank,
    revenue_rank,
    prev_profit,
    profit - prev_profit AS profit_change,
    CASE WHEN prev_profit <> 0 THEN (profit - prev_profit) / prev_profit END AS profit_change_pct,
    profit / NULLIF(revenue, 0) AS profit_margin,
    cumulative_profit,
    AVG(profit) OVER (PARTITION BY channel, state ORDER BY year, month_num ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_profit_3m
FROM ranked_items
WHERE profit_rank <= 3
ORDER BY state, year, month_num, channel, profit_rank
