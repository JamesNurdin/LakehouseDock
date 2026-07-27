WITH
    store_agg AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            SUM(ss.ss_quantity) AS store_qty,
            SUM(ss.ss_net_paid) AS store_net_paid,
            COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
            MIN(ss.ss_sold_date_sk) AS store_first_date,
            MAX(ss.ss_sold_date_sk) AS store_last_date
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE
            ss.ss_quantity >= 2
            AND i.i_current_price BETWEEN 10 AND 100
            AND hd.hd_vehicle_count > 0
            AND ca.ca_state = 'TX'
            AND ib.ib_upper_bound <= 120000
            AND (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand > 0)
        GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
    ),
    web_agg AS (
        SELECT
            i.i_item_sk,
            SUM(ws.ws_quantity) AS web_qty,
            SUM(ws.ws_net_paid) AS web_net_paid,
            COUNT(DISTINCT ws.ws_order_number) AS web_orders,
            MIN(ws.ws_sold_date_sk) AS web_first_date,
            MAX(ws.ws_sold_date_sk) AS web_last_date,
            ws.ws_ship_mode_sk,
            ws.ws_web_site_sk
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE
            ws.ws_quantity >= 2
            AND i.i_current_price BETWEEN 10 AND 100
            AND hd.hd_vehicle_count > 0
            AND ca.ca_state = 'CA'
            AND ib.ib_upper_bound <= 120000
            AND (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand > 0)
        GROUP BY i.i_item_sk, ws.ws_ship_mode_sk, ws.ws_web_site_sk
    ),
    joined AS (
        SELECT
            s.i_item_sk,
            s.i_item_id,
            s.i_product_name,
            s.store_qty,
            s.store_net_paid,
            s.store_orders,
            w.web_qty,
            w.web_net_paid,
            w.web_orders,
            COALESCE(sm.sm_ship_mode_id, 'UNKNOWN') AS ship_mode_id,
            COALESCE(ws.web_name, 'UNKNOWN') AS web_site_name,
            (s.store_net_paid + w.web_net_paid) AS total_net_paid,
            (s.store_qty + w.web_qty) AS total_qty,
            CASE
                WHEN (s.store_qty + w.web_qty) = 0 THEN 'NO SALES'
                WHEN (s.store_qty + w.web_qty) < 5 THEN 'LOW'
                ELSE 'HIGH'
            END AS sales_volume_category
        FROM store_agg s
        JOIN web_agg w ON s.i_item_sk = w.i_item_sk
        LEFT JOIN ship_mode sm ON w.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN web_site ws ON w.ws_web_site_sk = ws.web_site_sk
    )
SELECT
    DISTINCT i_item_sk,
    i_item_id,
    i_product_name,
    total_qty,
    total_net_paid,
    sales_volume_category,
    ship_mode_id,
    web_site_name,
    RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank
FROM joined
WHERE total_net_paid > 1000
  AND sales_volume_category <> 'NO SALES'
ORDER BY sales_rank
LIMIT 100
