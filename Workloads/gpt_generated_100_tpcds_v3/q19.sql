WITH joined_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        ca.ca_state,
        ca.ca_gmt_offset,
        inv.inv_quantity_on_hand,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_response_target,
        ss.ss_ticket_number,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        r.r_reason_desc,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        wp.wp_type,
        sm.sm_type AS ship_mode_type
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN ship_mode sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    WHERE i.i_current_price > 100.00
      AND ca.ca_state IN ('TX', 'GA', 'OH')
      AND p.p_response_target = 1
      AND inv.inv_quantity_on_hand > 200
), aggregated AS (
    SELECT
        i_item_id,
        i_product_name,
        ca_state,
        SUM(ss_net_paid) AS sum_store_sales,
        SUM(ws_net_paid) AS sum_web_sales,
        SUM(ss_quantity) AS sum_store_qty,
        SUM(ws_quantity) AS sum_web_qty,
        SUM(sr_return_amt) AS sum_return_amt,
        COUNT(DISTINCT p_promo_sk) AS promo_cnt
    FROM joined_data
    GROUP BY i_item_id, i_product_name, ca_state
    HAVING (SUM(ss_net_paid) + SUM(ws_net_paid)) > 5000
       AND COUNT(DISTINCT p_promo_sk) >= 1
)
SELECT
    i_item_id,
    i_product_name,
    ca_state,
    (sum_store_sales + sum_web_sales) AS total_sales,
    (sum_store_qty + sum_web_qty) AS total_quantity,
    CASE WHEN (sum_store_sales + sum_web_sales) - sum_return_amt > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
    RANK() OVER (PARTITION BY ca_state ORDER BY (sum_store_sales + sum_web_sales) DESC) AS sales_state_rank,
    promo_cnt
FROM aggregated
ORDER BY ca_state, sales_state_rank
LIMIT 100
