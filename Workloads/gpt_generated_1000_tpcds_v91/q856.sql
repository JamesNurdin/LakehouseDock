WITH base AS (
    SELECT
        td.t_time_sk,
        td.t_hour,
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cs.cs_sold_date_sk AS cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cc.cc_mkt_id,
        cc.cc_market_manager,
        cp.cp_department,
        p.p_discount_active,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        inc.ib_lower_bound,
        inc.ib_upper_bound,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ca.ca_city,
        ca.ca_street_type
    FROM
        time_dim td
        JOIN store_sales ss
            ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN store_returns sr
            ON sr.sr_return_time_sk = td.t_time_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN catalog_returns cr
            ON cr.cr_returned_time_sk = td.t_time_sk
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_order_number = cs.cs_order_number
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        CROSS JOIN LATERAL (
            SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
            FROM income_band ib
            WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
        ) AS inc
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND ss.ss_quantity > 2
        AND ss.ss_net_paid >= 1000
        AND p.p_discount_active = 'Y'
        AND inc.ib_lower_bound >= 60000
        AND c.c_birth_year BETWEEN 1960 AND 1985
        AND ca.ca_street_type = 'Ave'
        AND cc.cc_mkt_id IN (1, 2, 3)
        AND c.c_customer_sk IN (
            SELECT cf.c_customer_sk
            FROM customer cf
            WHERE cf.c_preferred_cust_flag = 'Y'
        )
),
agg AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        ca_city,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(cs_net_profit) AS total_catalog_profit,
        SUM(COALESCE(sr_net_loss, 0)) AS total_store_return_loss,
        SUM(COALESCE(cr_net_loss, 0)) AS total_catalog_return_loss,
        (SUM(ss_net_profit) + SUM(cs_net_profit) - SUM(COALESCE(sr_net_loss, 0)) - SUM(COALESCE(cr_net_loss, 0))) AS net_profit,
        CASE
            WHEN (SUM(ss_net_profit) + SUM(cs_net_profit)) > 5000 THEN 'High'
            WHEN (SUM(ss_net_profit) + SUM(cs_net_profit)) BETWEEN 2000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM base
    GROUP BY
        c_customer_sk,
        c_first_name,
        c_last_name,
        ca_city
)
SELECT
    a.c_customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.ca_city,
    a.total_store_profit,
    a.total_catalog_profit,
    a.total_store_return_loss,
    a.total_catalog_return_loss,
    a.net_profit,
    a.profit_category,
    ROW_NUMBER() OVER (ORDER BY a.net_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (ORDER BY a.net_profit DESC) AS profit_dense_rank,
    CASE
        WHEN a.net_profit > overall.avg_net_profit THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS avg_comparison,
    grp.g AS dummy_group
FROM agg a
CROSS JOIN (SELECT AVG(net_profit) AS avg_net_profit FROM agg) AS overall
CROSS JOIN (VALUES (1), (2), (3)) AS grp(g)
WHERE a.profit_category <> 'Low'
ORDER BY a.net_profit DESC
LIMIT 50
