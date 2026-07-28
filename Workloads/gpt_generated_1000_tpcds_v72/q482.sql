WITH per_item_year AS (
    SELECT
        i.i_item_id,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
                  AND s.s_closed_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                          AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                           AND cr.cr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                       AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cp.cp_department = 'DEPARTMENT'
      AND sm.sm_type = 'AIR'
    GROUP BY i.i_item_id, d.d_year
)
SELECT
    year,
    AVG(store_net_paid) AS avg_store_net_paid,
    AVG(catalog_net_paid) AS avg_catalog_net_paid,
    AVG(web_net_paid) AS avg_web_net_paid,
    AVG(total_return_amount) AS avg_return_amount,
    AVG(total_on_hand) AS avg_on_hand,
    COUNT(*) AS item_count
FROM (
    SELECT
        i_item_id,
        d_year AS year,
        store_net_paid,
        catalog_net_paid,
        web_net_paid,
        total_return_amount,
        total_on_hand,
        profit_flag
    FROM per_item_year
) t
WHERE profit_flag = 'Profitable'
GROUP BY year
HAVING AVG(store_net_paid) > 1000
ORDER BY year DESC
LIMIT 100
