WITH agg_returns AS (
    SELECT
        w.w_warehouse_name,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE i.i_category_id IN (1, 2, 5)
      AND i.i_container = 'Unknown'
      AND r.r_reason_desc LIKE '%color%'
      AND w.w_county = 'Fairfield County'
    GROUP BY
        w.w_warehouse_name,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price
)
SELECT
    w_warehouse_name,
    i_item_id,
    i_product_name,
    total_net_loss,
    total_return_amount,
    return_cnt,
    CASE
        WHEN total_return_amount > i_current_price * return_cnt THEN 'Above Avg Price'
        ELSE 'Below Avg Price'
    END AS return_price_flag,
    RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_net_loss DESC) AS warehouse_rank,
    SUM(total_return_amount) OVER (
        PARTITION BY w_warehouse_name
        ORDER BY total_net_loss
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_item_return_sum
FROM agg_returns
ORDER BY w_warehouse_name, warehouse_rank
LIMIT 20
