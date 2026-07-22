WITH catalog_return_agg AS (
    SELECT
        d.d_date AS return_date,
        'catalog' AS channel,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(cr.cr_return_quantity) AS return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE t.t_meal_time = 'dinner'
      AND i.i_brand = 'BrandX'
      AND (p.p_channel_email = 'Y' OR p.p_channel_email IS NULL)
    GROUP BY d.d_date
),
web_return_agg AS (
    SELECT
        d.d_date AS return_date,
        'web' AS channel,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(wr.wr_return_quantity) AS return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE t.t_meal_time = 'lunch'
      AND i.i_category = 'Sports'
      AND p.p_channel_email = 'N'
    GROUP BY d.d_date
),
combined AS (
    SELECT * FROM catalog_return_agg
    UNION ALL
    SELECT * FROM web_return_agg
),
filtered AS (
    SELECT * FROM combined
    WHERE net_loss > (SELECT AVG(net_loss) FROM combined)
),
agg AS (
    SELECT
        return_date,
        channel,
        SUM(net_loss) AS total_net_loss,
        SUM(return_qty) AS total_return_qty
    FROM filtered
    GROUP BY return_date, channel
    HAVING SUM(return_qty) > 10
)
SELECT
    return_date,
    channel,
    total_net_loss,
    total_return_qty,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_net_loss DESC) AS loss_rank,
    SUM(total_net_loss) OVER (PARTITION BY channel ORDER BY return_date ROWS UNBOUNDED PRECEDING) AS cumulative_loss
FROM agg
ORDER BY return_date DESC, channel
LIMIT 100
