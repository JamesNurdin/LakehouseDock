WITH all_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_customer_sk AS customer_sk,
        d.d_year,
        i.i_category,
        i.i_brand,
        ca.ca_state,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_code,
        cc.cc_name,
        p.p_promo_name,
        cu.c_birth_country,
        wp.wp_url,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer cu ON ss.ss_customer_sk = cu.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = cu.c_customer_sk
    LEFT JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ca.ca_state IN ('CA', 'TX', 'NY', 'WA')
      AND sm.sm_code = 'AIR'
      AND ib.ib_upper_bound > 50000
),
agg_data AS (
    SELECT
        d_year,
        i_category,
        SUM(ss_net_paid)                                 AS total_net_paid,
        SUM(COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) AS total_returns,
        AVG(ss_net_profit)                               AS avg_net_profit,
        COUNT(DISTINCT customer_sk)                      AS unique_customers,
        MIN(customer_sk)                                 AS sample_customer_sk
    FROM all_data
    GROUP BY d_year, i_category
),
high_low_categories AS (
    SELECT DISTINCT i_category FROM agg_data WHERE avg_net_profit > 1000
    UNION
    SELECT DISTINCT i_category FROM agg_data WHERE avg_net_profit < 100
)
SELECT
    ad.d_year,
    ad.i_category,
    ad.total_net_paid,
    ad.total_returns,
    ad.avg_net_profit,
    ad.unique_customers,
    RANK() OVER (PARTITION BY ad.d_year ORDER BY ad.total_net_paid DESC)                AS category_rank,
    SUM(ad.total_net_paid) OVER (PARTITION BY ad.d_year)                               AS year_total_net_paid
FROM agg_data ad
WHERE ad.i_category IN (SELECT i_category FROM high_low_categories)
  AND NOT EXISTS (
        SELECT 1 FROM store_returns sr WHERE sr.sr_customer_sk = ad.sample_customer_sk
    )
ORDER BY ad.total_net_paid DESC
LIMIT 100
