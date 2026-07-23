WITH date_filtered AS (
    SELECT d_date_sk, d_date, d_year, d_moy
    FROM date_dim
    WHERE d_year = 2000
      AND d_moy IN (1, 2)
),
sales_union AS (
    SELECT
        ss_sold_date_sk    AS sold_date_sk,
        ss_item_sk         AS item_sk,
        ss_cdemo_sk        AS cdemo_sk,
        ss_store_sk        AS store_sk,
        ss_promo_sk        AS promo_sk,
        ss_quantity        AS quantity,
        ss_sales_price     AS sales_price,
        ss_ext_sales_price AS ext_sales_price,
        ss_net_paid        AS net_paid,
        ss_net_profit      AS net_profit,
        ss_ticket_number   AS ticket_number,
        NULL               AS order_number,
        NULL               AS ship_mode_sk,
        NULL               AS warehouse_sk,
        NULL               AS web_page_sk,
        NULL               AS web_site_sk,
        'store'            AS sales_channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_sold_date_sk    AS sold_date_sk,
        ws_item_sk         AS item_sk,
        ws_bill_cdemo_sk   AS cdemo_sk,
        NULL               AS store_sk,
        ws_promo_sk        AS promo_sk,
        ws_quantity        AS quantity,
        ws_sales_price     AS sales_price,
        ws_ext_sales_price AS ext_sales_price,
        ws_net_paid        AS net_paid,
        ws_net_profit      AS net_profit,
        NULL               AS ticket_number,
        ws_order_number    AS order_number,
        ws_ship_mode_sk    AS ship_mode_sk,
        ws_warehouse_sk    AS warehouse_sk,
        ws_web_page_sk     AS web_page_sk,
        ws_web_site_sk     AS web_site_sk,
        'web'              AS sales_channel
    FROM web_sales
)
SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    p.p_promo_name,
    s.s_state,
    sm.sm_carrier,
    COUNT(DISTINCT cd.cd_demo_sk)       AS distinct_customers,
    SUM(su.ext_sales_price)            AS total_sales,
    AVG(su.ext_sales_price)            AS avg_sales,
    SUM(su.net_profit)                 AS total_profit,
    MIN(su.ext_sales_price)            AS min_sale,
    MAX(su.ext_sales_price)            AS max_sale
FROM date_filtered d
JOIN sales_union su ON su.sold_date_sk = d.d_date_sk
LEFT JOIN item i               ON i.i_item_sk = su.item_sk
LEFT JOIN promotion p          ON p.p_promo_sk = su.promo_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = su.cdemo_sk
LEFT JOIN store s              ON s.s_store_sk = su.store_sk
LEFT JOIN ship_mode sm         ON sm.sm_ship_mode_sk = su.ship_mode_sk
LEFT JOIN warehouse w          ON w.w_warehouse_sk = su.warehouse_sk
LEFT JOIN web_page wp          ON wp.wp_web_page_sk = su.web_page_sk
LEFT JOIN web_site we          ON we.web_site_sk = su.web_site_sk
LEFT JOIN call_center cc       ON cc.cc_closed_date_sk = d.d_date_sk
LEFT JOIN store_returns sr    ON sr.sr_ticket_number = su.ticket_number
LEFT JOIN web_returns wr      ON wr.wr_order_number = su.order_number
WHERE
    i.i_category       = 'Sports'
    AND p.p_discount_active = 'Y'
    AND cd.cd_gender    = 'M'
    AND (s.s_state = 'CA' OR s.s_state IS NULL)
    AND (sm.sm_carrier = 'UPS' OR sm.sm_carrier IS NULL)
    AND (cc.cc_city = 'San Francisco' OR cc.cc_city IS NULL)
    AND (we.web_country = 'United States' OR we.web_country IS NULL)
GROUP BY
    d.d_year,
    d.d_moy,
    i.i_category,
    p.p_promo_name,
    s.s_state,
    sm.sm_carrier
ORDER BY
    d.d_year,
    d.d_moy,
    total_sales DESC
