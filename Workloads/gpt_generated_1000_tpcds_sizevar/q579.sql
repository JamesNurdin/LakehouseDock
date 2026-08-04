WITH
    date_2001 AS (
        SELECT d_date_sk, d_year, d_date
        FROM date_dim
        WHERE d_year = 2001
    ),
    promo_types AS (
        SELECT *
        FROM (VALUES
            ('Email'),
            ('TV'),
            ('Catalog')
        ) AS t(promo_channel)
    ),
    agg_store_sales AS (
        SELECT
            ss_store_sk,
            ss_sold_date_sk,
            ss_cdemo_sk,
            ss_hdemo_sk,
            ss_addr_sk,
            ss_promo_sk,
            SUM(ss_quantity)         AS total_quantity,
            SUM(ss_net_profit)       AS total_net_profit
        FROM store_sales
        WHERE ss_quantity > 1
          AND ss_net_profit > 0
        GROUP BY ss_store_sk, ss_sold_date_sk, ss_cdemo_sk, ss_hdemo_sk, ss_addr_sk, ss_promo_sk
    ),
    agg_web_sales AS (
        SELECT
            ws_web_site_sk,
            ws_web_page_sk,
            ws_sold_date_sk,
            ws_bill_cdemo_sk,
            ws_bill_hdemo_sk,
            ws_bill_addr_sk,
            ws_promo_sk,
            SUM(ws_quantity)      AS total_web_quantity,
            SUM(ws_net_profit)    AS total_web_profit
        FROM web_sales
        WHERE ws_quantity > 1
          AND ws_ext_ship_cost < 500
        GROUP BY ws_web_site_sk, ws_web_page_sk, ws_sold_date_sk, ws_bill_cdemo_sk, ws_bill_hdemo_sk, ws_bill_addr_sk, ws_promo_sk
    )
SELECT
    s.s_store_id,
    s.s_state,
    cc.cc_name,
    d.d_date,
    pt.promo_channel,
    ca.ca_city,
    cd.cd_education_status,
    hd.hd_vehicle_count,
    p.p_promo_name,
    ws.total_web_profit,
    ss.total_net_profit,
    (
        SELECT SUM(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
    ) AS promo_total_cost,
    RANK() OVER (PARTITION BY s.s_state ORDER BY ss.total_net_profit DESC) AS profit_state_rank
FROM date_2001 d
CROSS JOIN promo_types pt
FULL OUTER JOIN agg_store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
FULL OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
LEFT JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN agg_web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE s.s_state = 'CA'
  AND cc.cc_country = 'United States'
  AND p.p_channel_email = 'Y'
  AND ca.ca_gmt_offset BETWEEN -5 AND 0
  AND cd.cd_education_status = 'College'
  AND hd.hd_vehicle_count >= 2
ORDER BY s.s_state, profit_state_rank
LIMIT 100
