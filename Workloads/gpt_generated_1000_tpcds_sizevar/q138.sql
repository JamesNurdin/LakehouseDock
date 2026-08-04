WITH
    date_sold AS (
        SELECT *
        FROM date_dim
    ),
    date_catalog AS (
        SELECT *
        FROM date_dim
    ),
    date_web AS (
        SELECT *
        FROM date_dim
    )
SELECT
    i.i_category,
    d_sold.d_year,
    SUM(ss.ss_net_paid)               AS store_sales_total,
    SUM(ws.ws_net_paid)               AS web_sales_total,
    SUM(cs.cs_net_paid)               AS catalog_sales_total,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_qty,
    CASE
        WHEN SUM(ss.ss_net_paid) > (SELECT MAX(cs2.cs_net_paid) FROM catalog_sales cs2)
            THEN 'Above Max'
        ELSE 'Below Max'
    END                                 AS sales_volume_flag,
    ROW_NUMBER() OVER (ORDER BY d_sold.d_year DESC) AS rn
FROM store_sales ss
LEFT JOIN date_sold d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
LEFT JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
FULL OUTER JOIN inventory inv
    ON inv.inv_item_sk = ss.ss_item_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
   AND cs.cs_item_sk = i.i_item_sk
LEFT JOIN date_catalog d_cat
    ON cs.cs_sold_date_sk = d_cat.d_date_sk
LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
   AND ws.ws_item_sk = i.i_item_sk
LEFT JOIN date_web d_web
    ON ws.ws_sold_date_sk = d_web.d_date_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
GROUP BY
    i.i_category,
    d_sold.d_year
ORDER BY
    d_sold.d_year DESC,
    i.i_category
LIMIT 100
