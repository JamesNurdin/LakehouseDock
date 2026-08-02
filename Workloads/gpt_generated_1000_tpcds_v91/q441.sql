WITH
    address_expanded AS (
        SELECT
            ca.ca_address_sk,
            loc
        FROM customer_address ca
        CROSS JOIN UNNEST(ARRAY[ca.ca_city, ca.ca_state]) AS t (loc)
    ),
    inventory_agg AS (
        SELECT
            i.i_item_sk,
            SUM(inv.inv_quantity_on_hand) AS total_on_hand
        FROM inventory inv
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        WHERE inv.inv_warehouse_sk IN (5, 12)
        GROUP BY i.i_item_sk
    ),
    store_sales_agg AS (
        SELECT
            ss.ss_item_sk,
            ss.ss_addr_sk,
            SUM(ss.ss_net_paid) AS total_net_paid,
            COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE s.s_company_id = 1
          AND s.s_county = 'Fairfield County'
          AND i.i_current_price > 10
          AND s.s_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
        GROUP BY ss.ss_item_sk, ss.ss_addr_sk
    ),
    catalog_returns_agg AS (
        SELECT
            cr.cr_item_sk,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY cr.cr_item_sk
    ),
    web_returns_agg AS (
        SELECT
            wr.wr_item_sk,
            SUM(wr.wr_return_amt) AS total_wr_return_amt,
            COUNT(*) AS wr_return_cnt
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE wp.wp_type = 'product'
          AND wp.wp_link_count > 5
        GROUP BY wr.wr_item_sk
    ),
    full_returns AS (
        SELECT
            COALESCE(cr.cr_item_sk, wr.wr_item_sk) AS item_sk,
            cr.total_return_amount,
            cr.return_cnt,
            wr.total_wr_return_amt,
            wr.wr_return_cnt
        FROM catalog_returns_agg cr
        FULL OUTER JOIN web_returns_agg wr
            ON cr.cr_item_sk = wr.wr_item_sk
    )
SELECT
    i.i_item_sk,
    i.i_item_desc,
    i.i_current_price,
    latest_p.p_promo_id,
    inv_agg.total_on_hand,
    ss_agg.total_net_paid,
    ss_agg.ticket_cnt,
    fr.total_return_amount,
    fr.return_cnt,
    fr.total_wr_return_amt,
    fr.wr_return_cnt,
    addr_exp.loc AS address_part,
    ROW_NUMBER() OVER (ORDER BY ss_agg.total_net_paid DESC) AS overall_rn
FROM item i
LEFT JOIN LATERAL (
    SELECT p.p_promo_id, p.p_start_date_sk
    FROM promotion p
    WHERE p.p_item_sk = i.i_item_sk
      AND p.p_discount_active = 'Y'
    ORDER BY p.p_start_date_sk DESC
    LIMIT 1
) latest_p ON TRUE
LEFT JOIN inventory_agg inv_agg ON i.i_item_sk = inv_agg.i_item_sk
LEFT JOIN store_sales_agg ss_agg ON i.i_item_sk = ss_agg.ss_item_sk
LEFT JOIN full_returns fr ON i.i_item_sk = fr.item_sk
LEFT JOIN address_expanded addr_exp ON ss_agg.ss_addr_sk = addr_exp.ca_address_sk
WHERE EXISTS (
    SELECT 1 FROM inventory_agg inv_check WHERE inv_check.i_item_sk = i.i_item_sk
)
ORDER BY overall_rn
LIMIT 100
