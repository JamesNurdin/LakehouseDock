WITH agg AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        cc.cc_name,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
        JOIN customer cu_ss ON ss.ss_customer_sk = cu_ss.c_customer_sk
        JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
        JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        -- Catalog Sales
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
            AND cs.cs_sold_time_sk = t_ss.t_time_sk
            AND cs.cs_promo_sk = p.p_promo_sk
        -- Call Center
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        -- Catalog Returns
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_returned_date_sk = d.d_date_sk
        -- Web Sales
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_promo_sk = p.p_promo_sk
        JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        d.d_year = 2000
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND t_ss.t_hour BETWEEN 9 AND 17
        AND ca_ss.ca_state = 'WA'
        AND cd_ss.cd_gender = 'M'
        AND hd_ss.hd_income_band_sk = 3
        AND EXISTS (
            SELECT 1 FROM reason r
            WHERE r.r_reason_sk = cr.cr_reason_sk
              AND r.r_reason_desc = 'Damaged'
        )
    GROUP BY
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        cc.cc_name
)
SELECT
    agg.d_year,
    agg.s_store_id,
    agg.s_store_name,
    agg.s_state,
    agg.p_promo_name,
    agg.cc_name,
    agg.total_store_profit,
    agg.total_catalog_net_paid,
    agg.total_web_net_paid,
    agg.total_return_amount,
    agg.distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.total_store_profit DESC) AS store_profit_rank
FROM agg
ORDER BY agg.total_store_profit DESC
LIMIT 100
