WITH sales_by_store AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_paid)   AS store_net_paid,
        SUM(ss_net_profit) AS store_net_profit
    FROM store_sales
    GROUP BY ss_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_vehicle_count,
    ca.ca_city,
    SUM(ss.ss_net_paid)   AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    sbs.store_net_profit   AS store_total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    AND cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN sales_by_store sbs ON sbs.ss_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
  AND p.p_channel_catalog = 'N'
  AND ca.ca_state = 'CA'
  AND hd.hd_income_band_sk BETWEEN 8 AND 15
  AND cp.cp_department = 'Electronics'
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
  AND EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = cr.cr_reason_sk
          AND r.r_reason_desc LIKE '%damage%'
    )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_vehicle_count,
    ca.ca_city,
    sbs.store_net_profit
ORDER BY total_net_profit DESC, profit_rank
LIMIT 100
