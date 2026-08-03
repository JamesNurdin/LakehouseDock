WITH sales_base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        td.t_hour,
        p.p_discount_active,
        ca.ca_zip,
        cc.cc_country,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_returns_loss,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_profit,
        lr.latest_return_qty
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN LATERAL (
        SELECT SUM(sr2.sr_return_quantity) AS latest_return_qty
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
    ) lr ON TRUE
    WHERE
        td.t_hour BETWEEN 9 AND 17               -- filter 1: business hours
        AND s.s_state = 'CA'                     -- filter 2: California stores
        AND ca.ca_zip LIKE '9%'                  -- filter 3: ZIP codes starting with 9
        AND p.p_discount_active = 'Y'            -- filter 4: active discount promotions
        AND cc.cc_country = 'United States'      -- filter 5: US call centers
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        td.t_hour,
        p.p_discount_active,
        ca.ca_zip,
        cc.cc_country,
        lr.latest_return_qty
)
SELECT
    s_store_id,
    s_store_name,
    t_hour,
    total_store_profit,
    total_store_returns_loss,
    total_web_profit,
    RANK() OVER (PARTITION BY t_hour ORDER BY total_store_profit DESC) AS profit_rank_per_hour,
    CASE WHEN p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_type,
    latest_return_qty
FROM sales_base
ORDER BY t_hour, profit_rank_per_hour
