WITH agg AS (
    SELECT 
        d.d_fy_quarter_seq AS fy_quarter,
        d.d_year AS year,
        i.i_category AS category,
        i.i_brand AS brand,
        s.s_market_desc AS market,
        ws.web_mkt_desc AS site_market,
        ws.web_close_date_sk AS site_close_sk,
        d.d_date AS return_date,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        MAX(CASE WHEN wr.wr_refunded_cash > 0 THEN wr.wr_return_amt ELSE NULL END) AS max_refunded_return_amt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        d.d_fy_quarter_seq,
        d.d_year,
        i.i_category,
        i.i_brand,
        s.s_market_desc,
        ws.web_mkt_desc,
        ws.web_close_date_sk,
        d.d_date
    HAVING SUM(wr.wr_return_amt) > 0
)
SELECT 
    agg.fy_quarter,
    agg.year,
    agg.category,
    agg.brand,
    agg.market,
    agg.site_market,
    agg.return_date,
    agg.return_count,
    agg.total_return_amt,
    agg.total_return_qty,
    agg.total_return_amt_inc_tax,
    agg.total_net_loss,
    agg.avg_return_amt_inc_tax,
    agg.max_refunded_return_amt,
    CASE WHEN agg.site_close_sk IS NULL THEN 'Open' ELSE 'Closed' END AS site_status,
    RANK() OVER (PARTITION BY agg.category ORDER BY agg.total_return_amt DESC) AS category_return_rank
FROM agg
ORDER BY agg.total_return_amt DESC
LIMIT 100
