WITH
store_sales_agg AS (
    SELECT
        'Store' AS channel,
        s.s_state AS state,
        d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        i.i_item_sk AS i_item_sk,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY s.s_state, d.d_year, d.d_quarter_seq, i.i_item_sk, i.i_category, i.i_brand
),
catalog_sales_agg AS (
    SELECT
        'Catalog' AS channel,
        cc.cc_state AS state,
        d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        i.i_item_sk AS i_item_sk,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY cc.cc_state, d.d_year, d.d_quarter_seq, i.i_item_sk, i.i_category, i.i_brand
),
web_sales_agg AS (
    SELECT
        'Web' AS channel,
        w.web_state AS state,
        d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        i.i_item_sk AS i_item_sk,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY w.web_state, d.d_year, d.d_quarter_seq, i.i_item_sk, i.i_category, i.i_brand
),
unified_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
store_returns_agg AS (
    SELECT
        'Store' AS channel,
        s.s_state AS state,
        d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        sr.sr_item_sk AS i_item_sk,
        SUM(sr.sr_return_quantity) AS return_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS return_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_state, d.d_year, d.d_quarter_seq, sr.sr_item_sk
),
catalog_returns_agg AS (
    SELECT
        'Catalog' AS channel,
        cc.cc_state AS state,
        d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        cr.cr_item_sk AS i_item_sk,
        SUM(cr.cr_return_quantity) AS return_quantity,
        SUM(cr.cr_return_amt_inc_tax) AS return_amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cc.cc_state, d.d_year, d.d_quarter_seq, cr.cr_item_sk
),
web_returns_agg AS (
    SELECT
        'Web' AS channel,
        w.web_state AS state,
        d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        wr.wr_item_sk AS i_item_sk,
        SUM(wr.wr_return_quantity) AS return_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS return_amount
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY w.web_state, d.d_year, d.d_quarter_seq, wr.wr_item_sk
),
unified_returns AS (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
),
sales_with_returns AS (
    SELECT
        s.channel,
        COALESCE(s.state, 'UNKNOWN') AS state,
        s.year,
        s.quarter_seq,
        s.i_item_sk,
        i.i_item_desc,
        i.i_manufact,
        s.i_category,
        s.i_brand,
        s.total_quantity,
        s.total_sales,
        s.total_discount,
        s.total_net_paid,
        s.total_net_profit,
        COALESCE(r.return_quantity, 0) AS return_quantity,
        COALESCE(r.return_amount, 0) AS return_amount,
        s.total_sales - COALESCE(r.return_amount, 0) AS net_sales_after_returns,
        CASE WHEN s.total_net_paid = 0 THEN 0 ELSE s.total_net_profit / s.total_net_paid END AS profit_margin,
        CONCAT(COALESCE(s.state, 'UNKNOWN'), '-', s.channel) AS region_channel,
        ROW_NUMBER() OVER (PARTITION BY s.channel, s.year, s.quarter_seq ORDER BY s.total_net_profit DESC) AS profit_rank,
        AVG(s.total_net_profit) OVER (PARTITION BY s.year, s.quarter_seq) AS avg_profit_all_channels,
        CASE WHEN s.total_net_profit > (SELECT AVG(total_net_profit) FROM unified_sales us WHERE us.year = s.year AND us.quarter_seq = s.quarter_seq) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_vs_average,
        AVG(s.total_net_profit) OVER (PARTITION BY s.channel ORDER BY s.year, s.quarter_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_profit_3q
    FROM unified_sales s
    LEFT JOIN unified_returns r
        ON s.channel = r.channel
        AND COALESCE(s.state, 'UNKNOWN') = COALESCE(r.state, 'UNKNOWN')
        AND s.year = r.year
        AND s.quarter_seq = r.quarter_seq
        AND s.i_item_sk = r.i_item_sk
    LEFT JOIN item i ON s.i_item_sk = i.i_item_sk
),
filtered AS (
    SELECT *
    FROM sales_with_returns
    WHERE profit_margin > 0.1
      AND (total_quantity > 10 OR total_sales > 1000)
      AND NOT (state IS NULL OR state = '')
)
SELECT
    channel,
    state,
    year,
    quarter_seq,
    SUM(total_quantity) AS sum_quantity,
    SUM(total_sales) AS sum_sales,
    SUM(return_quantity) AS sum_return_qty,
    SUM(return_amount) AS sum_return_amount,
    SUM(net_sales_after_returns) AS sum_net_sales,
    SUM(total_net_profit) AS sum_profit,
    AVG(profit_margin) AS avg_profit_margin,
    MAX(profit_rank) AS max_profit_rank,
    array_join(array_agg(DISTINCT i_brand), ', ') AS brands_sold,
    COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
    CASE WHEN SUM(total_net_profit) > 0 AND SUM(total_net_paid) > 0 THEN SUM(total_net_profit) / SUM(total_net_paid) ELSE 0 END AS overall_margin,
    log10(SUM(total_net_profit) + 1) AS lognetprofit,
    CONCAT(state, '-', channel) AS region_channel
FROM filtered
GROUP BY channel, state, year, quarter_seq
HAVING SUM(total_net_profit) > 0
ORDER BY channel, year, quarter_seq, sum_profit DESC
LIMIT 100
