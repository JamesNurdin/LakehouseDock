WITH
  sales_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      i.i_category,
      i.i_brand,
      i.i_color,
      i.i_item_id,
      c.c_customer_sk,
      c.c_birth_year,
      cd.cd_gender,
      sm.sm_type,
      wp.wp_char_count,
      d_sold.d_year,
      t_sales.t_hour
    FROM web_sales ws
    INNER JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    INNER JOIN time_dim t_sales
      ON ws.ws_sold_time_sk = t_sales.t_time_sk
    INNER JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN date_dim d_creation
      ON wp.wp_creation_date_sk = d_creation.d_date_sk
    INNER JOIN date_dim d_access
      ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE
      d_sold.d_year = 2000
      AND t_sales.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'Brand#12'
      AND i.i_category = 'Sports'
      AND c.c_birth_year BETWEEN 1945 AND 1965
      AND wp.wp_char_count > 2000
      AND sm.sm_type = 'AIR'
  ),
  returns_agg AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_returned_date_sk,
      SUM(sr.sr_net_loss) AS total_return_loss,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    INNER JOIN date_dim d_ret
      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    INNER JOIN item i_ret
      ON sr.sr_item_sk = i_ret.i_item_sk
    INNER JOIN customer c_ret
      ON sr.sr_customer_sk = c_ret.c_customer_sk
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
  )
SELECT
  sb.ws_order_number,
  sb.i_item_id,
  sb.i_category,
  sb.i_brand,
  sb.i_color,
  sb.c_customer_sk,
  sb.c_birth_year,
  sb.cd_gender,
  sb.sm_type,
  sb.wp_char_count,
  sb.d_year,
  sb.t_hour,
  SUM(sb.ws_quantity) AS total_quantity,
  SUM(sb.ws_net_paid) AS total_net_paid,
  SUM(sb.ws_ext_sales_price) AS total_sales_price,
  SUM(sb.ws_net_profit) AS total_profit,
  COALESCE(ra.total_return_loss, 0) AS total_return_loss,
  COALESCE(ra.return_cnt, 0) AS return_cnt,
  ROW_NUMBER() OVER (PARTITION BY sb.i_category ORDER BY SUM(sb.ws_net_paid) DESC) AS category_rank
FROM sales_base sb
LEFT JOIN returns_agg ra
  ON sb.ws_item_sk = ra.sr_item_sk
  AND sb.ws_sold_date_sk = ra.sr_returned_date_sk
GROUP BY
  sb.ws_order_number,
  sb.i_item_id,
  sb.i_category,
  sb.i_brand,
  sb.i_color,
  sb.c_customer_sk,
  sb.c_birth_year,
  sb.cd_gender,
  sb.sm_type,
  sb.wp_char_count,
  sb.d_year,
  sb.t_hour,
  ra.total_return_loss,
  ra.return_cnt
HAVING
  SUM(sb.ws_net_paid) > 10000
ORDER BY
  total_net_paid DESC
LIMIT 100
