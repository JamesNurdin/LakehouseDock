WITH
cr_base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        d.d_year,
        t.t_hour,
        w.w_warehouse_name,
        ib.ib_upper_bound,
        cr.cr_returning_addr_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_return_amount > 500
      AND EXISTS (
          SELECT 1
          FROM customer_address ca
          WHERE ca.ca_address_sk = cr.cr_returning_addr_sk
            AND ca.ca_suite_number LIKE 'Suite%'
      )
),
inventory_full AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        w.w_warehouse_name,
        i.inv_date_sk
    FROM inventory i
    FULL OUTER JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
),
store_agg AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        d.d_year,
        t.t_hour,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = sr.sr_customer_sk
          AND cr2.cr_return_amount > 1000
    )
),
promo_dates AS (
    SELECT
        p.p_promo_sk,
        p.p_start_date_sk,
        p.p_end_date_sk,
        ds.d_year AS start_year,
        de.d_year AS end_year
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN date_dim de ON p.p_end_date_sk = de.d_date_sk
    WHERE p.p_discount_active = 'Y'
),
intersect_keys AS (
    SELECT cr.cr_warehouse_sk AS key_id
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 2000
    INTERSECT
    SELECT sr.sr_store_sk AS key_id
    FROM store_returns sr
    WHERE sr.sr_return_amt > 1500
),
union_returns AS (
    SELECT cr.cr_warehouse_sk AS warehouse_sk, cr.cr_return_amount AS amount, cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 600
    UNION
    SELECT cr.cr_warehouse_sk, cr.cr_return_amount, cr.cr_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 900
)
SELECT
    COALESCE(cb.w_warehouse_name, inv.w_warehouse_name) AS warehouse_name,
    SUM(ur.amount) AS total_return_amount,
    SUM(ur.net_loss) AS total_net_loss,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory,
    COUNT(DISTINCT cb.cr_returned_date_sk) AS distinct_return_dates,
    COUNT(DISTINCT ik.key_id) AS intersect_key_count,
    MIN(p.start_year) AS earliest_promo_start_year,
    MAX(p.end_year) AS latest_promo_end_year
FROM union_returns ur
JOIN cr_base cb ON ur.warehouse_sk = cb.cr_warehouse_sk
LEFT JOIN inventory_full inv ON ur.warehouse_sk = inv.inv_warehouse_sk
LEFT JOIN intersect_keys ik ON ur.warehouse_sk = ik.key_id
LEFT JOIN promo_dates p ON cb.cr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
LEFT JOIN warehouse w ON ur.warehouse_sk = w.w_warehouse_sk
GROUP BY
    COALESCE(cb.w_warehouse_name, inv.w_warehouse_name)
ORDER BY total_return_amount DESC
LIMIT 100
