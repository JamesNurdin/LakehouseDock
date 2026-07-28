WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_hdemo_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_net_loss,
        d.d_year,
        i.i_item_id,
        i.i_brand,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        s.s_store_name,
        s.s_state,
        w.w_warehouse_name,
        w.w_state,
        inv.inv_quantity_on_hand,
        wp.wp_url
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'BrandX'
      AND c.c_salutation = 'Mr.'
      AND ib.ib_lower_bound >= 30000
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%price%'
), agg AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        d_year,
        SUM(sr_net_loss) AS total_net_loss
    FROM base
    GROUP BY c_customer_id, c_first_name, c_last_name, d_year
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year,
    total_net_loss,
    CASE WHEN total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS year_rank
FROM agg
ORDER BY d_year, year_rank
LIMIT 100
