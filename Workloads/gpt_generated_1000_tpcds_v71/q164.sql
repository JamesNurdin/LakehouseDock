WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        ca.ca_city,
        ca.ca_location_type,
        c.c_salutation,
        p.p_promo_name,
        r.r_reason_desc,
        t.t_hour,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_net_profit) AS avg_profit,
        COUNT(*) AS txn_count,
        CASE
            WHEN SUM(ss.ss_net_profit) > 100000 THEN 'HIGH'
            WHEN SUM(ss.ss_net_profit) > 50000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE c.c_salutation = 'Mr.'
        AND c.c_current_cdemo_sk IN (213219, 1185612)
        AND ca.ca_location_type = 'single family'
        AND ca.ca_gmt_offset = -6.00
        AND p.p_discount_active = 'Y'
        AND r.r_reason_desc LIKE '%defect%'
        AND t.t_hour BETWEEN 9 AND 17
        AND s.s_state = 'CA'
    GROUP BY
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        ca.ca_city,
        ca.ca_location_type,
        c.c_salutation,
        p.p_promo_name,
        r.r_reason_desc,
        t.t_hour
)
SELECT
    sa.s_store_id,
    sa.s_state,
    sa.ca_city,
    sa.ca_location_type,
    sa.c_salutation,
    sa.p_promo_name,
    sa.r_reason_desc,
    sa.t_hour,
    sa.total_profit,
    sa.total_quantity,
    sa.avg_profit,
    sa.txn_count,
    sa.profit_category,
    ROW_NUMBER() OVER (PARTITION BY sa.s_store_id ORDER BY sa.total_profit DESC) AS profit_rank,
    SUM(sa.total_profit) OVER (PARTITION BY sa.s_state) AS state_total_profit,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_store_sk = sa.s_store_sk) AS store_txn_count
FROM sales_agg sa
ORDER BY sa.total_profit DESC
LIMIT 100
