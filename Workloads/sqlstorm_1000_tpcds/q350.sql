WITH
sales_by_state AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        COALESCE(s.s_state, cc.cc_state, ws_site.web_state) AS state,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws_fact.ws_net_paid) AS web_net_paid,
        SUM(ws_fact.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT cs.cs_item_sk) AS catalog_items_sold,
        COUNT(DISTINCT ss.ss_item_sk) AS store_items_sold,
        COUNT(DISTINCT ws_fact.ws_item_sk) AS web_items_sold
    FROM date_dim d
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws_fact ON ws_fact.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_site ws_site ON ws_fact.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, d.d_quarter_name, COALESCE(s.s_state, cc.cc_state, ws_site.web_state)
),
returns_by_state AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        COALESCE(sr_s.s_state, cr_cc.cc_state) AS state,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM date_dim d
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN call_center cr_cc ON cr.cr_call_center_sk = cr_cc.cc_call_center_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN store sr_s ON sr.sr_store_sk = sr_s.s_store_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, d.d_quarter_name, COALESCE(sr_s.s_state, cr_cc.cc_state)
),
combined AS (
    SELECT
        s.d_year,
        s.d_quarter_name,
        s.state,
        s.catalog_net_paid,
        s.store_net_paid,
        s.web_net_paid,
        r.catalog_net_loss,
        r.store_net_loss,
        r.web_net_loss,
        ((s.catalog_net_paid - COALESCE(r.catalog_net_loss, 0))
         + (s.store_net_paid - COALESCE(r.store_net_loss, 0))
         + (s.web_net_paid - COALESCE(r.web_net_loss, 0))) AS total_net_adj,
        (s.catalog_net_profit + s.store_net_profit + s.web_net_profit) AS total_net_profit,
        (s.catalog_items_sold + s.store_items_sold + s.web_items_sold) AS total_items_sold
    FROM sales_by_state s
    LEFT JOIN returns_by_state r
        ON s.d_year = r.d_year
        AND s.d_quarter_name = r.d_quarter_name
        AND s.state = r.state
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_adj DESC) AS profit_rank_year,
        SUM(total_net_adj) OVER (PARTITION BY state ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_state_profit
    FROM combined
)
SELECT
    d_year,
    d_quarter_name,
    state,
    total_net_adj,
    total_net_profit,
    total_items_sold,
    profit_rank_year,
    cumulative_state_profit
FROM ranked
WHERE profit_rank_year <= 10
ORDER BY d_year, profit_rank_year
