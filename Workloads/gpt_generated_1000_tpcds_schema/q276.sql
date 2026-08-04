WITH promo_intersect AS (
    SELECT p.p_promo_id
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    WHERE d_start.d_year = 2001
    INTERSECT
    SELECT p2.p_promo_id
    FROM promotion p2
    JOIN date_dim d_end ON p2.p_end_date_sk = d_end.d_date_sk
    WHERE d_end.d_year = 2002
)
SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    w.w_warehouse_name,
    d_sold.d_date AS sold_date,
    sm.sm_type,
    p.p_promo_name,
    channel,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    (
        SELECT SUM(ss_inner.ss_net_paid)
        FROM store_sales ss_inner
        WHERE ss_inner.ss_customer_sk = cs.cs_bill_customer_sk
    ) AS total_customer_store_paid
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel)
WHERE d_ss.d_year = 2001
  AND cd_ss.cd_marital_status = 'M'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND p.p_promo_id IN (SELECT p_promo_id FROM promo_intersect)
ORDER BY cs.cs_net_profit DESC
LIMIT 100
