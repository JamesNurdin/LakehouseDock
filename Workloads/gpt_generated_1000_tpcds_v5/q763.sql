WITH base_join AS (
   SELECT
       d.d_year,
       c.c_customer_sk,
       c.c_birth_month,
       cd.cd_gender,
       hd.hd_income_band_sk,
       p.p_promo_id,
       p.p_channel_radio,
       ws.web_site_id,
       ws.web_country,
       cr.cr_net_loss,
       sr.sr_net_loss,
       wp.wp_web_page_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
   JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
   JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND c.c_birth_month = 5
     AND cd.cd_gender = 'M'
     AND hd.hd_income_band_sk > 5
     AND p.p_channel_radio = 'N'
     AND ws.web_country = 'United States'
     AND cr.cr_return_quantity > 0
     AND sr.sr_return_quantity > 0
),
agg1 AS (
   SELECT
       d_year,
       p_promo_id AS key_id,
       SUM(cr_net_loss + sr_net_loss) AS total_net_loss
   FROM base_join
   GROUP BY d_year, p_promo_id
),
agg2 AS (
   SELECT
       d_year,
       web_site_id AS key_id,
       -SUM(cr_net_loss + sr_net_loss) AS total_net_loss
   FROM base_join
   GROUP BY d_year, web_site_id
),
combined AS (
   SELECT * FROM agg1
   UNION ALL
   SELECT * FROM agg2
),
final AS (
   SELECT
       d_year,
       key_id,
       total_net_loss,
       AVG(total_net_loss) OVER (PARTITION BY d_year) AS avg_loss_by_year,
       SUM(total_net_loss) OVER (PARTITION BY d_year ORDER BY key_id
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_loss,
       (SELECT MAX(d_date) FROM date_dim WHERE d_year = 2001) AS max_date_2001
   FROM combined
)
SELECT
   d_year,
   key_id,
   total_net_loss,
   avg_loss_by_year,
   cumulative_loss,
   max_date_2001
FROM final
WHERE avg_loss_by_year > 0
ORDER BY d_year, key_id
LIMIT 100
