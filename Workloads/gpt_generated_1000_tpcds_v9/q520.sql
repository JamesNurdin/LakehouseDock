WITH store_profit AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'Store Net Profit' AS metric_type,
        SUM(ss.ss_net_profit) AS metric_amount
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_color = 'pink'
      AND i.i_size = 'medium'
      AND i.i_rec_start_date >= DATE '2001-01-01'
    GROUP BY i.i_item_id, i.i_product_name
),
web_loss AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'Web Net Loss' AS metric_type,
        SUM(wr.wr_net_loss) AS metric_amount
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id LIKE 'AAAAAAA%'
      AND i.i_wholesale_cost > 5.0
      AND i.i_rec_end_date <= DATE '2003-12-31'
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT
    i_item_id,
    i_product_name,
    metric_type,
    metric_amount
FROM store_profit
UNION
SELECT
    i_item_id,
    i_product_name,
    metric_type,
    metric_amount
FROM web_loss
LIMIT 100
