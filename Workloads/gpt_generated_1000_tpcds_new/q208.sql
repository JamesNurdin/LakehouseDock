/*
  Goal: Identify the top‑performing stores (by total return amount) for each year, limited to stores that satisfy two independent criteria – (a) located in CA with customers born in July, and (b) have inventory on hand > 100 for items whose customers have a college education. The query joins all 11 selected TPC‑DS tables using only the allowed join keys, applies four filter predicates, uses a windowed RANK, and intersects the two store‑sets with INTERSECT.
*/
WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_fee,
        sr.sr_net_loss,
        c.c_customer_sk,
        c.c_birth_month,
        cd.cd_demo_sk,
        cd.cd_education_status,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        d.d_date_sk,
        d.d_year,
        t.t_time_sk,
        t.t_hour,
        inv.inv_date_sk,
        inv.inv_quantity_on_hand,
        w.w_warehouse_sk,
        w.w_city AS warehouse_city,
        cc.cc_call_center_sk,
        cc.cc_gmt_offset,
        ws.web_site_sk,
        ws.web_name
    FROM store_returns sr
    JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t               ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s                  ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN inventory inv       ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w         ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN call_center cc      ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN web_site ws         ON ws.web_open_date_sk = d.d_date_sk
),
filtered_stores AS (
    SELECT s_store_sk
    FROM base
    WHERE s_state = 'CA' AND c_birth_month = 7
    INTERSECT
    SELECT s_store_sk
    FROM base
    WHERE inv_quantity_on_hand > 100 AND cd_education_status = 'College'
)
SELECT
    b.s_store_name,
    b.s_store_sk,
    b.d_year,
    SUM(b.sr_return_amt)                         AS total_return_amt,
    RANK() OVER (PARTITION BY b.d_year ORDER BY SUM(b.sr_return_amt) DESC) AS store_rank,
    CASE
        WHEN b.cc_gmt_offset BETWEEN -5 AND 5 THEN 'Standard GMT'
        ELSE 'Other GMT'
    END                                         AS gmt_category
FROM base b
JOIN filtered_stores f ON b.s_store_sk = f.s_store_sk
WHERE b.d_year BETWEEN 2000 AND 2002          -- filter predicate 1
  AND b.s_state = 'CA'                         -- filter predicate 2
  AND b.c_birth_month = 7                      -- filter predicate 3
  AND b.inv_quantity_on_hand > 100            -- filter predicate 4
GROUP BY
    b.s_store_name,
    b.s_store_sk,
    b.d_year,
    b.cc_gmt_offset,
    b.s_state,
    b.c_birth_month,
    b.inv_quantity_on_hand
ORDER BY b.d_year DESC, total_return_amt DESC
LIMIT 100
