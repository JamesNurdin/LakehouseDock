WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        d.d_date,
        d.d_year,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_state,
        cc.cc_hours,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid_inc_tax,
        ws.ws_quantity AS ws_quantity,
        ws.ws_sales_price AS ws_sales_price,
        wp.wp_url,
        we.web_name,
        -- expand the dash‑separated hours string into separate rows
        hour_part
    FROM sampled_sales ss
    INNER JOIN date_dim d                ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim t                ON ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
    -- join the catalog return to bring in call_center
    INNER JOIN catalog_returns cr        ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN call_center cc            ON cr.cr_call_center_sk = cc.cc_call_center_sk
    -- join web sales and its related dimensions
    INNER JOIN web_sales ws              ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site we               ON ws.ws_web_site_sk = we.web_site_sk
    -- unnest the hours string (e.g., '9-5')
    LEFT JOIN LATERAL (
        SELECT value AS hour_part
        FROM UNNEST(split(cc.cc_hours, '-')) AS t(value)
    ) AS u ON true
    WHERE d.d_year = 2001
      AND i.i_brand = 'BrandX'
      AND ca.ca_state IN ('CA','TX','NY')
      AND ss.ss_quantity > 5
      AND ss.ss_sales_price > 100
),
first_set AS (
    SELECT
        d_date,
        d_year,
        i_brand,
        ca_state,
        hour_part,
        SUM(ss_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS state_rank
    FROM joined_data
    WHERE cd_marital_status = 'M'
      AND hd_buy_potential = '>10000'
    GROUP BY d_date, d_year, i_brand, ca_state, hour_part
    HAVING SUM(ss_net_paid_inc_tax) > 1000
),
second_set AS (
    SELECT
        d_date,
        d_year,
        i_brand,
        ca_state,
        hour_part,
        SUM(ss_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS state_rank
    FROM joined_data
    WHERE cd_marital_status = 'S'
      AND hd_buy_potential = '0-500'
    GROUP BY d_date, d_year, i_brand, ca_state, hour_part
    HAVING SUM(ss_net_paid_inc_tax) > 1000
)
SELECT *
FROM (
    SELECT * FROM first_set
    UNION DISTINCT
    SELECT * FROM second_set
) AS combined
ORDER BY state_rank, total_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
