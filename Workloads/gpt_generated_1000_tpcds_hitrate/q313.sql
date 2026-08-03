WITH joined AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_promo_sk,
        ss.ss_sold_time_sk,
        p.p_promo_name,
        p.p_cost,
        p.p_discount_active,
        cc.cc_city,
        hd.hd_vehicle_count,
        td.t_hour,
        td.t_minute,
        td.t_second,
        ca.ca_state,
        sr.sr_return_amt
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE td.t_hour = 14
      AND p.p_discount_active = 'Y'
      AND hd.hd_vehicle_count >= 2
      AND cc.cc_city = 'Antioch'
      AND p.p_cost > (SELECT MIN(p_cost) FROM promotion)
      AND EXISTS (
            SELECT 1
            FROM catalog_sales cs2
            WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
              AND cs2.cs_sold_time_sk = td.t_time_sk
      )
),
aggregated AS (
    SELECT
        ss_promo_sk,
        p_promo_name,
        cc_city,
        t_hour,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss_ticket_number) AS order_cnt,
        AVG(ss_quantity) AS avg_quantity,
        MIN(ss_net_paid) AS min_net_paid,
        MAX(ss_net_paid) AS max_net_paid
    FROM joined
    GROUP BY ss_promo_sk, p_promo_name, cc_city, t_hour
)
SELECT
    a.p_promo_name,
    a.cc_city,
    a.t_hour,
    a.total_net_paid,
    a.order_cnt,
    a.avg_quantity,
    a.min_net_paid,
    a.max_net_paid,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        JOIN store_sales ss2 ON sr2.sr_ticket_number = ss2.ss_ticket_number
        WHERE ss2.ss_promo_sk = a.ss_promo_sk
    ) AS total_return_amt_for_promo,
    ROW_NUMBER() OVER (ORDER BY a.total_net_paid DESC) AS rn
FROM aggregated a
ORDER BY a.total_net_paid DESC
LIMIT 100
