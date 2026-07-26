SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_division,
    cc.cc_employees,
    d_closed.d_year AS closed_year,
    COALESCE(inv_tot.inv_quantity_on_hand, 0) AS total_inventory_qty,
    COALESCE(wp_tot.wp_count, 0) AS web_pages_created,
    CASE
        WHEN cc.cc_tax_percentage > 0.10 THEN 'HIGH TAX'
        WHEN cc.cc_tax_percentage > 0.05 THEN 'MEDIUM TAX'
        ELSE 'LOW TAX'
    END AS tax_category,
    RANK() OVER (PARTITION BY cc.cc_division ORDER BY cc.cc_employees DESC) AS emp_rank_in_division
FROM call_center cc
LEFT JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
LEFT JOIN (
    SELECT inv_date_sk, SUM(inv_quantity_on_hand) AS inv_quantity_on_hand
    FROM inventory
    GROUP BY inv_date_sk
) inv_tot
    ON inv_tot.inv_date_sk = cc.cc_closed_date_sk
LEFT JOIN (
    SELECT wp_creation_date_sk, COUNT(*) AS wp_count
    FROM web_page
    GROUP BY wp_creation_date_sk
) wp_tot
    ON wp_tot.wp_creation_date_sk = cc.cc_closed_date_sk
WHERE cc.cc_employees IS NOT NULL
