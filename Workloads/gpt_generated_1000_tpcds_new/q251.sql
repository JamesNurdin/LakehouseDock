/* goal: Identify high‑value ship‑mode and manufacturer combinations by aggregating web sales, filtering on several dimension attributes, comparing total discounts to a global benchmark, and enriching each group with the count of promotions that share the same promotion name. */
WITH base AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_code,
        i.i_manufact,
        i.i_units,
        p.p_promo_name,
        p.p_discount_active,
        ws.ws_ext_discount_amt,
        ws.ws_coupon_amt,
        ws.ws_net_paid_inc_ship_tax
    FROM web_sales ws
    RIGHT OUTER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE sm.sm_code IN ('AIR', 'SEA', 'SURFACE', 'BIKE')
      AND i.i_units = 'Pallet'
      AND p.p_discount_active = 'Y'
      AND i.i_manufact LIKE '%callyable%'
),
agg AS (
    SELECT
        sm_ship_mode_id,
        i_manufact,
        p_promo_name,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_paid_inc_ship_tax) AS total_net,
        COUNT(*) AS sales_cnt
    FROM base
    GROUP BY sm_ship_mode_id, i_manufact, p_promo_name
)
SELECT
    a.sm_ship_mode_id,
    a.i_manufact,
    a.p_promo_name,
    a.total_discount,
    a.total_net,
    a.sales_cnt,
    lc.promo_cnt
FROM agg a
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS promo_cnt
    FROM promotion p
    WHERE p.p_promo_name = a.p_promo_name
) lc ON TRUE
WHERE a.total_discount > (
        SELECT SUM(ws3.ws_ext_discount_amt)
        FROM web_sales ws3
        WHERE ws3.ws_ship_date_sk = 2451545
    )
  AND a.total_net / NULLIF(a.sales_cnt, 1) > (
        SELECT AVG(ws4.ws_ext_discount_amt)
        FROM web_sales ws4
    )
  AND a.sales_cnt > 10
  AND a.total_discount > 1000
  AND a.total_net > 5000
ORDER BY a.total_net DESC
LIMIT 100
