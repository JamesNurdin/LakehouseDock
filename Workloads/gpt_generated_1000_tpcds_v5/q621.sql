WITH base AS (
    SELECT
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        d.d_year,
        d.d_fy_quarter_seq,
        w.web_site_sk,
        w.web_name,
        w.web_manager,
        CASE
            WHEN i.inv_quantity_on_hand >= 700 THEN 'High'
            WHEN i.inv_quantity_on_hand >= 400 THEN 'Medium'
            ELSE 'Low'
        END AS qty_category
    FROM inventory i
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND d.d_fy_quarter_seq IN (2, 6, 7, 11, 20)
      AND w.web_state = 'CA'
      AND w.web_manager IN ('Richard Fuchs', 'Herbert Hawes', 'Lewis Wolf')
      AND w.web_street_type IN ('Drive', 'Circle', 'Blvd')
      AND i.inv_quantity_on_hand > 0
),
site_summary AS (
    SELECT
        b.web_name,
        b.web_manager,
        b.d_year,
        b.d_fy_quarter_seq,
        SUM(b.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT b.inv_item_sk) AS distinct_items,
        AVG(CASE WHEN b.qty_category = 'High' THEN b.inv_quantity_on_hand END) AS avg_high_qty
    FROM base b
    GROUP BY
        b.web_name,
        b.web_manager,
        b.d_year,
        b.d_fy_quarter_seq
    HAVING SUM(b.inv_quantity_on_hand) > 1000
       AND COUNT(DISTINCT b.inv_item_sk) >= 5
       AND AVG(b.inv_quantity_on_hand) > 300
)
SELECT
    ss.web_manager,
    AVG(ss.total_quantity) AS avg_total_quantity_per_manager,
    COUNT(DISTINCT ss.web_name) AS distinct_sites
FROM site_summary ss
GROUP BY ss.web_manager
HAVING AVG(ss.total_quantity) > 1500
ORDER BY avg_total_quantity_per_manager DESC
LIMIT 100
