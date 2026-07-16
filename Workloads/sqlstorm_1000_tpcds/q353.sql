WITH
store_agg AS (
 SELECT s.s_store_id AS entity_id,
        d.d_year,
        d.d_month_seq AS month_key,
        SUM(ss.ss_net_paid) AS net_sales,
        SUM(ss.ss_net_profit) AS profit,
        COUNT(*) AS sales_txn
 FROM store_sales ss
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
 GROUP BY s.s_store_id, d.d_year, d.d_month_seq
),
store_ret_agg AS (
 SELECT s.s_store_id AS entity_id,
        d.d_year,
        d.d_month_seq AS month_key,
        SUM(sr.sr_net_loss) AS net_loss,
        COUNT(*) AS returns_txn
 FROM store_returns sr
 JOIN store s ON sr.sr_store_sk = s.s_store_sk
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
 GROUP BY s.s_store_id, d.d_year, d.d_month_seq
),
catalog_agg AS (
 SELECT cp.cp_catalog_page_id AS entity_id,
        d.d_year,
        d.d_month_seq AS month_key,
        SUM(cs.cs_net_paid) AS net_sales,
        SUM(cs.cs_net_profit) AS profit,
        COUNT(*) AS sales_txn
 FROM catalog_sales cs
 JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
 GROUP BY cp.cp_catalog_page_id, d.d_year, d.d_month_seq
),
catalog_ret_agg AS (
 SELECT cp.cp_catalog_page_id AS entity_id,
        d.d_year,
        d.d_month_seq AS month_key,
        SUM(cr.cr_net_loss) AS net_loss,
        COUNT(*) AS returns_txn
 FROM catalog_returns cr
 JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
 GROUP BY cp.cp_catalog_page_id, d.d_year, d.d_month_seq
),
web_agg AS (
 SELECT ws.ws_web_page_sk AS entity_id,
        d.d_year,
        d.d_month_seq AS month_key,
        SUM(ws.ws_net_paid) AS net_sales,
        SUM(ws.ws_net_profit) AS profit,
        COUNT(*) AS sales_txn
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
 GROUP BY ws.ws_web_page_sk, d.d_year, d.d_month_seq
),
web_ret_agg AS (
 SELECT wr.wr_web_page_sk AS entity_id,
        d.d_year,
        d.d_month_seq AS month_key,
        SUM(wr.wr_net_loss) AS net_loss,
        COUNT(*) AS returns_txn
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
 GROUP BY wr.wr_web_page_sk, d.d_year, d.d_month_seq
),
combined AS (
 SELECT 'store' AS channel,
        s.entity_id,
        s.d_year,
        s.month_key,
        s.net_sales - COALESCE(r.net_loss,0) AS net_revenue,
        s.profit AS profit,
        s.sales_txn,
        COALESCE(r.returns_txn,0) AS returns_txn
 FROM store_agg s
 LEFT JOIN store_ret_agg r
   ON s.entity_id = r.entity_id AND s.d_year = r.d_year AND s.month_key = r.month_key

 UNION ALL

 SELECT 'catalog' AS channel,
        c.entity_id,
        c.d_year,
        c.month_key,
        c.net_sales - COALESCE(cr.net_loss,0) AS net_revenue,
        c.profit AS profit,
        c.sales_txn,
        COALESCE(cr.returns_txn,0) AS returns_txn
 FROM catalog_agg c
 LEFT JOIN catalog_ret_agg cr
   ON c.entity_id = cr.entity_id AND c.d_year = cr.d_year AND c.month_key = cr.month_key

 UNION ALL

 SELECT 'web' AS channel,
        CAST(w.entity_id AS varchar) AS entity_id,
        w.d_year,
        w.month_key,
        w.net_sales - COALESCE(wr.net_loss,0) AS net_revenue,
        w.profit AS profit,
        w.sales_txn,
        COALESCE(wr.returns_txn,0) AS returns_txn
 FROM web_agg w
 LEFT JOIN web_ret_agg wr
   ON w.entity_id = wr.entity_id AND w.d_year = wr.d_year AND w.month_key = wr.month_key
)
SELECT
    channel,
    entity_id,
    d_year,
    month_key,
    net_revenue,
    profit,
    sales_txn,
    returns_txn,
    net_revenue / NULLIF(sales_txn,0) AS avg_revenue_per_txn,
    profit / NULLIF(sales_txn,0) AS profit_per_txn,
    RANK() OVER (PARTITION BY channel, d_year ORDER BY net_revenue DESC) AS revenue_rank,
    PERCENT_RANK() OVER (PARTITION BY channel, d_year ORDER BY profit DESC) AS profit_percentile
FROM combined
WHERE net_revenue > 0
ORDER BY channel, d_year, month_key, revenue_rank
LIMIT 200
