WITH filtered_store AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_wholesale_cost,
        ss.ss_ext_tax,
        ss.ss_net_paid,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        t.t_time_sk,
        t.t_hour,
        t.t_minute,
        t.t_second,
        p.p_promo_sk,
        p.p_channel_catalog,
        p.p_channel_email,
        p.p_discount_active
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE
        ss.ss_ext_tax > 20.00
        AND ss.ss_wholesale_cost BETWEEN 30.00 AND 60.00
        AND hd.hd_vehicle_count >= 2
        AND t.t_minute IN (0, 6, 8, 16)
)
SELECT
    filtered_store.p_promo_sk,
    filtered_store.p_channel_catalog,
    filtered_store.t_hour,
    filtered_store.hd_buy_potential,
    SUM(filtered_store.ss_net_paid) AS total_store_net_paid,
    AVG(cs.cs_sales_price) AS avg_catalog_sales_price,
    COUNT(DISTINCT filtered_store.ss_ticket_number) AS distinct_tickets,
    MIN(filtered_store.ss_ext_tax) AS min_store_tax,
    MAX(cs.cs_ext_discount_amt) AS max_catalog_discount,
    (
        SELECT MAX(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_promo_sk = filtered_store.p_promo_sk
    ) AS max_catalog_ext_sales_for_promo
FROM filtered_store
LEFT JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = filtered_store.t_time_sk
    AND cs.cs_promo_sk = filtered_store.p_promo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs_sub
    WHERE cs_sub.cs_promo_sk = filtered_store.p_promo_sk
      AND cs_sub.cs_quantity > 5
)
GROUP BY
    filtered_store.p_promo_sk,
    filtered_store.p_channel_catalog,
    filtered_store.t_hour,
    filtered_store.hd_buy_potential
HAVING
    SUM(filtered_store.ss_net_paid) > 10000
    AND COUNT(DISTINCT filtered_store.ss_ticket_number) >= 5
ORDER BY total_store_net_paid DESC
