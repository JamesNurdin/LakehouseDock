WITH
  /* Items sold in the period */
  sold_items AS (
    SELECT DISTINCT ss_item_sk
    FROM store_sales
  ),
  /* Items that appear in web returns */
  returned_items AS (
    SELECT DISTINCT wr_item_sk
    FROM web_returns
  ),
  /* Items sold but never returned on the web */
  non_returned_items AS (
    SELECT ss_item_sk
    FROM sold_items
    EXCEPT
    SELECT wr_item_sk
    FROM returned_items
  ),
  /* Unnest promotion channel flags into a normalized table */
  promo_channels AS (
    SELECT p.p_promo_sk,
           channel
    FROM promotion p
    CROSS JOIN UNNEST(ARRAY[ 'dmail','email','catalog','tv','radio','press','event','demo' ]) AS t(channel)
    WHERE (CASE
            WHEN channel = 'dmail'  THEN p.p_channel_dmail
            WHEN channel = 'email'  THEN p.p_channel_email
            WHEN channel = 'catalog' THEN p.p_channel_catalog
            WHEN channel = 'tv'     THEN p.p_channel_tv
            WHEN channel = 'radio'  THEN p.p_channel_radio
            WHEN channel = 'press'  THEN p.p_channel_press
            WHEN channel = 'event'  THEN p.p_channel_event
            WHEN channel = 'demo'   THEN p.p_channel_demo
          END) = 'Y'
  ),
  /* Core fact joined to all dimension tables */
  base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_net_paid,
      i.i_item_id,
      i.i_brand,
      i.i_category,
      d.d_year,
      t.t_shift,
      ca.ca_state,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      p.p_promo_name,
      w.w_warehouse_name,
      cp.cp_type,
      ws.web_name,
      r.r_reason_desc,
      inv.inv_quantity_on_hand,
      pc.channel AS active_promo_channel
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p         ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN promo_channels pc   ON p.p_promo_sk = pc.p_promo_sk
    LEFT JOIN warehouse w         ON 1 = 0   -- placeholder; real join via inventory later
    LEFT JOIN catalog_page cp     ON ss.ss_sold_date_sk = cp.cp_end_date_sk
    LEFT JOIN web_site ws         ON ss.ss_sold_date_sk = ws.web_open_date_sk
    LEFT JOIN inventory inv       ON ss.ss_item_sk = inv.inv_item_sk
                                 AND ss.ss_sold_date_sk = inv.inv_date_sk
    LEFT JOIN warehouse w2        ON inv.inv_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN store_returns sr    ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r            ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr      ON ss.ss_item_sk = wr.wr_item_sk
    WHERE ss.ss_item_sk IN (SELECT ss_item_sk FROM non_returned_items)
  )
SELECT
  b.d_year,
  b.t_shift,
  b.i_brand,
  b.i_category,
  COUNT(DISTINCT b.i_item_id)               AS distinct_items_sold,
  SUM(b.ss_quantity)                       AS total_quantity,
  SUM(b.ss_sales_price)                    AS total_sales,
  AVG(b.ss_net_paid)                       AS avg_net_paid,
  COUNT(DISTINCT b.active_promo_channel)   AS distinct_active_promo_channels,
  SUM(CASE WHEN b.cp_type = 'monthly' THEN 1 ELSE 0 END) AS monthly_catalog_pages,
  SUM(CASE WHEN b.r_reason_desc IS NOT NULL THEN 1 ELSE 0 END) AS returns_with_reason,
  SUM(b.inv_quantity_on_hand)               AS total_inventory_on_hand
FROM base b
WHERE b.d_year BETWEEN 2000 AND 2002
  AND b.ca_state IN ('CA','TX','NY')
  AND b.i_brand IS NOT NULL
GROUP BY b.d_year, b.t_shift, b.i_brand, b.i_category
HAVING SUM(b.ss_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
