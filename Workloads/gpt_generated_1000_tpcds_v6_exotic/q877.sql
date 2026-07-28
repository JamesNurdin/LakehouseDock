WITH inventory_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
sales_union AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_sold_time_sk AS sold_time_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_addr_sk AS addr_sk,
        ss.ss_cdemo_sk AS cdemo_sk,
        ss.ss_hdemo_sk AS hdemo_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_net_paid AS net_paid,
        CAST(NULL AS integer) AS ship_mode_sk,
        CAST(NULL AS integer) AS warehouse_sk,
        CAST(NULL AS integer) AS web_site_sk,
        'store' AS channel
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        'web' AS channel
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
)
SELECT
    i.i_category,
    td.t_shift,
    sm.sm_code,
    ws.web_name,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(su.ext_sales_price) AS total_sales,
    AVG(su.net_paid) AS avg_net_paid,
    MIN(su.ext_sales_price) AS min_sales,
    MAX(su.ext_sales_price) AS max_sales,
    SUM(COALESCE(ia.total_qty, 0)) AS total_inventory,
    COUNT(*) AS transaction_count
FROM sales_union su
JOIN time_dim td
    ON su.sold_time_sk = td.t_time_sk
JOIN item i
    ON su.item_sk = i.i_item_sk
JOIN customer c
    ON su.customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON su.addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON su.cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON su.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN promotion p
    ON su.promo_sk = p.p_promo_sk
LEFT JOIN ship_mode sm
    ON su.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
    ON su.warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_site ws
    ON su.web_site_sk = ws.web_site_sk
LEFT JOIN inventory_agg ia
    ON su.item_sk = ia.inv_item_sk
   AND su.warehouse_sk = ia.inv_warehouse_sk
WHERE td.t_shift = 'first'
  AND i.i_units = 'Dozen'
  AND sm.sm_code = 'AIR'
  AND ib.ib_upper_bound > 50000
GROUP BY
    i.i_category,
    td.t_shift,
    sm.sm_code,
    ws.web_name
ORDER BY total_sales DESC
LIMIT 100
