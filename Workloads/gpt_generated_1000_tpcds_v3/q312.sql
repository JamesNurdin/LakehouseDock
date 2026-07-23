WITH
agg_a AS (
    SELECT
        i.i_manufact_id AS manufacturer_id,
        i.i_item_id      AS item_id,
        i.i_item_desc    AS item_desc,
        td.t_time_id     AS return_time_id,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss)         AS total_net_loss,
        MIN(td.t_time)              AS min_time
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_ship_cost > 100
      AND cr.cr_returning_addr_sk IN (4421968, 4733283)
      AND i.i_manufact_id IN (86, 364)
      AND i.i_class = 'sports-apparel'
      AND td.t_second <= 10
    GROUP BY
        i.i_manufact_id,
        i.i_item_id,
        i.i_item_desc,
        td.t_time_id
),
ranked_a AS (
    SELECT
        manufacturer_id,
        item_id,
        item_desc,
        return_time_id,
        total_return_qty,
        total_net_loss,
        RANK() OVER (PARTITION BY manufacturer_id ORDER BY total_net_loss DESC) AS manufacturer_rank,
        ROW_NUMBER() OVER (PARTITION BY manufacturer_id ORDER BY min_time ASC) AS row_num,
        CASE WHEN total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS net_loss_category,
        'A' AS source_flag
    FROM agg_a
),
agg_b AS (
    SELECT
        i.i_manufact_id AS manufacturer_id,
        i.i_item_id      AS item_id,
        i.i_item_desc    AS item_desc,
        td.t_time_id     AS return_time_id,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss)         AS total_net_loss,
        MIN(td.t_time)              AS min_time
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_amount > 500
      AND cr.cr_refunded_cdemo_sk > 500000
      AND td.t_hour BETWEEN 12 AND 23
      AND i.i_class = 'decor'
      AND cr.cr_return_ship_cost > 200
      AND i.i_manufact_id NOT IN (86, 364)
    GROUP BY
        i.i_manufact_id,
        i.i_item_id,
        i.i_item_desc,
        td.t_time_id
),
ranked_b AS (
    SELECT
        manufacturer_id,
        item_id,
        item_desc,
        return_time_id,
        total_return_qty,
        total_net_loss,
        RANK() OVER (PARTITION BY manufacturer_id ORDER BY total_net_loss DESC) AS manufacturer_rank,
        ROW_NUMBER() OVER (PARTITION BY manufacturer_id ORDER BY min_time ASC) AS row_num,
        CASE WHEN total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS net_loss_category,
        'B' AS source_flag
    FROM agg_b
)
SELECT
    manufacturer_id,
    item_id,
    item_desc,
    return_time_id,
    total_return_qty,
    total_net_loss,
    manufacturer_rank,
    row_num,
    net_loss_category,
    source_flag
FROM ranked_a
UNION ALL
SELECT
    manufacturer_id,
    item_id,
    item_desc,
    return_time_id,
    total_return_qty,
    total_net_loss,
    manufacturer_rank,
    row_num,
    net_loss_category,
    source_flag
FROM ranked_b
ORDER BY manufacturer_id, manufacturer_rank, total_net_loss DESC
LIMIT 100
