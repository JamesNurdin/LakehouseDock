WITH daily_agg AS (
    SELECT d.d_date,
           SUM(inv.inv_quantity_on_hand) AS total_inventory,
           COUNT(DISTINCT cc.cc_call_center_sk) AS call_center_cnt,
           AVG(cc.cc_tax_percentage) AS avg_tax_pct,
           COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_cnt,
           SUM(wp.wp_char_count) AS total_char_count
    FROM date_dim d
    LEFT JOIN inventory inv
           ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
           ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
           ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_date
)
SELECT d_date,
       total_inventory,
       call_center_cnt,
       avg_tax_pct,
       web_page_cnt,
       total_char_count,
       DENSE_RANK() OVER (ORDER BY total_inventory DESC) AS inventory_day_rank,
       SUM(total_inventory) OVER (ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_inventory,
       CASE WHEN call_center_cnt > 5 AND web_page_cnt > 10 THEN 'busy_day' ELSE 'regular_day' END AS day_activity_flag
FROM daily_agg
ORDER BY d_date DESC
LIMIT 20
