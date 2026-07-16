SELECT
    cc.cc_division_name,
    cc.cc_division,
    AVG(cc.cc_tax_percentage) AS avg_tax_percentage,
    SUM(inv.total_qty) AS total_inventory_quantity,
    COUNT(DISTINCT ws.web_site_id) AS distinct_web_sites
FROM
    call_center cc
    JOIN web_site ws
        ON cc.cc_company = ws.web_company_id
    LEFT JOIN (
        SELECT
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM
            inventory
        GROUP BY
            inv_warehouse_sk
    ) inv
        ON ws.web_site_sk = inv.inv_warehouse_sk
WHERE
    cc.cc_rec_start_date >= DATE '2000-01-01'
    AND cc.cc_rec_end_date <= DATE '2001-12-31'
    AND cc.cc_tax_percentage > 0.01
GROUP BY
    cc.cc_division_name,
    cc.cc_division
HAVING
    SUM(inv.total_qty) > 1000
ORDER BY
    avg_tax_percentage DESC,
    total_inventory_quantity DESC
LIMIT 100
