WITH daily_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        wp.wp_type,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
        CASE
            WHEN SUM(i.inv_quantity_on_hand) < 1000 THEN 'Low'
            WHEN SUM(i.inv_quantity_on_hand) BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS qty_category
    FROM date_dim d
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND d.d_current_quarter = 'Y'
      AND wp.wp_autogen_flag = 'N'
      AND wp.wp_type IN ('home', 'product')
      AND i.inv_item_sk IN (101410, 101438, 101444)
    GROUP BY d.d_year, d.d_quarter_name, wp.wp_type
)
SELECT
    d_year,
    d_quarter_name,
    AVG(total_qty) AS avg_total_qty,
    SUM(page_cnt) AS total_pages,
    qty_category
FROM daily_agg
WHERE qty_category <> 'Low'
GROUP BY d_year, d_quarter_name, qty_category
HAVING AVG(total_qty) > 2000
ORDER BY d_year DESC, d_quarter_name
