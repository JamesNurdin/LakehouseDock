WITH aggregated_returns AS (
    SELECT 
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
)
SELECT 
    d.d_year,
    d.d_quarter_name,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    i.i_product_name,
    ar.total_return_amt,
    ar.total_net_loss,
    ar.avg_return_qty,
    ar.return_cnt,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.web_name AS site_name,
    ws.web_city AS site_city,
    ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_quarter_seq ORDER BY ar.total_net_loss DESC) AS loss_rank_in_quarter,
    SUM(ar.total_return_amt) OVER (PARTITION BY i.i_category) AS total_return_by_category
FROM aggregated_returns ar
JOIN date_dim d ON ar.wr_returned_date_sk = d.d_date_sk
JOIN item i ON ar.wr_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk AND ws.web_close_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND i.i_category IS NOT NULL
ORDER BY d.d_year, loss_rank_in_quarter
LIMIT 100
