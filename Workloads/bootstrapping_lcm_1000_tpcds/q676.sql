WITH wp_created AS (
    SELECT wp_creation_date_sk AS d_date_sk,
           COUNT(DISTINCT wp_web_page_id) AS pages_created
    FROM web_page
    GROUP BY wp_creation_date_sk
),
wp_accessed AS (
    SELECT wp_access_date_sk AS d_date_sk,
           COUNT(DISTINCT wp_web_page_id) AS pages_accessed
    FROM web_page
    GROUP BY wp_access_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    s.s_store_id,
    s.s_market_desc,
    d_closed.d_current_day AS store_closed_day,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_inventory_items,
    COALESCE(wc.pages_created, 0) AS pages_created,
    COALESCE(wa.pages_accessed, 0) AS pages_accessed,
    CASE
        WHEN COALESCE(wa.pages_accessed, 0) = 0 THEN NULL
        ELSE COALESCE(wc.pages_created, 0) * 1.0 / COALESCE(wa.pages_accessed, 0)
    END AS created_to_accessed_ratio
FROM date_dim d
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
LEFT JOIN wp_created wc ON wc.d_date_sk = d.d_date_sk
LEFT JOIN wp_accessed wa ON wa.d_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY
    d.d_date,
    d.d_year,
    s.s_store_id,
    s.s_market_desc,
    d_closed.d_current_day,
    wc.pages_created,
    wa.pages_accessed
ORDER BY d.d_date DESC
LIMIT 100
