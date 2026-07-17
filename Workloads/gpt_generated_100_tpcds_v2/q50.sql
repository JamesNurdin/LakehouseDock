WITH item_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_wholesale_cost,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        AVG(sr.sr_refunded_cash) AS avg_refunded_cash,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
    GROUP BY i.i_item_id, i.i_item_desc, i.i_brand, i.i_wholesale_cost
)
SELECT
    iag.i_item_id,
    iag.i_item_desc,
    iag.i_brand,
    iag.i_wholesale_cost,
    CASE
        WHEN iag.i_wholesale_cost > 5 THEN 'Expensive'
        WHEN iag.i_wholesale_cost > 2 THEN 'Medium'
        ELSE 'Cheap'
    END AS cost_category,
    iag.total_return_amt_inc_tax,
    iag.avg_refunded_cash,
    iag.total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY iag.i_brand ORDER BY iag.total_return_amt_inc_tax DESC) AS brand_item_rank,
    RANK() OVER (ORDER BY iag.total_return_amt_inc_tax DESC) AS overall_return_rank,
    SUM(iag.total_return_amt_inc_tax) OVER (
        PARTITION BY iag.i_brand
        ORDER BY iag.total_return_amt_inc_tax DESC
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_3item_return_sum
FROM item_agg iag
WHERE iag.total_return_amt_inc_tax > 0
ORDER BY overall_return_rank
LIMIT 100
