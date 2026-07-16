WITH
store_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_quarter_seq AS quarter,
        i.i_category AS category,
        s.s_state AS state,
        CAST(NULL AS varchar) AS department,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category, s.s_state
),
store_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_quarter_seq AS quarter,
        i.i_category AS category,
        s.s_state AS state,
        CAST(NULL AS varchar) AS department,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_transactions
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category, s.s_state
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_quarter_seq AS quarter,
        i.i_category AS category,
        CAST(NULL AS varchar) AS state,
        cp.cp_department AS department,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_transactions
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category, cp.cp_department
),
catalog_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_quarter_seq AS quarter,
        i.i_category AS category,
        CAST(NULL AS varchar) AS state,
        cp.cp_department AS department,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_transactions
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category, cp.cp_department
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_quarter_seq AS quarter,
        i.i_category AS category,
        CAST(NULL AS varchar) AS state,
        CAST(NULL AS varchar) AS department,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_transactions
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_quarter_seq AS quarter,
        i.i_category AS category,
        CAST(NULL AS varchar) AS state,
        CAST(NULL AS varchar) AS department,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_transactions
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
sales_union AS (
    SELECT 'Store' AS channel, year, quarter, category, state, department, total_sales, total_profit, sales_transactions FROM store_sales_agg
    UNION ALL
    SELECT 'Catalog' AS channel, year, quarter, category, state, department, total_sales, total_profit, sales_transactions FROM catalog_sales_agg
    UNION ALL
    SELECT 'Web' AS channel, year, quarter, category, state, department, total_sales, total_profit, sales_transactions FROM web_sales_agg
),
returns_union AS (
    SELECT 'Store' AS channel, year, quarter, category, state, department, total_return_amount, total_return_loss, return_transactions FROM store_returns_agg
    UNION ALL
    SELECT 'Catalog' AS channel, year, quarter, category, state, department, total_return_amount, total_return_loss, return_transactions FROM catalog_returns_agg
    UNION ALL
    SELECT 'Web' AS channel, year, quarter, category, state, department, total_return_amount, total_return_loss, return_transactions FROM web_returns_agg
)
SELECT
    t.channel,
    t.year,
    t.quarter,
    t.category,
    t.state,
    t.department,
    t.total_sales,
    t.total_profit,
    t.total_return_amount,
    t.total_return_loss,
    t.net_sales,
    t.net_profit,
    t.return_rate,
    t.profit_rank_in_year,
    LAG(t.net_profit) OVER (PARTITION BY t.channel, t.category ORDER BY t.year, t.quarter) AS prior_net_profit,
    CASE
        WHEN LAG(t.net_profit) OVER (PARTITION BY t.channel, t.category ORDER BY t.year, t.quarter) IS NULL
             OR LAG(t.net_profit) OVER (PARTITION BY t.channel, t.category ORDER BY t.year, t.quarter) = 0
        THEN NULL
        ELSE t.net_profit / LAG(t.net_profit) OVER (PARTITION BY t.channel, t.category ORDER BY t.year, t.quarter)
    END AS profit_growth
FROM (
    SELECT
        s.channel,
        s.year,
        s.quarter,
        s.category,
        s.state,
        s.department,
        s.total_sales,
        s.total_profit,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
        s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
        CASE WHEN s.total_sales = 0 THEN 0 ELSE COALESCE(r.total_return_amount, 0) / s.total_sales END AS return_rate,
        ROW_NUMBER() OVER (PARTITION BY s.channel, s.year ORDER BY s.total_profit DESC) AS profit_rank_in_year
    FROM sales_union s
    LEFT JOIN returns_union r
        ON s.channel = r.channel
        AND s.year = r.year
        AND s.quarter = r.quarter
        AND s.category = r.category
        AND ( (s.state IS NULL AND r.state IS NULL) OR (s.state = r.state) )
        AND ( (s.department IS NULL AND r.department IS NULL) OR (s.department = r.department) )
    WHERE s.year >= 1998
) t
ORDER BY t.channel, t.year, t.quarter, t.net_profit DESC
