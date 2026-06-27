WITH store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_returns_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_returns_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_returns_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year, wr.d_year) AS year,
    COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq, ws.d_month_seq, wr.d_month_seq) AS month_seq,
    COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category, ws.i_category, wr.i_category) AS category,
    COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_net_profit,
    COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0) AS total_net_loss,
    COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
      - (COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) AS net_profit_after_returns,
    COALESCE(ss.store_sales_cnt, 0) AS store_sales_cnt,
    COALESCE(sr.store_returns_cnt, 0) AS store_returns_cnt,
    COALESCE(cs.catalog_sales_cnt, 0) AS catalog_sales_cnt,
    COALESCE(cr.catalog_returns_cnt, 0) AS catalog_returns_cnt,
    COALESCE(ws.web_sales_cnt, 0) AS web_sales_cnt,
    COALESCE(wr.web_returns_cnt, 0) AS web_returns_cnt
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr
    ON ss.d_year = sr.d_year
   AND ss.d_month_seq = sr.d_month_seq
   AND ss.i_category = sr.i_category
FULL OUTER JOIN catalog_sales_agg cs
    ON COALESCE(ss.d_year, sr.d_year) = cs.d_year
   AND COALESCE(ss.d_month_seq, sr.d_month_seq) = cs.d_month_seq
   AND COALESCE(ss.i_category, sr.i_category) = cs.i_category
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(ss.d_year, sr.d_year, cs.d_year) = cr.d_year
   AND COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq) = cr.d_month_seq
   AND COALESCE(ss.i_category, sr.i_category, cs.i_category) = cr.i_category
FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year) = ws.d_year
   AND COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq) = ws.d_month_seq
   AND COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category) = ws.i_category
FULL OUTER JOIN web_returns_agg wr
    ON COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year) = wr.d_year
   AND COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq, ws.d_month_seq) = wr.d_month_seq
   AND COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category, ws.i_category) = wr.i_category
ORDER BY year, month_seq, category
