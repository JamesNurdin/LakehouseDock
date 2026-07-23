WITH base_sales AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_store_sk,
    ss.ss_promo_sk,
    ss.ss_net_profit AS ss_net_profit,
    sr.sr_net_loss AS sr_net_loss,
    cr.cr_net_loss AS cr_net_loss,
    wr.wr_net_loss AS wr_net_loss,
    d_sales.d_year AS d_year,
    i.i_brand AS i_brand,
    i.i_category AS i_category,
    s.s_store_name AS s_store_name,
    c.c_customer_id AS c_customer_id,
    cd.cd_gender AS cd_gender,
    hd.hd_income_band_sk AS hd_income_band_sk,
    p.p_promo_name AS p_promo_name,
    sm.sm_type AS sm_type,
    r_sr.r_reason_desc AS store_return_reason,
    r_cr.r_reason_desc AS catalog_return_reason,
    r_wr.r_reason_desc AS web_return_reason,
    wp.wp_url AS wp_url,
    wp.wp_type AS wp_type
  FROM store_sales ss
  INNER JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
  INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
  INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
  INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
  LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
  LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
  LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
  LEFT JOIN customer c_wp ON wp.wp_customer_sk = c_wp.c_customer_sk
  LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
  LEFT JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
  LEFT JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
  WHERE i.i_manager_id > 20
    AND d_sales.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    AND i.i_formulation LIKE '%papaya%'
),
aggregated AS (
  SELECT
    d_year AS year,
    i_brand AS brand,
    i_category AS category,
    s_store_name AS store_name,
    sm_type AS ship_type,
    SUM(ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(sr_net_loss, 0) + COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT c_customer_id) AS distinct_customers
  FROM base_sales
  GROUP BY d_year, i_brand, i_category, s_store_name, sm_type
)
SELECT
  year,
  brand,
  category,
  store_name,
  total_sales_profit,
  total_return_loss,
  distinct_customers
FROM (
  SELECT
    year,
    brand,
    category,
    store_name,
    total_sales_profit,
    total_return_loss,
    distinct_customers
  FROM aggregated
  WHERE ship_type IS NULL

  UNION ALL

  SELECT
    year,
    brand,
    category,
    store_name,
    -total_sales_profit AS total_sales_profit,
    total_return_loss,
    distinct_customers
  FROM aggregated
  WHERE ship_type = 'Air'
) final_result
ORDER BY total_return_loss DESC
LIMIT 100
