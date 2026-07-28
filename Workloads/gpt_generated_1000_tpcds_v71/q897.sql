WITH cat_detail AS (
    SELECT
        cr.cr_reason_sk,
        cr.cr_ship_mode_sk,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS cat_dist_customers
    FROM catalog_returns cr
    GROUP BY cr.cr_reason_sk,
             cr.cr_ship_mode_sk,
             cr.cr_returned_date_sk,
             cr.cr_returned_time_sk,
             cr.cr_refunded_customer_sk,
             cr.cr_refunded_addr_sk
),
store_detail AS (
    SELECT
        sr.sr_reason_sk,
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(DISTINCT sr.sr_customer_sk) AS store_dist_customers
    FROM store_returns sr
    JOIN store_sales ss
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    GROUP BY sr.sr_reason_sk,
             sr.sr_store_sk,
             sr.sr_returned_date_sk
),
web_detail AS (
    SELECT
        wr.wr_reason_sk,
        wr.wr_returned_date_sk,
        wr.wr_web_page_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT wr.wr_refunded_customer_sk) AS web_dist_customers
    FROM web_returns wr
    GROUP BY wr.wr_reason_sk,
             wr.wr_returned_date_sk,
             wr.wr_web_page_sk
)
SELECT DISTINCT
    r.r_reason_desc,
    sm.sm_type,
    d_cat.d_year,
    cdemo_ref.cd_gender,
    hdemo_ref.hd_vehicle_count,
    cd.cat_net_loss,
    COALESCE(sd.store_net_loss, 0) AS store_net_loss,
    COALESCE(wd.web_net_loss, 0) AS web_net_loss,
    (cd.cat_net_loss + COALESCE(sd.store_net_loss, 0) + COALESCE(wd.web_net_loss, 0)) AS total_loss,
    CASE
        WHEN (cd.cat_net_loss + COALESCE(sd.store_net_loss, 0) + COALESCE(wd.web_net_loss, 0)) > 10000 THEN 'High'
        ELSE 'Low'
    END AS loss_category,
    cd.cat_dist_customers,
    sd.store_dist_customers,
    wd.web_dist_customers,
    (SELECT AVG(cr2.cr_net_loss)
       FROM catalog_returns cr2
       WHERE cr2.cr_reason_sk = cd.cr_reason_sk) AS avg_cat_loss_per_reason,
    (SELECT MAX(ss2.ss_ext_sales_price)
       FROM store_sales ss2
       WHERE ss2.ss_sold_date_sk = d_store.d_date_sk) AS max_sales_price_on_store_date
FROM cat_detail cd
JOIN date_dim d_cat
  ON cd.cr_returned_date_sk = d_cat.d_date_sk
JOIN time_dim t_cat
  ON cd.cr_returned_time_sk = t_cat.t_time_sk
JOIN reason r
  ON cd.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
  ON cd.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c_ref
  ON cd.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_address ca_ref
  ON cd.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cdemo_ref
  ON c_ref.c_current_cdemo_sk = cdemo_ref.cd_demo_sk
JOIN household_demographics hdemo_ref
  ON c_ref.c_current_hdemo_sk = hdemo_ref.hd_demo_sk
LEFT JOIN store_detail sd
  ON cd.cr_reason_sk = sd.sr_reason_sk
LEFT JOIN date_dim d_store
  ON sd.sr_returned_date_sk = d_store.d_date_sk
LEFT JOIN store s
  ON sd.sr_store_sk = s.s_store_sk
LEFT JOIN web_detail wd
  ON cd.cr_reason_sk = wd.wr_reason_sk
LEFT JOIN date_dim d_web
  ON wd.wr_returned_date_sk = d_web.d_date_sk
LEFT JOIN web_page wp
  ON wd.wr_web_page_sk = wp.wp_web_page_sk
ORDER BY total_loss DESC
LIMIT 100
