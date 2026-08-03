WITH ss_agg AS (
    SELECT
        ss.ss_promo_sk,
        ss.ss_addr_sk,
        ss.ss_hdemo_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
      AND ss.ss_net_paid > 0
    GROUP BY ss.ss_promo_sk, ss.ss_addr_sk, ss.ss_hdemo_sk
)
SELECT
    ca.ca_state,
    ca.ca_city,
    ca.ca_location_type,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    p.p_promo_name,
    ss_agg.total_sales,
    ss_agg.total_net_paid,
    ss_agg.sales_cnt,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY ss_agg.total_net_paid DESC) AS state_sales_rank
FROM ss_agg
JOIN promotion p
    ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca
    ON ss_agg.ss_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 2
  AND hd.hd_dep_count <= 6
  AND ca.ca_location_type = 'single family'
  AND ca.ca_state IN ('CA','NY','TX')
  AND p.p_discount_active = 'Y'
  AND p.p_channel_tv = 'Y'
  AND ss_agg.total_sales > 5000
  AND ss_agg.sales_cnt >= 5
  AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_promo_sk = ss_agg.ss_promo_sk
          AND ws.ws_bill_addr_sk = ss_agg.ss_addr_sk
          AND ws.ws_quantity > 2
    )
ORDER BY ca.ca_state, state_sales_rank, ss_agg.total_sales DESC
LIMIT 100
