WITH ranked_items AS (
    SELECT
        i.i_brand,
        i.i_item_id,
        d_ret.d_day_name AS day_name,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(i.i_current_price) AS avg_price,
        PERCENT_RANK() OVER (PARTITION BY i.i_brand ORDER BY SUM(wr.wr_return_quantity) DESC) AS pct_rank,
        CASE WHEN SUM(wr.wr_return_quantity) > 500 THEN 'High Return' ELSE 'Normal Return' END AS return_flag,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(wr.wr_return_quantity) DESC) AS brand_item_rank
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN web_site ws
        ON d_ret.d_date_sk >= ws.web_open_date_sk
       AND (ws.web_close_date_sk IS NULL OR d_ret.d_date_sk <= ws.web_close_date_sk)
    WHERE d_ret.d_year = 2003
    GROUP BY i.i_brand, i.i_item_id, d_ret.d_day_name
)
SELECT
    ri.i_brand,
    ri.i_item_id,
    ri.day_name,
    ri.total_return_qty,
    ri.avg_price,
    ri.pct_rank,
    ri.return_flag,
    ri.brand_item_rank
FROM ranked_items ri
WHERE ri.brand_item_rank <= 10
ORDER BY ri.i_brand, ri.brand_item_rank
