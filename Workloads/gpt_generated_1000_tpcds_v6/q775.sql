WITH promo_set AS (
    SELECT p_promo_sk FROM promotion WHERE p_discount_active = 'Y'
    UNION
    SELECT p_promo_sk FROM promotion WHERE p_channel_tv = 'Y'
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_category,
    t.t_sub_shift,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN sr.sr_return_amt ELSE 0 END) AS damaged_returns,
    AVG(cs.cs_quantity) AS avg_quantity,
    MIN(cs.cs_sales_price) AS min_sales_price,
    MAX(cs.cs_sales_price) AS max_sales_price,
    (SELECT MAX(p_cost) FROM promotion WHERE p_discount_active = 'Y') AS max_active_promo_cost
FROM
    store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promo_set ps
        ON ss.ss_promo_sk = ps.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_reason_sk = r.r_reason_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
WHERE
    i.i_manufact_id IN (460, 117)
    AND i.i_color = 'Red'
    AND s.s_state = 'CA'
    AND t.t_sub_shift = 'morning'
    AND cp.cp_type = 'A'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    i.i_category,
    t.t_sub_shift
ORDER BY total_sales DESC
LIMIT 100
