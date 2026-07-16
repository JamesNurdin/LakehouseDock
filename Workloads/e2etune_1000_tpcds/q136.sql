WITH inv_agg AS (
    SELECT
        i.inv_warehouse_sk,
        DATE_TRUNC('month', date_parse(cast(i.inv_date_sk AS varchar), '%Y%m%d')) AS month,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM inventory i
    WHERE date_parse(cast(i.inv_date_sk AS varchar), '%Y%m%d') >= DATE '2022-01-01'
    GROUP BY i.inv_warehouse_sk, DATE_TRUNC('month', date_parse(cast(i.inv_date_sk AS varchar), '%Y%m%d'))
    HAVING SUM(i.inv_quantity_on_hand) > 5000
)
SELECT
    w.w_state,
    w.w_city,
    a.month,
    a.total_quantity,
    a.distinct_items,
    AVG(w.w_warehouse_sq_ft) OVER (PARTITION BY w.w_state) AS avg_warehouse_sq_ft_state,
    RANK() OVER (PARTITION BY w.w_state ORDER BY a.total_quantity DESC) AS warehouse_state_rank,
    (SELECT SUM(cc.cc_employees) FROM call_center cc WHERE cc.cc_city = w.w_city) AS total_cc_employees_in_city,
    (SELECT AVG(ws.web_tax_percentage) FROM web_site ws WHERE ws.web_state = w.w_state) AS avg_web_tax_pct_state
FROM inv_agg a
JOIN warehouse w ON a.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_country = 'United States'
ORDER BY w.w_state, a.total_quantity DESC
LIMIT 100
