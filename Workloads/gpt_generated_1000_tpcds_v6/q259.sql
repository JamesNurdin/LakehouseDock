/*
Goal: Identify the top revenue contributors across call centers and stores, categorising net amount levels, while excluding orders that have a catalogue return. The query joins all 15 TPC‑DS tables, applies multiple filters, uses a UNION ALL of two sub‑queries, a NOT EXISTS anti‑join, a CASE expression, a ROLLUP aggregation and window‑function ranking, and returns the first 100 rows.
*/
WITH catalog_data AS (
    SELECT
        cs.cs_sold_date_sk                AS date_sk,
        cs.cs_order_number                AS order_number,
        cs.cs_net_paid                    AS net_paid,
        CAST(NULL AS decimal(7,2))        AS net_loss,
        sm.sm_type                        AS ship_mode_type,
        cc.cc_name                        AS call_center_name,
        CAST(NULL AS varchar)             AS store_id,
        CAST(NULL AS varchar)             AS reason_desc
    FROM catalog_sales cs
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                  ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c                    ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim td                   ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_paid > 100
      AND cc.cc_state = 'CA'
      AND sm.sm_code = 'AIR'
),
store_data AS (
    SELECT
        sr.sr_returned_date_sk           AS date_sk,
        sr.sr_ticket_number              AS order_number,
        CAST(NULL AS decimal(7,2))       AS net_paid,
        sr.sr_net_loss                   AS net_loss,
        CAST(NULL AS varchar)            AS ship_mode_type,
        CAST(NULL AS varchar)            AS call_center_name,
        s.s_store_id                     AS store_id,
        r.r_reason_desc                  AS reason_desc
    FROM store_returns sr
    JOIN time_dim td                      ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c                       ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd         ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd       ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                   ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca              ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s                          ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r                         ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_net_loss > 0
      AND s.s_state = 'TX'
      AND r.r_reason_desc LIKE '%damage%'
),
combined AS (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM store_data
),
pre_agg AS (
    SELECT
        date_sk,
        order_number,
        COALESCE(net_paid, 0) - COALESCE(net_loss, 0)                AS net_amount,
        CASE
            WHEN COALESCE(net_paid, 0) - COALESCE(net_loss, 0) > 1000 THEN 'HIGH'
            WHEN COALESCE(net_paid, 0) - COALESCE(net_loss, 0) > 0    THEN 'MEDIUM'
            ELSE 'LOW'
        END                                                          AS amount_category,
        ship_mode_type,
        call_center_name,
        store_id,
        reason_desc
    FROM combined
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = combined.order_number
    )
)
SELECT
    call_center_name,
    store_id,
    amount_category,
    ship_mode_type,
    SUM(net_amount)                                     AS total_net_amount,
    ROW_NUMBER() OVER (PARTITION BY call_center_name ORDER BY SUM(net_amount) DESC) AS rn,
    RANK()       OVER (PARTITION BY amount_category   ORDER BY SUM(net_amount) DESC) AS amt_rank
FROM pre_agg
GROUP BY ROLLUP (call_center_name, store_id, amount_category, ship_mode_type)
HAVING SUM(net_amount) > 0
ORDER BY total_net_amount DESC
LIMIT 100
