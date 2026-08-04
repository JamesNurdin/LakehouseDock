WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_tax,
        ws.ws_ext_ship_cost,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        sm.sm_type,
        p.p_discount_active,
        w.web_country,
        w.web_name,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        s.s_store_name,
        inv.inv_quantity_on_hand,
        td.t_time,
        td.t_hour
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
),
full_demo_income AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    FULL OUTER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
joined_full AS (
    SELECT
        b.*,
        fdi.ib_lower_bound AS fd_ib_lower,
        fdi.ib_upper_bound AS fd_ib_upper
    FROM base b
    LEFT JOIN full_demo_income fdi
        ON b.hd_demo_sk = fdi.hd_demo_sk
),
lateral_agg AS (
    SELECT
        jf.*, 
        lc.total_orders_per_item
    FROM joined_full jf
    CROSS JOIN LATERAL (
        SELECT COUNT(DISTINCT ws2.ws_order_number) AS total_orders_per_item
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = jf.ws_item_sk
    ) lc
),
filtered AS (
    SELECT *
    FROM lateral_agg
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2451921               -- predicate 1 (sample surrogate date key range)
      AND fd_ib_upper >= 50000                                      -- predicate 2
      AND sm_type = 'AIR'                                           -- predicate 3
      AND web_country = 'United States'                             -- predicate 4
),
anti AS (
    SELECT *
    FROM filtered f
    WHERE f.ws_order_number NOT IN (
        SELECT DISTINCT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_return_amt > 1000
    )
)
SELECT
    i_category,
    i_brand,
    sm_type,
    fd_ib_lower,
    fd_ib_upper,
    SUM(ws_net_paid) AS total_net_paid,
    AVG(ws_ext_tax) AS avg_tax,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    MAX(total_orders_per_item) AS max_orders_per_item
FROM anti
GROUP BY GROUPING SETS (
    (i_category, i_brand, sm_type, fd_ib_lower, fd_ib_upper),
    (i_category, i_brand, sm_type),
    (i_category, i_brand),
    ()
)
HAVING SUM(ws_net_paid) > 1000
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH FIRST 20 ROWS ONLY
