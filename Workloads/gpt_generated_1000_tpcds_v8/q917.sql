WITH
  sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  ticket_excluding_returns AS (
    SELECT ss_ticket_number
    FROM store_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
  ),
  joined_data AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_addr_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_net_paid,
      ss.ss_net_profit,
      d.d_date,
      d.d_year,
      t.t_hour,
      i.i_product_name,
      i.i_current_price,
      p.p_discount_active,
      ca.ca_city,
      ca.ca_state,
      cd.cd_gender,
      sr.sr_return_amt,
      sr.sr_net_loss,
      r.r_reason_desc,
      wr.wr_return_amt        AS web_return_amt,
      wp.wp_url,
      inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk    = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk    = t.t_time_sk
    JOIN item i                   ON ss.ss_item_sk         = i.i_item_sk
    JOIN promotion p              ON ss.ss_promo_sk        = p.p_promo_sk
    JOIN customer_address ca      ON ss.ss_addr_sk         = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk        = cd.cd_demo_sk
    FULL OUTER JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r                ON sr.sr_reason_sk       = r.r_reason_sk
    LEFT JOIN web_returns wr          ON wr.wr_returned_date_sk = d.d_date_sk
                                         AND wr.wr_item_sk          = i.i_item_sk
    LEFT JOIN web_page wp             ON wr.wr_web_page_sk      = wp.wp_web_page_sk
    LEFT JOIN sampled_inventory inv   ON inv.inv_item_sk        = i.i_item_sk
                                         AND inv.inv_date_sk        = d.d_date_sk
    WHERE d.d_year = 2002
      AND i.i_current_price > 50
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
  )
SELECT DISTINCT
  jd.d_date,
  jd.i_product_name,
  jd.ca_city,
  jd.cd_gender,
  jd.r_reason_desc,
  jd.wp_url,
  jd.inv_quantity_on_hand,
  jd.ss_quantity,
  jd.ss_sales_price,
  jd.ss_net_paid,
  jd.ss_net_profit,
  jd.sr_return_amt,
  jd.web_return_amt,
  SUM(jd.ss_net_paid) OVER (PARTITION BY jd.ca_city ORDER BY jd.d_date
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_city_net_paid,
  RANK() OVER (PARTITION BY jd.ca_city ORDER BY jd.ss_net_profit DESC) AS profit_rank,
  LAG(jd.ss_net_paid, 1) OVER (PARTITION BY jd.ca_city ORDER BY jd.d_date) AS prev_day_net_paid
FROM joined_data jd
WHERE jd.ss_ticket_number IN (SELECT ss_ticket_number FROM ticket_excluding_returns)
ORDER BY jd.d_date ASC
OFFSET 0 LIMIT 100
