WITH
    store_sales_agg AS (
        SELECT
            i.i_item_sk,
            i.i_category,
            d.d_year,
            d.d_month_seq,
            SUM(ss.ss_net_paid) AS store_sales_net_paid
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY i.i_item_sk, i.i_category, d.d_year, d.d_month_seq
    ),
    store_returns_agg AS (
        SELECT
            i.i_item_sk,
            i.i_category,
            d.d_year,
            d.d_month_seq,
            SUM(sr.sr_net_loss) AS store_returns_net_loss
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        GROUP BY i.i_item_sk, i.i_category, d.d_year, d.d_month_seq
    ),
    catalog_sales_agg AS (
        SELECT
            i.i_item_sk,
            i.i_category,
            d.d_year,
            d.d_month_seq,
            SUM(cs.cs_net_paid) AS catalog_sales_net_paid
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        GROUP BY i.i_item_sk, i.i_category, d.d_year, d.d_month_seq
    ),
    catalog_returns_agg AS (
        SELECT
            i.i_item_sk,
            i.i_category,
            d.d_year,
            d.d_month_seq,
            SUM(cr.cr_net_loss) AS catalog_returns_net_loss
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        GROUP BY i.i_item_sk, i.i_category, d.d_year, d.d_month_seq
    ),
    web_sales_agg AS (
        SELECT
            i.i_item_sk,
            i.i_category,
            d.d_year,
            d.d_month_seq,
            SUM(ws.ws_net_paid) AS web_sales_net_paid
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY i.i_item_sk, i.i_category, d.d_year, d.d_month_seq
    ),
    web_returns_agg AS (
        SELECT
            i.i_item_sk,
            i.i_category,
            d.d_year,
            d.d_month_seq,
            SUM(wr.wr_net_loss) AS web_returns_net_loss
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        GROUP BY i.i_item_sk, i.i_category, d.d_year, d.d_month_seq
    )
SELECT
    COALESCE(ss.i_item_sk, sr.i_item_sk, cs.i_item_sk, cr.i_item_sk, ws.i_item_sk, wr.i_item_sk) AS item_sk,
    COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category, ws.i_category, wr.i_category) AS category,
    COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year, wr.d_year) AS year,
    COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq, ws.d_month_seq, wr.d_month_seq) AS month_seq,
    (COALESCE(ss.store_sales_net_paid, 0) - COALESCE(sr.store_returns_net_loss, 0))
    + (COALESCE(cs.catalog_sales_net_paid, 0) - COALESCE(cr.catalog_returns_net_loss, 0))
    + (COALESCE(ws.web_sales_net_paid, 0) - COALESCE(wr.web_returns_net_loss, 0)) AS net_revenue
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr
    ON ss.i_item_sk = sr.i_item_sk
   AND ss.d_year = sr.d_year
   AND ss.d_month_seq = sr.d_month_seq
FULL OUTER JOIN catalog_sales_agg cs
    ON COALESCE(ss.i_item_sk, sr.i_item_sk) = cs.i_item_sk
   AND COALESCE(ss.d_year, sr.d_year) = cs.d_year
   AND COALESCE(ss.d_month_seq, sr.d_month_seq) = cs.d_month_seq
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(ss.i_item_sk, sr.i_item_sk, cs.i_item_sk) = cr.i_item_sk
   AND COALESCE(ss.d_year, sr.d_year, cs.d_year) = cr.d_year
   AND COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq) = cr.d_month_seq
FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(ss.i_item_sk, sr.i_item_sk, cs.i_item_sk, cr.i_item_sk) = ws.i_item_sk
   AND COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year) = ws.d_year
   AND COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq) = ws.d_month_seq
FULL OUTER JOIN web_returns_agg wr
    ON COALESCE(ss.i_item_sk, sr.i_item_sk, cs.i_item_sk, cr.i_item_sk, ws.i_item_sk) = wr.i_item_sk
   AND COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year) = wr.d_year
   AND COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq, ws.d_month_seq) = wr.d_month_seq
WHERE (COALESCE(ss.store_sales_net_paid, 0) - COALESCE(sr.store_returns_net_loss, 0)
       + COALESCE(cs.catalog_sales_net_paid, 0) - COALESCE(cr.catalog_returns_net_loss, 0)
       + COALESCE(ws.web_sales_net_paid, 0) - COALESCE(wr.web_returns_net_loss, 0)) > 0
ORDER BY net_revenue DESC
LIMIT 50
