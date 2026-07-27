WITH sr AS (
        SELECT sr.sr_store_sk,
               sr.sr_returned_date_sk,
               sr.sr_return_time_sk,
               sr.sr_customer_sk,
               sr.sr_cdemo_sk,
               sr.sr_net_loss,
               sr.sr_return_quantity,
               sr.sr_return_amt
        FROM store_returns sr
    ),
    wr AS (
        SELECT wr.wr_returned_date_sk,
               wr.wr_returned_time_sk,
               wr.wr_refunded_customer_sk,
               wr.wr_refunded_cdemo_sk,
               wr.wr_web_page_sk,
               wr.wr_net_loss,
               wr.wr_return_quantity,
               wr.wr_return_amt
        FROM web_returns wr
    )
SELECT
    d.d_year,
    s.s_store_name,
    cd.cd_gender,
    c.c_first_name,
    c.c_last_name,
    p.p_promo_name,
    inv.inv_quantity_on_hand,
    wp.wp_url,
    ws.web_name,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) DESC) AS loss_rank
FROM date_dim d
LEFT JOIN sr ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN store s ON s.s_store_sk = sr.sr_store_sk
LEFT JOIN customer c ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = sr.sr_cdemo_sk
LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
LEFT JOIN wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN time_dim t ON t.t_time_sk = sr.sr_return_time_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND c.c_preferred_cust_flag = 'Y'
  AND p.p_discount_active = 'Y'
  AND inv.inv_quantity_on_hand > 0
  AND t.t_meal_time = 'lunch'
GROUP BY
    d.d_year,
    s.s_store_name,
    cd.cd_gender,
    c.c_first_name,
    c.c_last_name,
    p.p_promo_name,
    inv.inv_quantity_on_hand,
    wp.wp_url,
    ws.web_name
ORDER BY total_net_loss DESC
LIMIT 100
