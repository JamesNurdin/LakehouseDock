WITH sales_cte AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_size,
        i.i_rec_end_date,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ca.ca_state,
        p.p_promo_id,
        p.p_cost,
        (
            SELECT AVG(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
        ) AS avg_item_promo_cost,
        cc.cc_division_name,
        cc.cc_employees,
        sm.sm_type,
        ws.ws_sold_date_sk,
        wp.wp_type,
        wsite.web_country,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM store_sales ss
    FULL OUTER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE i.i_size = 'large'
      AND i.i_rec_end_date > DATE '2000-01-01'
      AND cc.cc_employees > 1000000
      AND ca.ca_state = 'CA'
      AND wsite.web_country = 'United States'
),
agg AS (
    SELECT
        division,
        profit_flag,
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(DISTINCT item_id) AS distinct_items,
        SUM(net_paid) AS total_net_paid,
        AVG(net_profit) AS avg_net_profit,
        MAX(CASE WHEN profit_flag = 'Profitable' THEN net_profit END) AS max_profit
    FROM (
        SELECT
            cc_division_name AS division,
            profit_flag,
            c_customer_id AS customer_id,
            i_item_id AS item_id,
            ss_net_paid AS net_paid,
            ss_net_profit AS net_profit
        FROM sales_cte
    ) sub
    GROUP BY division, profit_flag
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY division ORDER BY total_net_paid DESC) AS rn
    FROM agg
)
SELECT
    division,
    profit_flag,
    distinct_customers,
    distinct_items,
    total_net_paid,
    avg_net_profit,
    max_profit,
    rn
FROM ranked
WHERE rn <= 5
ORDER BY division, rn
LIMIT 100
