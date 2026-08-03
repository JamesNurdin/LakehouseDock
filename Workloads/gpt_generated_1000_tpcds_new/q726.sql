WITH
    sampled_returns AS (
        SELECT *
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    filtered_returns AS (
        SELECT
            cr_item_sk,
            cr_returned_time_sk,
            cr_return_quantity,
            cr_return_amount,
            cr_net_loss
        FROM sampled_returns
        WHERE cr_net_loss > 1000
          AND cr_return_quantity >= 1
          AND cr_return_amount > 50
    ),
    aggregated_returns AS (
        SELECT
            cr_item_sk,
            cr_returned_time_sk,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(cr_net_loss) AS total_net_loss,
            COUNT(*) AS cnt_returns,
            CASE WHEN SUM(cr_return_amount) > 500 THEN 'High' ELSE 'Low' END AS amount_category
        FROM filtered_returns
        GROUP BY cr_item_sk, cr_returned_time_sk
    ),
    item_subset_a AS (
        SELECT DISTINCT cr_item_sk
        FROM catalog_returns
        WHERE cr_return_quantity > 2
    ),
    item_subset_b AS (
        SELECT DISTINCT cr_item_sk
        FROM catalog_returns
        WHERE cr_return_amount BETWEEN 100 AND 200
    ),
    common_items AS (
        SELECT cr_item_sk FROM item_subset_a
        INTERSECT
        SELECT cr_item_sk FROM item_subset_b
    ),
    final_agg AS (
        SELECT
            ar.cr_item_sk,
            ar.total_return_amount,
            ar.total_net_loss,
            ar.cnt_returns,
            ar.amount_category,
            td.t_hour,
            td.t_am_pm,
            td.t_minute,
            (
                SELECT SUM(cr_return_amount)
                FROM catalog_returns cr2
                WHERE cr2.cr_item_sk = ar.cr_item_sk
            ) AS overall_item_return_amount
        FROM aggregated_returns ar
        JOIN time_dim td
          ON ar.cr_returned_time_sk = td.t_time_sk
        WHERE ar.cr_item_sk IN (SELECT cr_item_sk FROM common_items)
          AND td.t_am_pm = 'PM'
          AND td.t_minute BETWEEN 0 AND 30
    )
SELECT
    cr_item_sk,
    total_return_amount,
    total_net_loss,
    cnt_returns,
    amount_category,
    t_hour,
    t_am_pm,
    t_minute,
    overall_item_return_amount
FROM final_agg
ORDER BY total_net_loss DESC
LIMIT 100
