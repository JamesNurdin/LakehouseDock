/*
Goal: Compare yearly profit contributions from catalog, web, and store channels by ship mode, while accounting for store returns. The query ranks states (via web_site) by total contribution and shows the average catalog profit for the year.
*/
WITH catalog_agg AS (
    SELECT
        d.d_year,
        sm.sm_ship_mode_id,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001                           -- filter 1: specific year
      AND sm.sm_type = 'AIR'                        -- filter 2: ship mode type
      AND hd.hd_buy_potential = '5000-10000'        -- filter 3: household buying potential
    GROUP BY d.d_year, sm.sm_ship_mode_id
),
web_agg AS (
    SELECT
        d.d_year,
        sm.sm_ship_mode_id,
        we.web_state,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND we.web_country = 'United States'
      AND wp.wp_type = 'CONTENT'
      AND hd.hd_buy_potential = '5000-10000'
    GROUP BY d.d_year, sm.sm_ship_mode_id, we.web_state
),
store_agg AS (
    SELECT
        d.d_year,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND d.d_holiday = 'N'
      AND hd.hd_buy_potential = '5000-10000'
    GROUP BY d.d_year
),
return_agg AS (
    SELECT
        d.d_year,
        SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND hd.hd_buy_potential = '5000-10000'
    GROUP BY d.d_year
)
SELECT
    ca.d_year,
    ca.sm_ship_mode_id,
    ca.catalog_profit,
    wa.web_profit,
    sa.store_profit,
    ra.return_loss,
    (ca.catalog_profit + wa.web_profit + sa.store_profit + ra.return_loss) AS total_contribution,
    RANK() OVER (PARTITION BY ca.d_year ORDER BY (ca.catalog_profit + wa.web_profit + sa.store_profit + ra.return_loss) DESC) AS profit_rank,
    (
        SELECT AVG(catalog_profit)
        FROM catalog_agg sub_ca
        WHERE sub_ca.d_year = ca.d_year
    ) AS avg_catalog_profit_year
FROM catalog_agg ca
JOIN web_agg wa ON ca.d_year = wa.d_year AND ca.sm_ship_mode_id = wa.sm_ship_mode_id
JOIN store_agg sa ON ca.d_year = sa.d_year
JOIN return_agg ra ON ca.d_year = ra.d_year
ORDER BY total_contribution DESC
LIMIT 100
