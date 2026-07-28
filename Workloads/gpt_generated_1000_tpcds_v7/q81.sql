/*
  Goal: Compare total return amounts and net losses of stores for the year 2001, incorporating both store and web returns, and rank stores by total net loss while categorising return volume.
*/
WITH joined_data AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ca.ca_state,
        hd.hd_income_band_sk,
        p.p_discount_active
    FROM store_returns sr
    JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t               ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s                  ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca      ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr      ON sr.sr_customer_sk = wr.wr_refunded_customer_sk
                                   AND sr.sr_returned_date_sk = wr.wr_returned_date_sk
    LEFT JOIN web_page wp         ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws          ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN call_center cc       ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN promotion p          ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_state IN ('CA', 'TX')
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND s.s_store_name LIKE '%Store%'
      AND p.p_discount_active = 'Y'
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    d_year,
    SUM(COALESCE(sr_return_amt, 0))        AS store_return_amt,
    SUM(COALESCE(wr_return_amt, 0))        AS web_return_amt,
    SUM(COALESCE(sr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_net_loss,
    RANK() OVER (ORDER BY SUM(COALESCE(sr_net_loss, 0) + COALESCE(wr_net_loss, 0)) DESC) AS net_loss_rank,
    CASE WHEN SUM(COALESCE(sr_return_amt, 0)) > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_volume_category
FROM joined_data
GROUP BY
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    d_year
ORDER BY total_net_loss DESC
LIMIT 100
