WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 500
    GROUP BY inv_date_sk, inv_item_sk, inv_warehouse_sk
)
SELECT
    d.d_year,
    s.s_store_name,
    c.cd_gender,
    p.p_promo_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(CASE WHEN sr.sr_net_loss IS NOT NULL THEN sr.sr_net_loss ELSE 0 END) AS total_return_loss,
    MAX(CASE WHEN cc.cc_gmt_offset > 0 THEN cc.cc_gmt_offset ELSE NULL END) AS max_gmt_offset,
    CASE
        WHEN s.s_floor_space > (
            SELECT MAX(s2.s_floor_space)
            FROM store s2
            WHERE s2.s_state = 'CA'
        ) THEN 'Larger than CA max'
        ELSE 'Smaller or equal'
    END AS floor_space_flag,
    s.s_floor_space
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics c ON ss.ss_cdemo_sk = c.cd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN inv_agg i ON i.inv_date_sk = d.d_date_sk
    AND i.inv_item_sk = ss.ss_item_sk
WHERE
    d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND c.cd_marital_status = 'M'
    AND s.s_market_manager = 'David Smith'
    AND s.s_floor_space > 8000000
    AND p.p_promo_name LIKE '%Clearance%'
    AND wp.wp_type = 'Content'
    AND ss.ss_item_sk IN (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 1000
    )
GROUP BY
    d.d_year,
    s.s_store_name,
    c.cd_gender,
    p.p_promo_name,
    s.s_floor_space
ORDER BY total_sales DESC
LIMIT 100
