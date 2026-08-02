/*
  Goal: Compute per‑item sales and return performance across store and web channels, joining all TPC‑DS tables, applying multiple filters, aggregating twice, and keeping unmatched items via a full outer join.
*/
WITH store_sales_agg AS (
    SELECT
        ss_item_sk,
        ss_ticket_number,
        ss_store_sk,
        ss_customer_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        SUM(ss_quantity) AS total_store_qty,
        SUM(ss_net_paid) AS total_store_net_paid,
        SUM(ss_net_profit) AS total_store_net_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451895 AND 2451905
        AND ss_quantity > 0
        AND ss_net_paid > 0
    GROUP BY ss_item_sk, ss_ticket_number, ss_store_sk, ss_customer_sk,
             ss_hdemo_sk, ss_addr_sk
),
web_sales_agg AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_ship_mode_sk,
        ws_bill_customer_sk,
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        ws_web_page_sk,
        SUM(ws_quantity) AS total_web_qty,
        SUM(ws_net_paid) AS total_web_net_paid,
        SUM(ws_net_profit) AS total_web_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451895 AND 2451905
        AND ws_quantity > 0
        AND ws_net_paid > 0
    GROUP BY ws_item_sk, ws_order_number, ws_ship_mode_sk,
             ws_bill_customer_sk, ws_bill_hdemo_sk, ws_bill_addr_sk,
             ws_web_page_sk
),
store_sales_item AS (
    SELECT
        ss.ss_item_sk,
        i.i_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_ticket_number,
        ss.total_store_qty,
        ss.total_store_net_paid,
        ss.total_store_net_profit
    FROM store_sales_agg ss
    JOIN item i ON i.i_item_sk = ss.ss_item_sk
),
web_sales_item AS (
    SELECT
        ws.ws_item_sk,
        i.i_item_sk,
        ws.ws_order_number,
        ws.ws_ship_mode_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_web_page_sk,
        ws.total_web_qty,
        ws.total_web_net_paid,
        ws.total_web_net_profit
    FROM web_sales_agg ws
    JOIN item i ON i.i_item_sk = ws.ws_item_sk
),
combined AS (
    SELECT
        COALESCE(ss_i.i_item_sk, ws_i.i_item_sk) AS i_item_sk,
        ss_i.ss_store_sk,
        ss_i.ss_customer_sk,
        ss_i.ss_hdemo_sk,
        ss_i.ss_addr_sk,
        ss_i.ss_ticket_number,
        ws_i.ws_order_number,
        ws_i.ws_ship_mode_sk,
        ws_i.ws_bill_customer_sk,
        ws_i.ws_bill_hdemo_sk,
        ws_i.ws_bill_addr_sk,
        ws_i.ws_web_page_sk,
        ss_i.total_store_qty,
        ss_i.total_store_net_paid,
        ss_i.total_store_net_profit,
        ws_i.total_web_qty,
        ws_i.total_web_net_paid,
        ws_i.total_web_net_profit
    FROM store_sales_item ss_i
    FULL OUTER JOIN web_sales_item ws_i
        ON ss_i.i_item_sk = ws_i.i_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    SUM(COALESCE(comb.total_store_qty, 0) + COALESCE(comb.total_web_qty, 0)) AS total_quantity,
    SUM(COALESCE(comb.total_store_net_paid, 0) + COALESCE(comb.total_web_net_paid, 0)) AS total_net_paid,
    SUM(COALESCE(comb.total_store_net_profit, 0) + COALESCE(comb.total_web_net_profit, 0)) AS total_net_profit,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_quantity,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    MAX(s.s_store_name) AS store_name,
    MIN(ca.ca_city) AS city,
    MIN(hd.hd_income_band_sk) AS income_band,
    MIN(sm.sm_type) AS ship_mode,
    MIN(wp.wp_url) AS web_page_url,
    MIN(rs.r_reason_desc) AS store_return_reason,
    MIN(rw.r_reason_desc) AS web_return_reason
FROM combined comb
JOIN item i ON i.i_item_sk = comb.i_item_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN store s ON s.s_store_sk = comb.ss_store_sk
LEFT JOIN customer c ON c.c_customer_sk = COALESCE(comb.ss_customer_sk, comb.ws_bill_customer_sk)
LEFT JOIN customer_address ca ON ca.ca_address_sk = COALESCE(comb.ss_addr_sk, comb.ws_bill_addr_sk)
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = COALESCE(comb.ss_hdemo_sk, comb.ws_bill_hdemo_sk)
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = comb.ws_ship_mode_sk
LEFT JOIN web_page wp ON wp.wp_web_page_sk = comb.ws_web_page_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = comb.i_item_sk
   AND sr.sr_ticket_number = comb.ss_ticket_number
LEFT JOIN reason rs ON rs.r_reason_sk = sr.sr_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = comb.i_item_sk
   AND wr.wr_order_number = comb.ws_order_number
LEFT JOIN reason rw ON rw.r_reason_sk = wr.wr_reason_sk
WHERE
    i.i_brand = 'Brand#44'
    AND i.i_category = 'Sports'
    AND ca.ca_gmt_offset = -5.00
    AND hd.hd_vehicle_count > 1
    AND s.s_state = 'CA'
    AND sm.sm_type = 'Air'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category
HAVING
    SUM(COALESCE(comb.total_store_net_profit, 0) + COALESCE(comb.total_web_net_profit, 0)) > 10000
ORDER BY
    total_net_profit DESC
LIMIT 100
