/*
Goal: Identify stores with the highest combined net loss from store returns, catalog returns, and web returns during peak business hours, 
while filtering for good‑credit customers in specific cities, small web order quantities, and air‑shipping. The query joins all 14 selected TPC‑DS tables, applies six predicates, uses LEFT OUTER JOINs, and ranks stores by total net loss.
*/
WITH base AS (
    SELECT
        s.s_store_name,
        s.s_city,
        ca.ca_city AS address_city,
        cd.cd_credit_rating,
        p.p_promo_name,
        sm.sm_type,
        t.t_hour,
        sr.sr_net_loss,
        cr.cr_net_loss,
        wr.wr_net_loss,
        cr.cr_refunded_cash,
        ws.ws_quantity
    FROM time_dim t
    -- Store‑related tables (LEFT OUTER JOIN to guarantee outer‑join presence)
    LEFT JOIN store_returns sr          ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN store s                 ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r                ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca      ON sr.sr_addr_sk = ca.ca_address_sk
    -- Catalog return tables
    LEFT JOIN catalog_returns cr       ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN call_center cc           ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm              ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    -- Web sales and related tables
    LEFT JOIN web_sales ws             ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p               ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr           ON wr.wr_returned_time_sk = t.t_time_sk
                                      AND wr.wr_order_number = ws.ws_order_number
                                      AND wr.wr_item_sk = ws.ws_item_sk
)
SELECT
    s_store_name,
    s_city,
    address_city,
    cd_credit_rating,
    p_promo_name,
    sm_type,
    t_hour,
    total_net_loss,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM (
    SELECT
        s_store_name,
        s_city,
        address_city,
        cd_credit_rating,
        p_promo_name,
        sm_type,
        t_hour,
        SUM(COALESCE(sr_net_loss, 0) + COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_net_loss
    FROM base
    WHERE
        t_hour BETWEEN 9 AND 17                     -- peak business hours
        AND cd_credit_rating = 'Good'                -- good‑credit customers
        AND address_city IN ('Lakeview', 'Glendale') -- targeted cities
        AND cr_refunded_cash > 50                    -- substantial refunds
        AND ws_quantity <= 5                        -- small web orders
        AND sm_type = 'AIR'                          -- air shipping only
    GROUP BY
        s_store_name,
        s_city,
        address_city,
        cd_credit_rating,
        p_promo_name,
        sm_type,
        t_hour
) agg
ORDER BY loss_rank
LIMIT 100
