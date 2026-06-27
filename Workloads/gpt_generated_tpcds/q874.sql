WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    COALESCE(s.d_year, sr.d_year, cr.d_year, wr.d_year) AS sale_year,
    COALESCE(s.d_month_seq, sr.d_month_seq, cr.d_month_seq, wr.d_month_seq) AS sale_month_seq,
    COALESCE(s.i_category, sr.i_category, cr.i_category, wr.i_category) AS category,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(sr.total_store_return_loss, 0) AS total_store_return_loss,
    COALESCE(sr.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(cr.total_catalog_return_loss, 0) AS total_catalog_return_loss,
    COALESCE(cr.catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(wr.total_web_return_loss, 0) AS total_web_return_loss,
    COALESCE(wr.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(s.total_net_profit, 0) - COALESCE(sr.total_store_return_loss, 0) - COALESCE(cr.total_catalog_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
FULL OUTER JOIN store_returns_agg sr
    ON s.d_year = sr.d_year
   AND s.d_month_seq = sr.d_month_seq
   AND s.i_category = sr.i_category
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(s.d_year, sr.d_year) = cr.d_year
   AND COALESCE(s.d_month_seq, sr.d_month_seq) = cr.d_month_seq
   AND COALESCE(s.i_category, sr.i_category) = cr.i_category
FULL OUTER JOIN web_returns_agg wr
    ON COALESCE(s.d_year, sr.d_year, cr.d_year) = wr.d_year
   AND COALESCE(s.d_month_seq, sr.d_month_seq, cr.d_month_seq) = wr.d_month_seq
   AND COALESCE(s.i_category, sr.i_category, cr.i_category) = wr.i_category
WHERE COALESCE(s.total_quantity, 0) > 0
ORDER BY sale_year, sale_month_seq, category
