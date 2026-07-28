WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        i.inv_quantity_on_hand,
        s.s_store_id,
        s.s_state,
        s.s_division_id,
        w.web_site_id,
        w.web_country,
        w.web_tax_percentage
    FROM tpcds.date_dim d
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.inv_quantity_on_hand > 500
      AND s.s_state = 'TX'
      AND s.s_division_id = 1
      AND w.web_country = 'United States'
      AND w.web_tax_percentage < 0.10
)
SELECT
    d_date,
    s_store_id,
    s_state,
    web_site_id,
    SUM(inv_quantity_on_hand) AS total_qty,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY SUM(inv_quantity_on_hand) DESC) AS qty_rank,
    CASE
        WHEN SUM(inv_quantity_on_hand) > 800 THEN 'HIGH'
        WHEN SUM(inv_quantity_on_hand) BETWEEN 600 AND 800 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS qty_category
FROM base
GROUP BY d_date, s_store_id, s_state, web_site_id
ORDER BY total_qty DESC
LIMIT 100
