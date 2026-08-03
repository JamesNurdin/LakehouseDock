WITH all_data AS (
   SELECT
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      c.c_birth_country,
      ws.ws_net_paid,
      ws.ws_sold_date_sk,
      sr.sr_net_loss,
      cr.cr_net_loss,
      p.p_promo_name,
      p.p_channel_tv,
      sm.sm_type,
      cp.cp_department,
      cp.cp_description,
      r.r_reason_desc,
      ib.ib_lower_bound,
      wsite.web_state,
      wsite.web_name
   FROM customer c
   FULL OUTER JOIN web_page wp
        ON c.c_customer_sk = wp.wp_customer_sk
   INNER JOIN web_sales ws
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
   INNER JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
   INNER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
   INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   INNER JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
   INNER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
   INNER JOIN catalog_returns cr
        ON cr.cr_returning_customer_sk = c.c_customer_sk
   INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   INNER JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
   INNER JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
   INNER JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
   INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
   c_customer_id,
   c_first_name,
   c_last_name,
   ws_net_paid,
   sr_net_loss,
   cr_net_loss,
   (sr_net_loss + cr_net_loss) AS total_loss,
   ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY (sr_net_loss + cr_net_loss) DESC) AS loss_rank,
   p_promo_name,
   cp_description,
   r_reason_desc,
   sm_type,
   ib_lower_bound,
   web_name
FROM all_data
WHERE c_birth_country IN ('PHILIPPINES', 'SWITZERLAND')
  AND p_channel_tv = 'N'
  AND sm_type = 'AIR'
  AND cp_department = 'Electronics'
  AND web_state = 'CA'
  AND ib_lower_bound >= 50000
UNION DISTINCT
SELECT
   c_customer_id,
   c_first_name,
   c_last_name,
   ws_net_paid,
   sr_net_loss,
   cr_net_loss,
   (sr_net_loss + cr_net_loss) AS total_loss,
   ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY (sr_net_loss + cr_net_loss) DESC) AS loss_rank,
   p_promo_name,
   cp_description,
   r_reason_desc,
   sm_type,
   ib_lower_bound,
   web_name
FROM all_data
WHERE c_birth_country NOT IN ('PHILIPPINES', 'SWITZERLAND')
  AND p_channel_tv = 'N'
  AND sm_type = 'AIR'
  AND cp_department = 'Electronics'
  AND web_state = 'CA'
  AND ib_lower_bound >= 50000
ORDER BY total_loss DESC, loss_rank ASC
LIMIT 100
