WITH cr_item AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_net_loss,
        ARRAY[cr.cr_return_amount, cr.cr_return_tax, cr.cr_return_ship_cost] AS return_metrics
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450986 AND 2451678
      AND cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 10
      AND cr.cr_return_tax >= 0
      AND cr.cr_return_ship_cost <= 100
      AND cr.cr_net_loss IS NOT NULL
),
unnested_returns AS (
    SELECT
        cr_item.*, 
        metric_value,
        ROW_NUMBER() OVER (PARTITION BY cr_item.cr_item_sk ORDER BY metric_value DESC) AS metric_rank
    FROM cr_item
    CROSS JOIN UNNEST(cr_item.return_metrics) AS t(metric_value)
),
joined_data AS (
    SELECT
        ur.cr_returned_date_sk,
        ur.cr_returned_time_sk,
        ur.cr_item_sk,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        sm.sm_carrier,
        sm.sm_code,
        inv.inv_quantity_on_hand,
        ur.return_metrics,
        ur.metric_value,
        ur.metric_rank,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_quantity
    FROM unnested_returns ur
    JOIN item i ON ur.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ur.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv ON ur.cr_item_sk = inv.inv_item_sk
    LEFT JOIN web_returns wr ON ur.cr_item_sk = wr.wr_item_sk
    WHERE i.i_current_price > 20
      AND i.i_brand IN ('Brand#1', 'Brand#2')
      AND sm.sm_carrier = 'MSC'
      AND inv.inv_quantity_on_hand BETWEEN 0 AND 500
      AND sm.sm_code = 'SEA'
      AND (wr.wr_return_amt_inc_tax IS NULL OR wr.wr_return_amt_inc_tax > 50)
)
SELECT
    cr_returned_date_sk,
    cr_returned_time_sk,
    cr_item_sk,
    i_item_sk,
    i_product_name,
    i_brand,
    i_category,
    sm_carrier,
    sm_code,
    inv_quantity_on_hand,
    metric_value,
    metric_rank,
    wr_return_amt_inc_tax,
    wr_return_quantity,
    RANK() OVER (PARTITION BY i_brand ORDER BY metric_value DESC) AS brand_metric_rank
FROM joined_data
ORDER BY cr_returned_date_sk DESC, metric_value DESC
LIMIT 100
