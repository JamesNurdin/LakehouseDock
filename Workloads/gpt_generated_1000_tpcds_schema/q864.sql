WITH intersected_tickets AS (
    SELECT ss.ss_ticket_number AS ticket_number
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
    INTERSECT
    SELECT sr.sr_ticket_number
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
)
SELECT
    s.s_store_id,
    d.d_date,
    i.i_item_id,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    CASE WHEN ss.ss_ext_sales_price > 1000 THEN 'High' ELSE 'Normal' END AS price_category,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_ext_sales_price DESC) AS sales_rank,
    ss.ss_ext_sales_price - (
        SELECT AVG(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_sold_date_sk = ss.ss_sold_date_sk
    ) AS price_vs_avg
FROM
    store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_returned_time_sk = t.t_time_sk
    AND cr.cr_item_sk = i.i_item_sk
    AND cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
WHERE
    d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 9 AND 17
    AND ss.ss_ticket_number NOT IN (
        SELECT cr_order_number FROM catalog_returns
    )
    AND ss.ss_ticket_number IN (
        SELECT ticket_number FROM intersected_tickets
    )
    AND ss.ss_ext_sales_price > (
        SELECT MAX(ss3.ss_ext_sales_price)
        FROM store_sales ss3
        WHERE ss3.ss_sold_date_sk = d.d_date_sk
    )
ORDER BY
    sales_rank,
    ss.ss_ext_sales_price DESC
LIMIT 100
