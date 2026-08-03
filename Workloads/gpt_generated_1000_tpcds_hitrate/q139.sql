WITH
  base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_ext_sales_price            AS store_sales_price,
      sr.sr_net_loss                   AS store_return_loss,
      ws.ws_ext_sales_price            AS web_sales_price,
      wr.wr_net_loss                   AS web_return_loss,
      s.s_store_name,
      ws_web.web_name                  AS web_name,
      i.i_category,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      r.r_reason_desc,
      td.t_hour,
      ca.ca_gmt_offset,
      w.w_county,
      wp.wp_type
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_store_sk = s.s_store_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_site ws_web
      ON ws.ws_web_site_sk = ws_web.web_site_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE s.s_state = 'CA'
      AND w.w_county = 'Williamson County'
      AND ib.ib_lower_bound >= 50000
      AND r.r_reason_desc LIKE '%fit%'
      AND i.i_current_price > 100
      AND td.t_hour BETWEEN 9 AND 17
  ),
  distinct_keys AS (
    SELECT DISTINCT
      i_category,
      ib_income_band_sk,
      r_reason_desc
    FROM base
  ),
  store_agg AS (
    SELECT
      dk.i_category,
      dk.ib_income_band_sk,
      dk.r_reason_desc,
      COALESCE(SUM(b.store_sales_price), 0) AS total_sales,
      COALESCE(SUM(b.store_return_loss), 0) AS total_loss
    FROM distinct_keys dk
    LEFT JOIN base b
      ON b.i_category = dk.i_category
     AND b.ib_income_band_sk = dk.ib_income_band_sk
     AND b.r_reason_desc = dk.r_reason_desc
    GROUP BY dk.i_category, dk.ib_income_band_sk, dk.r_reason_desc
  ),
  web_agg AS (
    SELECT
      dk.i_category,
      dk.ib_income_band_sk,
      dk.r_reason_desc,
      COALESCE(SUM(b.web_sales_price), 0) AS total_sales,
      COALESCE(SUM(b.web_return_loss), 0) AS total_loss
    FROM distinct_keys dk
    LEFT JOIN base b
      ON b.i_category = dk.i_category
     AND b.ib_income_band_sk = dk.ib_income_band_sk
     AND b.r_reason_desc = dk.r_reason_desc
     AND b.web_name IS NOT NULL
    GROUP BY dk.i_category, dk.ib_income_band_sk, dk.r_reason_desc
  )
SELECT *
FROM store_agg
INTERSECT
SELECT *
FROM web_agg
ORDER BY i_category, ib_income_band_sk
LIMIT 100
