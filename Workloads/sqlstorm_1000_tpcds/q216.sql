WITH sales_union AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        s.s_state AS state,
        i.i_category AS category,
        'store' AS channel,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq AS month,
        w.web_state AS state,
        i.i_category AS category,
        'web' AS channel,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq AS month,
        cc.cc_state AS state,
        i.i_category AS category,
        'catalog' AS channel,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
), agg_sales AS (
    SELECT
        d_year,
        month,
        state,
        category,
        channel,
        SUM(sales_amount) AS total_sales,
        SUM(net_profit) AS total_profit,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT item_sk) AS distinct_items_sold,
        AVG(sales_amount) AS avg_sale_per_transaction,
        SUM(sales_amount) / NULLIF(SUM(quantity), 0) AS avg_price_per_unit,
        approx_percentile(sales_amount, 0.5) AS median_sales_amount,
        CASE WHEN SUM(sales_amount) = 0 THEN NULL ELSE SUM(net_profit) / SUM(sales_amount) END AS profit_margin
    FROM sales_union
    GROUP BY d_year, month, state, category, channel
    HAVING SUM(sales_amount) > 10000
)
SELECT
    d_year,
    month,
    state,
    category,
    channel,
    total_sales,
    total_profit,
    total_quantity,
    distinct_items_sold,
    avg_sale_per_transaction,
    avg_price_per_unit,
    median_sales_amount,
    profit_margin,
    ROW_NUMBER() OVER (PARTITION BY state, d_year, month ORDER BY total_sales DESC) AS sales_rank_state_month,
    LAG(total_sales) OVER (PARTITION BY state, channel, category ORDER BY d_year, month) AS prev_month_sales,
    CASE
        WHEN LAG(total_sales) OVER (PARTITION BY state, channel, category ORDER BY d_year, month) IS NULL THEN NULL
        ELSE (total_sales - LAG(total_sales) OVER (PARTITION BY state, channel, category ORDER BY d_year, month)) /
             LAG(total_sales) OVER (PARTITION BY state, channel, category ORDER BY d_year, month)
    END AS mom_growth
FROM agg_sales
ORDER BY d_year, month, state, total_sales DESC
LIMIT 200
