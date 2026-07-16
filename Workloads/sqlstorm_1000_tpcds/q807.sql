WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS call_center_sk,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS web_site_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_tax AS ext_tax,
        cs.cs_net_profit AS net_profit,
        'Catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        CAST(NULL AS integer),
        ss.ss_store_sk,
        CAST(NULL AS integer),
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_net_profit,
        'Store'
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_net_profit,
        'Web'
    FROM web_sales ws
),
agg_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COALESCE(cc.cc_state, s.s_state, ws_state.web_state) AS state,
        us.channel,
        SUM(us.ext_sales_price) AS total_sales,
        SUM(us.ext_tax) AS total_tax,
        SUM(us.net_profit) AS total_profit,
        SUM(us.quantity) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM unified_sales us
    JOIN date_dim d ON us.date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON us.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store s ON us.store_sk = s.s_store_sk
    LEFT JOIN web_site ws_state ON us.web_site_sk = ws_state.web_site_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        COALESCE(cc.cc_state, s.s_state, ws_state.web_state),
        us.channel
),
sales_with_growth AS (
    SELECT
        a.*,
        COALESCE(a.total_sales - prev.total_sales, 0) AS sales_diff,
        CASE
            WHEN prev.total_sales > 0 THEN ROUND((a.total_sales - prev.total_sales) / prev.total_sales * 100, 2)
            ELSE NULL
        END AS sales_yoy_pct,
        ROW_NUMBER() OVER (PARTITION BY a.state, a.channel ORDER BY a.total_sales DESC) AS sales_rank_state_channel
    FROM agg_sales a
    LEFT JOIN agg_sales prev
        ON a.state = prev.state
        AND a.channel = prev.channel
        AND a.d_year = prev.d_year + 1
        AND a.d_month_seq = prev.d_month_seq
)
SELECT *
FROM sales_with_growth
WHERE total_sales > 5000
ORDER BY d_year, d_month_seq, state, channel
