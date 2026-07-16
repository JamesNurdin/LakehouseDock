WITH
store_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        s.s_state AS state,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        cc.cc_state AS state,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        w.web_state AS state,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY d.d_year, d.d_month_seq, w.web_state
),
store_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        s.s_state AS state,
        SUM(sr.sr_net_loss) AS store_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state
),
catalog_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        cc.cc_state AS state,
        SUM(cr.cr_net_loss) AS catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state
),
web_returns_join AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_net_loss,
        ws.ws_web_site_sk
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
),
web_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        w.web_state AS state,
        SUM(j.wr_net_loss) AS web_return_loss
    FROM web_returns_join j
    JOIN date_dim d ON j.wr_returned_date_sk = d.d_date_sk
    JOIN web_site w ON j.ws_web_site_sk = w.web_site_sk
    GROUP BY d.d_year, d.d_month_seq, w.web_state
),
sales_combined AS (
    SELECT
        year,
        month,
        state,
        SUM(store_profit) AS store_profit,
        SUM(catalog_profit) AS catalog_profit,
        SUM(web_profit) AS web_profit,
        SUM(store_profit) + SUM(catalog_profit) + SUM(web_profit) AS total_sales_profit
    FROM (
        SELECT year, month, state, store_profit, 0 AS catalog_profit, 0 AS web_profit FROM store_sales_agg
        UNION ALL
        SELECT year, month, state, 0, catalog_profit, 0 FROM catalog_sales_agg
        UNION ALL
        SELECT year, month, state, 0, 0, web_profit FROM web_sales_agg
    ) x
    GROUP BY year, month, state
),
returns_combined AS (
    SELECT
        year,
        month,
        state,
        SUM(store_return_loss) AS store_return_loss,
        SUM(catalog_return_loss) AS catalog_return_loss,
        SUM(web_return_loss) AS web_return_loss,
        SUM(store_return_loss) + SUM(catalog_return_loss) + SUM(web_return_loss) AS total_return_loss
    FROM (
        SELECT year, month, state, store_return_loss, 0 AS catalog_return_loss, 0 AS web_return_loss FROM store_returns_agg
        UNION ALL
        SELECT year, month, state, 0, catalog_return_loss, 0 FROM catalog_returns_agg
        UNION ALL
        SELECT year, month, state, 0, 0, web_return_loss FROM web_returns_agg
    ) r
    GROUP BY year, month, state
)
SELECT
    s.year,
    s.month,
    s.state,
    s.store_profit,
    s.catalog_profit,
    s.web_profit,
    s.total_sales_profit,
    COALESCE(r.store_return_loss, 0) AS store_return_loss,
    COALESCE(r.catalog_return_loss, 0) AS catalog_return_loss,
    COALESCE(r.web_return_loss, 0) AS web_return_loss,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY s.year, s.month ORDER BY s.total_sales_profit - COALESCE(r.total_return_loss, 0) DESC) AS profit_rank
FROM sales_combined s
LEFT JOIN returns_combined r
    ON s.year = r.year AND s.month = r.month AND s.state = r.state
WHERE s.year >= 2000
ORDER BY s.year, s.month, net_profit_after_returns DESC
