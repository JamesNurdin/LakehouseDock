WITH store_data AS (
    SELECT
        d.d_date AS d_date,
        i.i_item_sk AS i_item_sk,
        i.i_item_id AS i_item_id,
        i.i_item_desc AS i_item_desc,
        i.i_current_price AS i_current_price,
        ca.ca_country AS ca_country,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        p.p_promo_id AS p_promo_id,
        cp.cp_catalog_page_id AS cp_catalog_page_id,
        NULL AS web_site_id,
        NULL AS sm_ship_mode_id,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        sr.sr_return_amt AS return_amt,
        hd.hd_income_band_sk AS hd_income_band_sk,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON p.p_start_date_sk = cp.cp_start_date_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND ca.ca_country = 'United States'
      AND i.i_current_price > 100
),
web_data AS (
    SELECT
        d.d_date AS d_date,
        i.i_item_sk AS i_item_sk,
        i.i_item_id AS i_item_id,
        i.i_item_desc AS i_item_desc,
        i.i_current_price AS i_current_price,
        ca.ca_country AS ca_country,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        p.p_promo_id AS p_promo_id,
        cp.cp_catalog_page_id AS cp_catalog_page_id,
        ws2.web_site_id AS web_site_id,
        sm.sm_ship_mode_id AS sm_ship_mode_id,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        NULL AS return_amt,
        hd.hd_income_band_sk AS hd_income_band_sk,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON p.p_start_date_sk = cp.cp_start_date_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws2 ON ws.ws_web_site_sk = ws2.web_site_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND ca.ca_country = 'United States'
      AND i.i_current_price > 100
),
union_data AS (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
),
ranked AS (
    SELECT
        ud.*,
        RANK() OVER (PARTITION BY d_date ORDER BY net_profit DESC) AS profit_rank,
        CASE WHEN net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        (SELECT AVG(inv_quantity_on_hand)
         FROM inventory inv2
         WHERE inv2.inv_item_sk = ud.i_item_sk) AS avg_inventory_qty
    FROM union_data ud
)
SELECT
    d_date,
    i_item_id,
    i_item_desc,
    i_current_price,
    ca_country,
    net_paid,
    net_profit,
    p_promo_id,
    cp_catalog_page_id,
    COALESCE(web_site_id, 'N/A') AS web_site_id,
    COALESCE(sm_ship_mode_id, 'N/A') AS sm_ship_mode_id,
    inv_quantity_on_hand,
    return_amt,
    hd_income_band_sk,
    channel,
    profit_rank,
    profit_flag,
    avg_inventory_qty
FROM ranked
WHERE profit_rank <= 5
ORDER BY d_date DESC, profit_rank
LIMIT 100
