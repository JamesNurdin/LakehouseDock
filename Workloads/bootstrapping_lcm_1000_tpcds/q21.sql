WITH returns_agg AS (
    SELECT
        s.s_store_id AS s_store_id,
        ws.web_name AS web_name,
        d_ret.d_year AS d_year,
        d_ret.d_quarter_name AS d_quarter_name,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_fee) AS total_fee,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_page_cnt,
        SUM(CASE WHEN d_ret.d_weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_returns,
        SUM(wr.wr_return_tax) AS total_return_tax,
        AVG(date_diff('day', d_create.d_date, d_ret.d_date)) AS avg_days_page_creation_to_return,
        AVG(date_diff('day', d_access.d_date, d_ret.d_date)) AS avg_days_page_access_to_return,
        AVG(date_diff('day', d_site_close.d_date, d_ret.d_date)) AS avg_days_site_close_to_return
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_create ON wp.wp_creation_date_sk = d_create.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_site_close ON ws.web_close_date_sk = d_site_close.d_date_sk
    GROUP BY s.s_store_id, ws.web_name, d_ret.d_year, d_ret.d_quarter_name
)
SELECT
    s_store_id,
    web_name,
    d_year,
    d_quarter_name,
    total_returns,
    total_return_amt,
    total_return_amt_inc_tax,
    total_net_loss,
    total_fee,
    avg_return_qty,
    distinct_page_cnt,
    weekend_returns,
    total_return_tax,
    avg_days_page_creation_to_return,
    avg_days_page_access_to_return,
    avg_days_site_close_to_return,
    RANK() OVER (PARTITION BY d_year, d_quarter_name ORDER BY total_return_amt DESC) AS return_amount_rank
FROM returns_agg
WHERE total_returns > 10
ORDER BY d_year DESC, d_quarter_name, return_amount_rank
LIMIT 100
