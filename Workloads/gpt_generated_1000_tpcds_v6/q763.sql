WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM tpcds.store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451220
    GROUP BY
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number
)
SELECT
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    s.s_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sa.total_net_paid,
    sa.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY sa.total_net_paid DESC) AS sales_rank,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_type,
    (
        SELECT AVG(ss_inner.ss_net_paid)
        FROM tpcds.store_sales ss_inner
        WHERE ss_inner.ss_item_sk = i.i_item_sk
    ) AS avg_item_net_paid,
    (
        SELECT COUNT(*)
        FROM tpcds.store_returns sr_inner
        WHERE sr_inner.sr_item_sk = i.i_item_sk
    ) AS return_count
FROM sales_agg sa
JOIN tpcds.store_sales ss ON ss.ss_item_sk = sa.ss_item_sk
    AND ss.ss_store_sk = sa.ss_store_sk
    AND ss.ss_ticket_number = sa.ss_ticket_number
JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.inventory inv ON i.i_item_sk = inv.inv_item_sk
JOIN tpcds.warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN tpcds.store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    AND sr.sr_item_sk = i.i_item_sk
JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
WHERE
    s.s_state = 'CA'
    AND i.i_brand = 'Brand#45'
    AND wp.wp_autogen_flag = 'Y'
    AND p.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr_chk
        WHERE sr_chk.sr_item_sk = i.i_item_sk
            AND sr_chk.sr_return_quantity > 0
    )
ORDER BY sales_rank, i.i_item_id
LIMIT 100
