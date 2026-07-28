WITH filtered AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_holiday,
        w.web_company_name,
        w.web_state,
        w.web_zip
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1210
      AND d.d_week_seq IN (8, 19, 20)
      AND d.d_holiday = 'N'
      AND w.web_state = 'CA'
      AND w.web_zip = '84098'
      AND i.inv_warehouse_sk IN (1, 4, 15)
      AND i.inv_quantity_on_hand > 100
)
SELECT
    web_company_name,
    d_year,
    SUM(inv_quantity_on_hand) AS total_qty,
    AVG(inv_quantity_on_hand) AS avg_qty,
    COUNT(DISTINCT inv_item_sk) AS distinct_items,
    MIN(inv_quantity_on_hand) AS min_qty,
    MAX(inv_quantity_on_hand) AS max_qty
FROM filtered
GROUP BY web_company_name, d_year
ORDER BY total_qty DESC
LIMIT 100
