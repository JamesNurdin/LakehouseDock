WITH inventory_agg AS (
        SELECT inv_date_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_date_sk
    ),
    catalog_page_agg AS (
        SELECT cp_start_date_sk,
               cp_department,
               COUNT(*) AS page_cnt
        FROM catalog_page
        WHERE cp_department = 'Electronics'
        GROUP BY cp_start_date_sk,
                 cp_department
    ),
    full_inventory_catalog AS (
        SELECT ia.inv_date_sk,
               ia.total_qty,
               cpa.cp_start_date_sk,
               cpa.cp_department,
               cpa.page_cnt
        FROM inventory_agg ia
        FULL OUTER JOIN catalog_page_agg cpa
            ON ia.inv_date_sk = cpa.cp_start_date_sk
    )
SELECT
    d.d_year,
    d.d_month_seq,
    COALESCE(fic.inv_date_sk, fic.cp_start_date_sk) AS date_key,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(fic.total_qty) AS inventory_qty,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    AVG(CASE WHEN ss.ss_net_paid IS NOT NULL THEN ss.ss_net_paid END) AS avg_store_net_paid,
    MIN(CASE WHEN ws.ws_net_paid IS NOT NULL THEN ws.ws_net_paid END) AS min_web_net_paid,
    MAX(CASE WHEN ss.ss_net_profit IS NOT NULL THEN ss.ss_net_profit END) AS max_store_profit,
    store.s_store_name,
    web_site.web_name,
    ship_mode.sm_type
FROM full_inventory_catalog fic
LEFT JOIN date_dim d
    ON (fic.inv_date_sk = d.d_date_sk OR fic.cp_start_date_sk = d.d_date_sk)
LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN customer c_ss
    ON ss.ss_customer_sk = c_ss.c_customer_sk
LEFT JOIN store
    ON ss.ss_store_sk = store.s_store_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN customer c_ws
    ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
LEFT JOIN web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
LEFT JOIN ship_mode
    ON ws.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
WHERE
    d.d_year = 2001
    AND store.s_state = 'FL'
    AND ship_mode.sm_contract = 'I3uCelXtjP'
    AND web_site.web_country = 'USA'
    AND c_ss.c_birth_country = 'USA'
    AND store.s_tax_percentage > (
        SELECT AVG(s_tax_percentage)
        FROM store
        WHERE s_state = 'FL'
    )
    AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = ws.ws_item_sk
          AND inv.inv_quantity_on_hand > 0
    )
GROUP BY
    d.d_year,
    d.d_month_seq,
    COALESCE(fic.inv_date_sk, fic.cp_start_date_sk),
    store.s_store_name,
    web_site.web_name,
    ship_mode.sm_type
ORDER BY
    d.d_year,
    d.d_month_seq,
    store.s_store_name
LIMIT 100
