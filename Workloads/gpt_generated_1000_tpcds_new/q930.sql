WITH
  sales_sample AS (
    SELECT
      ss.ss_ticket_number               AS ticket,
      ss.ss_net_profit                  AS profit,
      cd.cd_gender                      AS gender,
      i.i_category                      AS category,
      d.d_year                          AS year
    FROM store_sales ss
      TABLESAMPLE BERNOULLI (10)
      JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
      JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
      JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
      JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
      JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  returns AS (
    SELECT
      sr.sr_ticket_number               AS ticket,
      -sr.sr_net_loss                    AS loss,
      d.d_year                           AS year
    FROM store_returns sr
      JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
      JOIN item i                   ON sr.sr_item_sk = i.i_item_sk
      JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
  ),
  catalog_ret AS (
    SELECT
      cr.cr_order_number                AS order_num,
      cr.cr_return_amount               AS return_amt,
      d.d_year                          AS year,
      cp.cp_type                        AS page_type,
      sm.sm_type                        AS ship_type,
      cc.cc_name                        AS call_center_name
    FROM catalog_returns cr
      JOIN date_dim d                ON cr.cr_returned_date_sk = d.d_date_sk
      JOIN item i                    ON cr.cr_item_sk = i.i_item_sk
      JOIN catalog_page cp           ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      FULL OUTER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
      LEFT JOIN ship_mode sm         ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      LEFT JOIN date_dim d_cc        ON cc.cc_closed_date_sk = d_cc.d_date_sk
  ),
  web_sales_sub AS (
    SELECT
      ws.ws_order_number                AS order_num,
      ws.ws_net_paid                    AS net_paid,
      d.d_year                          AS year,
      wp.wp_type                        AS page_type,
      sm.sm_type                        AS ship_type,
      CASE WHEN ws.ws_net_paid > 1000 THEN 'High' ELSE 'Low' END AS revenue_bracket
    FROM web_sales ws
      JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN item i                   ON ws.ws_item_sk = i.i_item_sk
      JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      LEFT JOIN web_returns wr      ON ws.ws_order_number = wr.wr_order_number
      LEFT JOIN date_dim d_wr        ON wr.wr_returned_date_sk = d_wr.d_date_sk
  ),
  combined AS (
    SELECT key, amount, year, src FROM (
      SELECT
        ticket            AS key,
        profit            AS amount,
        year              AS year,
        'store_sales'     AS src
      FROM sales_sample
      UNION
      SELECT
        ticket            AS key,
        loss              AS amount,
        year              AS year,
        'store_returns'   AS src
      FROM returns
    )
    INTERSECT
    SELECT
      order_num          AS key,
      net_paid           AS amount,
      year               AS year,
      'web_sales'        AS src
    FROM web_sales_sub
    EXCEPT
    SELECT
      order_num          AS key,
      return_amt         AS amount,
      year               AS year,
      'catalog_ret'      AS src
    FROM catalog_ret
  )
SELECT
  src,
  year,
  SUM(amount)                         AS total_amount,
  CASE WHEN SUM(amount) > 5000 THEN 'Large' ELSE 'Small' END AS size_category
FROM combined
GROUP BY GROUPING SETS ((src, year), (src), (year), ())
LIMIT 100
