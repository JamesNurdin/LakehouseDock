/*
Goal: Identify recent catalog returns and enrich them with either inventory levels or promotion costs, categorizing the return quantity and combining both perspectives into a unified result set.
*/
WITH inventory_returns AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        i.i_item_id,
        c.c_customer_id,
        ca.ca_state,
        cr.cr_return_amount,
        CASE WHEN cr.cr_return_quantity > 1 THEN 'Multiple' ELSE 'Single' END AS return_type,
        CAST(SUM(inv.inv_quantity_on_hand) OVER (PARTITION BY i.i_item_sk) AS double) AS metric_value,
        'Inventory' AS metric_source
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_rec_end_date >= DATE '2000-01-01'
      AND ca.ca_state IN ('CA', 'TX')
),
promotion_returns AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        i.i_item_id,
        c.c_customer_id,
        ca.ca_state,
        cr.cr_return_amount,
        CASE WHEN cr.cr_return_quantity > 1 THEN 'Multiple' ELSE 'Single' END AS return_type,
        CAST(SUM(p.p_cost) OVER (PARTITION BY i.i_item_sk) AS double) AS metric_value,
        'Promotion' AS metric_source
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE i.i_rec_end_date < DATE '2000-01-01'
      AND ca.ca_state = 'NY'
)
SELECT
    return_date_sk,
    i_item_id,
    c_customer_id,
    ca_state,
    cr_return_amount,
    return_type,
    metric_value,
    metric_source
FROM (
    SELECT
        return_date_sk,
        i_item_id,
        c_customer_id,
        ca_state,
        cr_return_amount,
        return_type,
        metric_value,
        metric_source
    FROM inventory_returns
    UNION ALL
    SELECT
        return_date_sk,
        i_item_id,
        c_customer_id,
        ca_state,
        cr_return_amount,
        return_type,
        metric_value,
        metric_source
    FROM promotion_returns
) AS combined
ORDER BY metric_value DESC, return_date_sk
LIMIT 100
