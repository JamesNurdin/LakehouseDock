WITH combined AS (
    SELECT
        s.s_city AS city,
        s.s_division_name AS division_name,
        'Return' AS metric_type,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS transaction_count,
        CASE
            WHEN regexp_like(s.s_city, 'Grove$') THEN 'GroveCity'
            WHEN s.s_city LIKE '%Valley%' THEN 'ValleyCity'
            ELSE 'OtherCity'
        END AS city_category,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS store_warehouse_label
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY
        s.s_city,
        s.s_division_name,
        CASE
            WHEN regexp_like(s.s_city, 'Grove$') THEN 'GroveCity'
            WHEN s.s_city LIKE '%Valley%' THEN 'ValleyCity'
            ELSE 'OtherCity'
        END,
        CONCAT(s.s_store_name, ' - ', s.s_city)

    UNION

    SELECT
        w.w_city AS city,
        CAST(NULL AS varchar) AS division_name,
        'Inventory' AS metric_type,
        SUM(i.inv_quantity_on_hand) AS total_amount,
        COUNT(DISTINCT i.inv_item_sk) AS transaction_count,
        CASE
            WHEN regexp_like(w.w_city, 'Grove$') THEN 'GroveCity'
            WHEN w.w_city LIKE '%Valley%' THEN 'ValleyCity'
            ELSE 'OtherCity'
        END AS city_category,
        CONCAT('Warehouse - ', w.w_warehouse_name) AS store_warehouse_label
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY
        w.w_city,
        CASE
            WHEN regexp_like(w.w_city, 'Grove$') THEN 'GroveCity'
            WHEN w.w_city LIKE '%Valley%' THEN 'ValleyCity'
            ELSE 'OtherCity'
        END,
        CONCAT('Warehouse - ', w.w_warehouse_name)
)
SELECT DISTINCT
    city,
    division_name,
    metric_type,
    total_amount,
    transaction_count,
    city_category,
    CASE
        WHEN total_amount > 5000 THEN 'High'
        ELSE 'Low'
    END AS amount_category,
    store_warehouse_label
FROM combined
ORDER BY city ASC, metric_type ASC
LIMIT 100
