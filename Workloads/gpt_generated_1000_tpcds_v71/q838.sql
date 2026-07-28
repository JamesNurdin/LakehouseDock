WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        SUM(ss.ss_net_profit)      AS total_net_profit,
        SUM(ss.ss_quantity)        AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    GROUP BY
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk
),
-- distinct list of web pages for a meaningful DISTINCT usage
distinct_wp AS (
    SELECT DISTINCT wp.wp_web_page_id
    FROM web_page wp
)
SELECT DISTINCT
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_state,
    i.i_item_id,
    i.i_brand,
    p.p_promo_name,
    c.c_customer_id,
    cd.cd_gender,
    total_net_profit,
    total_quantity,
    distinct_tickets,
    r.r_reason_desc,
    wp.wp_url,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg sa
JOIN date_dim d
    ON sa.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN item i
    ON sa.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
JOIN customer c
    ON sa.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sa.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN distinct_wp dwp
    ON wp.wp_web_page_id = dwp.wp_web_page_id
WHERE
    d.d_year = 2001
    AND s.s_state = 'CA'
    AND i.i_brand = 'Brand#21'
    AND w.w_county NOT IN ('Franklin Parish', 'Fairfield County')
    AND p.p_discount_active = 'Y'
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_returned_date_sk = d.d_date_sk
    )
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_state,
    i.i_item_id,
    i.i_brand,
    p.p_promo_name,
    c.c_customer_id,
    cd.cd_gender,
    total_net_profit,
    total_quantity,
    distinct_tickets,
    r.r_reason_desc,
    wp.wp_url
HAVING
    total_quantity > 10
ORDER BY
    profit_rank,
    total_net_profit DESC
LIMIT 100
