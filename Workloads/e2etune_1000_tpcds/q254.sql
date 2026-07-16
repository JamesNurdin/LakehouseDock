WITH web_returns_agg AS (
    SELECT
        wp.wp_web_page_id AS identifier,
        wp.wp_url AS url,
        wp.wp_type AS type,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_return_tax) AS avg_return_tax
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2450997
      AND wp.wp_type IN ('monthly', 'quarterly')
    GROUP BY wp.wp_web_page_id, wp.wp_url, wp.wp_type
),
web_returns_ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_return_amt DESC) AS rank
    FROM web_returns_agg
),
warehouse_inventory_agg AS (
    SELECT
        w.w_warehouse_id AS identifier,
        w.w_city AS city,
        w.w_state AS state,
        SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
        AVG(i.inv_quantity_on_hand) AS avg_qty_on_hand,
        w.w_warehouse_sq_ft AS warehouse_sq_ft
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_date_sk BETWEEN 2450815 AND 2450997
      AND w.w_country = 'United States'
    GROUP BY w.w_warehouse_id, w.w_city, w.w_state, w.w_warehouse_sq_ft
),
warehouse_inventory_ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_qty_on_hand DESC) AS rank,
        (total_qty_on_hand * 1.0) / warehouse_sq_ft AS qty_per_sqft
    FROM warehouse_inventory_agg
)
SELECT
    'WEB_RETURN' AS source,
    identifier,
    url,
    type,
    total_return_amt,
    total_return_qty,
    avg_return_tax,
    rank,
    CAST(NULL AS varchar) AS city,
    CAST(NULL AS varchar) AS state,
    CAST(NULL AS bigint) AS total_qty_on_hand,
    CAST(NULL AS double) AS qty_per_sqft
FROM web_returns_ranked
UNION ALL
SELECT
    'WAREHOUSE' AS source,
    identifier,
    CAST(NULL AS varchar) AS url,
    CAST(NULL AS varchar) AS type,
    CAST(NULL AS double) AS total_return_amt,
    CAST(NULL AS bigint) AS total_return_qty,
    CAST(NULL AS double) AS avg_return_tax,
    rank,
    city,
    state,
    total_qty_on_hand,
    qty_per_sqft
FROM warehouse_inventory_ranked
ORDER BY source, rank
