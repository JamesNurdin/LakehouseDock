WITH joined AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_brand_id,
        i.i_color,
        c.c_preferred_cust_flag,
        w.w_state AS warehouse_state,
        cp.cp_type,
        wp.wp_type,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        inv.inv_quantity_on_hand,
        sr.sr_ticket_number
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                     AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
                     AND wp.wp_customer_sk = c.c_customer_sk
    WHERE
        i.i_brand_id IN (10005006, 2004002)
        AND i.i_color = 'Red'
        AND s.s_state = 'CA'
        AND c.c_preferred_cust_flag = 'Y'
        AND d.d_year = 2000
        AND w.w_state = 'TX'
        AND cp.cp_type = 'A'
        AND wp.wp_type = 'Content'
)
SELECT
    d_year,
    s_state,
    i_brand_id,
    COUNT(*) AS return_count,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty,
    SUM(SUM(sr_return_amt)) OVER (PARTITION BY s_state) AS state_total_return,
    RANK() OVER (ORDER BY SUM(sr_return_amt) DESC) AS return_amount_rank
FROM joined
GROUP BY d_year, s_state, i_brand_id
ORDER BY total_return_amount DESC
LIMIT 100
