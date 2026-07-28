WITH
  store_ret_agg AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_reason_sk,
      SUM(sr.sr_net_loss) AS total_store_loss,
      COUNT(*) AS cnt_store_returns
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    WHERE sr.sr_return_ship_cost > 10
      AND d_sr.d_year = 2001
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk
  ),
  web_ret_agg AS (
    SELECT
      wr.wr_web_page_sk,
      SUM(wr.wr_net_loss) AS total_web_loss,
      COUNT(*) AS cnt_web_returns
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE wr.wr_return_amt > 20
      AND d_wr.d_year = 2001
    GROUP BY wr.wr_web_page_sk
  )
SELECT
  s.s_store_name,
  r.r_reason_desc,
  sr_agg.total_store_loss,
  sr_agg.cnt_store_returns,
  wp.wp_url,
  wp.wp_type,
  cp.cp_description,
  p.p_promo_name,
  cc.cc_name,
  d_store.d_year AS store_closed_year,
  ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY sr_agg.total_store_loss DESC) AS store_loss_rank,
  CASE
    WHEN sr_agg.total_store_loss > 5000 THEN 'High'
    ELSE 'Low'
  END AS loss_category
FROM store_ret_agg sr_agg
JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
JOIN reason r ON sr_agg.sr_reason_sk = r.r_reason_sk
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_store.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d_store.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_store.d_date_sk
JOIN web_ret_agg wr_agg ON 1 = 1
JOIN web_page wp ON wr_agg.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer cu ON wp.wp_customer_sk = cu.c_customer_sk
JOIN customer_address ca ON cu.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cu.c_current_hdemo_sk = hd.hd_demo_sk
WHERE d_store.d_year = 2001
  AND cc.cc_name LIKE '%Center%'
  AND cp.cp_type = 'general'
  AND p.p_discount_active = 'Y'
  AND cu.c_preferred_cust_flag = 'Y'
ORDER BY sr_agg.total_store_loss DESC
LIMIT 100
