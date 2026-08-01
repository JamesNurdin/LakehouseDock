WITH base AS (
    SELECT
        dd.d_year,
        s.s_state,
        s.s_city,
        p.p_channel_email,
        r.r_reason_desc,
        cs.cs_net_profit,
        sr.sr_net_loss,
        sm.sm_type,
        cc.cc_name,
        cp.cp_department,
        cs.cs_order_number
    FROM store_returns sr
    JOIN date_dim dd
        ON sr.sr_returned_date_sk = dd.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    WHERE dd.d_year = 2001
      AND s.s_state = 'CA'
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND p.p_channel_email = 'Y'
),
agg AS (
    SELECT
        s_state,
        p_channel_email,
        r_reason_desc,
        SUM(cs_net_profit) AS sum_net_profit,
        SUM(sr_net_loss) AS sum_net_loss,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY ROLLUP (s_state, p_channel_email, r_reason_desc)
    HAVING SUM(cs_net_profit) > 0
),
ranked AS (
    SELECT
        s_state,
        p_channel_email,
        r_reason_desc,
        sum_net_profit,
        sum_net_loss,
        txn_count,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY sum_net_profit DESC) AS profit_rank,
        AVG(sum_net_profit) OVER () AS avg_profit
    FROM agg
)
SELECT *
FROM ranked r1
WHERE r1.sum_net_profit > r1.avg_profit
  AND NOT EXISTS (
      SELECT 1 FROM reason r2 WHERE r2.r_reason_desc = r1.r_reason_desc AND r2.r_reason_desc = 'Damaged'
  )
EXCEPT
SELECT *
FROM ranked r2
WHERE r2.sum_net_profit < (SELECT AVG(sum_net_profit) FROM agg) * 0.5
ORDER BY s_state, sum_net_profit DESC
LIMIT 100
