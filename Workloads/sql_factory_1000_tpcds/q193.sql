WITH brand_shift_agg AS (
    SELECT
        i.i_brand_id,
        i.i_brand,
        td.t_shift,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        AVG(wp.wp_char_count) AS avg_page_char_count
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY i.i_brand_id, i.i_brand, td.t_shift
)
SELECT
    i_brand,
    i_brand_id,
    t_shift,
    total_net_loss,
    total_return_qty,
    avg_return_amt,
    avg_page_char_count,
    CASE
        WHEN total_net_loss > 10000 THEN 'HIGH'
        WHEN total_net_loss > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category,
    RANK() OVER (PARTITION BY t_shift ORDER BY total_net_loss DESC) AS brand_rank_in_shift
FROM brand_shift_agg
ORDER BY t_shift, brand_rank_in_shift
