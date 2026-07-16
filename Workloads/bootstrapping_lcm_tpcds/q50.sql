WITH weekly_item_stats AS (
    SELECT
        dd.d_fy_week_seq AS week_seq,
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        dd.d_quarter_name AS quarter_name,
        MIN(s.s_market_desc) AS market_desc,
        MIN(s.s_market_manager) AS market_manager,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
        AVG(wr.wr_net_loss) AS avg_net_loss
    FROM date_dim dd
    JOIN web_returns wr ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_date_sk = dd.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
    WHERE dd.d_fy_year = 2023
    GROUP BY
        dd.d_fy_week_seq,
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        dd.d_quarter_name
    HAVING SUM(wr.wr_return_amt) > 500
)
SELECT
    week_seq,
    i_item_id,
    i_brand,
    i_category,
    quarter_name,
    market_desc,
    market_manager,
    total_return_amount,
    total_return_qty,
    avg_inventory_qty,
    avg_net_loss,
    RANK() OVER (PARTITION BY week_seq ORDER BY total_return_amount DESC) AS return_rank,
    CASE
        WHEN total_return_amount > 10000 THEN 'High'
        WHEN total_return_amount > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_category
FROM weekly_item_stats
ORDER BY week_seq, return_rank
LIMIT 200
