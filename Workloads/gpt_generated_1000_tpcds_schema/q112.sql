WITH base AS (
    -- Join all tables using only the permitted join relationships
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d_sales.d_year,
        i.i_category,
        i.i_brand,
        i.i_item_sk,
        cs.cs_net_profit,
        cr.cr_return_amount,
        sr.sr_return_amt,
        p.p_discount_active,
        ib.ib_upper_bound,
        sm.sm_carrier,
        w.w_warehouse_name,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        ws.web_name,
        wp.wp_type
    FROM catalog_sales cs
    JOIN date_dim d_sales               ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales               ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p                    ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca           ON cs.cs_bill_addr_sk = ca.ca_address_sk
    -- Catalog returns linked by order number and item
    JOIN catalog_returns cr            ON cr.cr_order_number = cs.cs_order_number
                                           AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_cr_return           ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    JOIN time_dim t_cr_return           ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
    -- Store returns linked through shared dimensions
    JOIN store_returns sr              ON sr.sr_item_sk = i.i_item_sk
                                           AND sr.sr_cdemo_sk = cd.cd_demo_sk
                                           AND sr.sr_hdemo_sk = hd.hd_demo_sk
                                           AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN date_dim d_sr_return          ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
    JOIN time_dim t_sr_return          ON sr.sr_return_time_sk = t_sr_return.t_time_sk
    JOIN store s                       ON sr.sr_store_sk = s.s_store_sk
    -- Web‑site and web‑page linked via the same sales date (any allowed date_dim join is fine)
    JOIN web_site ws                   ON ws.web_open_date_sk = d_sales.d_date_sk
    JOIN web_page wp                   ON wp.wp_creation_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2001                         -- predicate #1
      AND ca.ca_country = 'United States'              -- predicate #2
      AND sm.sm_carrier = 'FEDEX'                       -- predicate #3
),
aggregated AS (
    SELECT
        s_store_name            AS store_name,
        d_year                  AS year,
        i_category              AS category,
        i_brand                 AS brand,
        i_item_sk               AS item_sk,
        SUM(cs_net_profit)      AS total_net_profit,
        SUM(cr_return_amount + sr_return_amt) AS total_return_amount,
        AVG(CASE WHEN p_discount_active IS NOT NULL THEN 1 ELSE 0 END) AS avg_discount_flag,
        AVG(ib_upper_bound)     AS avg_income_upper
    FROM base
    GROUP BY
        s_store_name,
        d_year,
        i_category,
        i_brand,
        i_item_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS row_num,
    store_name,
    year,
    category,
    brand,
    total_net_profit,
    total_return_amount,
    avg_discount_flag,
    avg_income_upper,
    -- Correlated scalar sub‑query: total sales paid for the same item across the whole catalog
    (SELECT SUM(cs2.cs_net_paid)
       FROM catalog_sales cs2
      WHERE cs2.cs_item_sk = agg.item_sk) AS item_total_paid
FROM aggregated agg
ORDER BY total_net_profit DESC
LIMIT 100
