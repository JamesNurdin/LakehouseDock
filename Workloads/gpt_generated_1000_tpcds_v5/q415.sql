WITH cc_inventory_web AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        d_open.d_year AS open_year,
        d_closed.d_year AS closed_year,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt,
        AVG(wp.wp_link_count) AS avg_link_cnt
    FROM call_center cc
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d_closed.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_open.d_date_sk
    WHERE
        cc.cc_state = 'CA'
        AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
        AND d_open.d_qoy = 2
        AND d_closed.d_qoy = 3
        AND wp.wp_link_count > 5
        AND wp.wp_type = 'HOME'
        AND cc.cc_employees >= 50
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        d_open.d_year,
        d_closed.d_year
)
SELECT
    cc_call_center_id,
    cc_name,
    open_year,
    closed_year,
    total_qty,
    web_page_cnt,
    avg_link_cnt,
    CASE
        WHEN total_qty > (SELECT AVG(total_qty) FROM cc_inventory_web) THEN 'HIGH'
        ELSE 'LOW'
    END AS qty_category
FROM cc_inventory_web
WHERE web_page_cnt >= (
    SELECT MIN(web_page_cnt)
    FROM cc_inventory_web
    WHERE avg_link_cnt > 10
)
ORDER BY total_qty DESC, cc_call_center_id
LIMIT 100
