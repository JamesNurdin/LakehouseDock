WITH sales_returns AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_addr_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_ship_mode_sk
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
),
sales_promo AS (
    SELECT
        sr.*,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_details,
        p.p_discount_active,
        sm.sm_ship_mode_id,
        ca.ca_state
    FROM sales_returns sr
    LEFT JOIN promotion p
        ON sr.cs_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
        ON COALESCE(sr.cs_ship_mode_sk, sr.cr_ship_mode_sk) = sm.sm_ship_mode_sk
    LEFT JOIN customer_address ca
        ON sr.cs_bill_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_details IS NOT NULL
),
unnested AS (
    SELECT
        sp.*,
        TRIM(channel) AS channel
    FROM sales_promo sp
    CROSS JOIN UNNEST(SPLIT(sp.p_channel_details, ',')) AS t(channel)
)
SELECT
    promo_id,
    ship_mode_id,
    net_amount,
    discount_promo_cnt,
    promo_status,
    CONCAT(promo_id, '-', ship_mode_id) AS promo_ship_key,
    SUBSTRING(promo_name, 1, 10) AS promo_name_prefix,
    REGEXP_EXTRACT(promo_name, '(\\d+)', 1) AS promo_number_extracted,
    SUM(net_amount) OVER (PARTITION BY promo_id ORDER BY min_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_amount
FROM (
    SELECT
        COALESCE(p_promo_id, 'ALL_PROMOS') AS promo_id,
        COALESCE(sm_ship_mode_id, 'ALL_SHIP_MODES') AS ship_mode_id,
        MIN(cs_sold_date_sk) AS min_sold_date_sk,
        SUM(COALESCE(cs_net_paid, 0) - COALESCE(cr_return_amount, 0)) AS net_amount,
        SUM(CASE WHEN REGEXP_LIKE(p_promo_name, 'Discount') THEN 1 ELSE 0 END) AS discount_promo_cnt,
        CASE WHEN MAX(p_discount_active) = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        MAX(p_promo_name) AS promo_name
    FROM unnested
    WHERE ca_state LIKE 'A%'
      AND REGEXP_LIKE(p_promo_name, '^.*Discount.*$')
    GROUP BY ROLLUP(p_promo_id, sm_ship_mode_id)
    HAVING SUM(COALESCE(cs_net_paid, 0) - COALESCE(cr_return_amount, 0)) > 10000
) t
ORDER BY net_amount DESC
LIMIT 100
