-- goal: Identify top customers by total loss (store + catalog returns) within each income band, focusing on daytime returns shipped by AIR and accessed web pages of type 'article'.
WITH joined AS (
    SELECT
        sr.sr_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss               AS store_net_loss,
        cr.cr_net_loss               AS catalog_net_loss,
        t.t_hour,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_type,
        wp.wp_type
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sr.sr_return_quantity > 5
      AND t.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 100000
      AND sm.sm_type = 'AIR'
      AND wp.wp_type = 'article'
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ib_lower_bound,
    ib_upper_bound,
    sm_type,
    SUM(store_net_loss) + SUM(catalog_net_loss) AS total_loss,
    SUM(sr_return_amt)                     AS total_return_amt,
    RANK() OVER (PARTITION BY ib_lower_bound ORDER BY (SUM(store_net_loss) + SUM(catalog_net_loss)) DESC) AS loss_rank
FROM joined
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    ib_lower_bound,
    ib_upper_bound,
    sm_type
HAVING (SUM(store_net_loss) + SUM(catalog_net_loss)) > 1000
ORDER BY loss_rank, total_loss DESC
LIMIT 100
