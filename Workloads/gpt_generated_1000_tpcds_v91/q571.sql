/*
Goal: Combine store and catalog return transactions for the year 2002, enrich each return with web‑page character/link/image metrics, filter to dates where inventory on hand exceeded 1,000 units, assign row numbers (global for store and partitioned by year for catalog), expand the metrics array with UNNEST, and return the first 100 rows.
*/
WITH inventory_by_date AS (
    SELECT
        i.inv_date_sk,
        d.d_date,
        SUM(i.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY i.inv_date_sk, d.d_date
),
web_page_metrics AS (
    SELECT
        wp.wp_web_page_sk,
        d.d_date AS creation_date,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_image_count,
        ARRAY[wp.wp_char_count, wp.wp_link_count, wp.wp_image_count] AS metric_vals
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
)
SELECT
    src_type,
    return_date,
    return_time,
    item_sk,
    return_amount,
    net_loss,
    metric_idx,
    metric_val,
    rn
FROM (
    SELECT
        'store' AS src_type,
        d.d_date AS return_date,
        t.t_time AS return_time,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        m.metric_idx,
        m.metric_val,
        ROW_NUMBER() OVER (ORDER BY d.d_date ASC) AS rn
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN web_page_metrics wp ON wp.creation_date = d.d_date
    LEFT JOIN UNNEST(wp.metric_vals) WITH ORDINALITY AS m(metric_val, metric_idx) ON TRUE
    WHERE d.d_year = 2002
      AND EXISTS (
          SELECT 1
          FROM inventory_by_date ibd
          WHERE ibd.inv_date_sk = sr.sr_returned_date_sk
            AND ibd.total_qty_on_hand > 1000
      )
    UNION ALL
    SELECT
        'catalog' AS src_type,
        d.d_date AS return_date,
        t.t_time AS return_time,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        m.metric_idx,
        m.metric_val,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_date DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_page_metrics wp ON wp.creation_date = d.d_date
    LEFT JOIN UNNEST(wp.metric_vals) WITH ORDINALITY AS m(metric_val, metric_idx) ON TRUE
    WHERE d.d_year = 2002
      AND cr.cr_return_amount > 1000
) AS combined
LIMIT 100
