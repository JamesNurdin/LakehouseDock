WITH daily_qty AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        d.d_year,
        inv.inv_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
),
avg_qty AS (
    SELECT
        i_item_sk,
        i_brand,
        i_category,
        d_year,
        AVG(inv_quantity_on_hand) AS avg_qty
    FROM daily_qty
    GROUP BY i_item_sk, i_brand, i_category, d_year
),
sites_by_year AS (
    SELECT
        od.d_year,
        COUNT(DISTINCT ws.web_site_sk) AS num_sites
    FROM web_site ws
    JOIN date_dim od
        ON ws.web_open_date_sk = od.d_date_sk
    WHERE od.d_year = 2022
    GROUP BY od.d_year
)
SELECT
    a.i_item_sk,
    a.i_brand,
    a.i_category,
    a.d_year,
    a.avg_qty,
    CASE
        WHEN a.avg_qty >= 1000 THEN 'High'
        WHEN a.avg_qty >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS qty_category,
    DENSE_RANK() OVER (PARTITION BY a.i_brand ORDER BY a.avg_qty DESC) AS brand_rank,
    COALESCE(s.num_sites, 0) AS sites_opened_in_year
FROM avg_qty a
LEFT JOIN sites_by_year s
    ON a.d_year = s.d_year
ORDER BY a.i_brand, brand_rank
