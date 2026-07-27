WITH enriched_returns AS (
  SELECT
    wr.wr_returned_date_sk,
    d.d_year,
    t.t_sub_shift,
    wr.wr_refunded_customer_sk,
    cr.c_first_name,
    cr.c_last_name,
    cr.c_preferred_cust_flag,
    ca.ca_country            AS refunded_country,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_net_loss,
    r.r_reason_desc,
    wp.wp_url,
    inv.inv_quantity_on_hand,
    wh.w_warehouse_name,
    p_start.p_promo_name    AS promo_start_name,
    p_end.p_promo_name      AS promo_end_name,
    ws.web_name,
    s.s_store_name,
    d_creation.d_month_seq  AS page_creation_month_seq,
    d_access.d_month_seq    AS page_access_month_seq,
    cr_ret.c_customer_sk    AS returning_customer_sk
  FROM web_returns wr
  JOIN date_dim d               ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN time_dim t               ON wr.wr_returned_time_sk = t.t_time_sk
  JOIN customer cr              ON wr.wr_refunded_customer_sk = cr.c_customer_sk
  JOIN customer_address ca      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN reason r                 ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_page wp              ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN inventory inv            ON d.d_date_sk = inv.inv_date_sk
  JOIN warehouse wh             ON inv.inv_warehouse_sk = wh.w_warehouse_sk
  JOIN promotion p_start        ON p_start.p_start_date_sk = d.d_date_sk
  JOIN promotion p_end          ON p_end.p_end_date_sk = d.d_date_sk
  JOIN web_site ws              ON ws.web_open_date_sk = d.d_date_sk
  JOIN store s                  ON s.s_closed_date_sk = d.d_date_sk
  JOIN date_dim d_creation      ON wp.wp_creation_date_sk = d_creation.d_date_sk
  JOIN date_dim d_access        ON wp.wp_access_date_sk = d_access.d_date_sk
  JOIN customer cr_ret          ON wr.wr_returning_customer_sk = cr_ret.c_customer_sk
)
SELECT
  er.refunded_country,
  er.cd_gender,
  er.hd_income_band_sk,
  er.d_year,
  er.promo_start_name,
  er.promo_end_name,
  er.web_name,
  SUM(er.wr_return_amt)                     AS total_return_amount,
  SUM(er.wr_return_quantity)               AS total_return_quantity,
  AVG(er.wr_return_tax)                    AS avg_return_tax,
  COUNT(DISTINCT er.wr_refunded_customer_sk) AS distinct_refunded_customers,
  SUM(SUM(er.wr_return_amt)) OVER (PARTITION BY er.refunded_country ORDER BY er.d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_return_by_country,
  RANK() OVER (PARTITION BY er.refunded_country ORDER BY SUM(er.wr_return_amt) DESC) AS country_return_rank
FROM enriched_returns er
GROUP BY
  er.refunded_country,
  er.cd_gender,
  er.hd_income_band_sk,
  er.d_year,
  er.promo_start_name,
  er.promo_end_name,
  er.web_name
ORDER BY total_return_amount DESC
LIMIT 100
