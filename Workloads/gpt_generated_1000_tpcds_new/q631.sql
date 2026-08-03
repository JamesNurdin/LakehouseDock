WITH
  promotion_channels AS (
    SELECT
      p.p_promo_sk,
      TRIM(channel) AS promo_channel
    FROM promotion p
    CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel)
    WHERE p.p_promo_sk IS NOT NULL
  ),
  sales_enriched AS (
    SELECT
      cs.cs_sold_date_sk AS sold_date_sk,
      cs.cs_sold_time_sk AS sold_time_sk,
      cs.cs_item_sk AS item_sk,
      cs.cs_quantity AS quantity,
      cs.cs_ext_sales_price AS sales_amount,
      cs.cs_net_paid AS net_paid,
      cp.cp_department,
      cp.cp_catalog_number,
      i.i_color,
      i.i_units,
      i.i_size,
      p.p_purpose,
      sm.sm_type AS ship_type,
      w.w_state AS warehouse_state,
      ca.ca_state AS address_state,
      td.t_hour,
      pc.promo_channel
    FROM catalog_sales cs
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p                    ON cs.cs_promo_sk = p.p_promo_sk
    JOIN promotion_channels pc          ON cs.cs_promo_sk = pc.p_promo_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                    ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca           ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN time_dim td                   ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_department = 'Books'
      AND i.i_color = 'Red'
      AND p.p_purpose = 'Unknown'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
  ),
  returns_union AS (
    SELECT
      sr.sr_returned_date_sk   AS return_date_sk,
      sr.sr_return_time_sk     AS return_time_sk,
      sr.sr_item_sk            AS item_sk,
      sr.sr_return_quantity    AS quantity,
      sr.sr_return_amt         AS return_amount,
      r.r_reason_desc          AS reason_desc,
      td.t_hour                AS hour,
      i.i_color                AS item_color,
      ca.ca_state              AS address_state,
      'store'                  AS source
    FROM store_returns sr
    JOIN reason r               ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td            ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i                 ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca    ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_desc LIKE '%Defect%'
      AND td.t_hour >= 12
      AND i.i_units = 'Dozen'
      AND ca.ca_state = 'TX'
      AND i.i_color = 'Red'
    UNION DISTINCT
    SELECT
      wr.wr_returned_date_sk   AS return_date_sk,
      wr.wr_returned_time_sk   AS return_time_sk,
      wr.wr_item_sk            AS item_sk,
      wr.wr_return_quantity    AS quantity,
      wr.wr_return_amt         AS return_amount,
      r.r_reason_desc          AS reason_desc,
      td.t_hour                AS hour,
      i.i_color                AS item_color,
      ca.ca_state              AS address_state,
      'web'                    AS source
    FROM web_returns wr
    JOIN reason r               ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim td            ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i                 ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_desc LIKE '%Defect%'
      AND td.t_hour >= 12
      AND i.i_units = 'Dozen'
      AND ca.ca_state = 'TX'
      AND i.i_color = 'Red'
  ),
  inventory_info AS (
    SELECT
      inv.inv_item_sk AS item_sk,
      inv.inv_quantity_on_hand AS qty_on_hand,
      w.w_state AS warehouse_state
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  ),
  combined AS (
    SELECT
      se.sold_date_sk        AS date_sk,
      se.t_hour              AS hour,
      se.item_sk             AS item_sk,
      se.quantity            AS quantity,
      se.sales_amount        AS amount,
      'sale'                 AS source,
      se.cp_department       AS department,
      se.i_color             AS item_color,
      se.i_units             AS item_units,
      se.i_size              AS item_size,
      se.p_purpose           AS promo_purpose,
      se.ship_type           AS ship_type,
      se.warehouse_state    AS warehouse_state,
      se.address_state       AS address_state,
      se.promo_channel       AS promo_channel
    FROM sales_enriched se
    WHERE NOT EXISTS (
      SELECT 1 FROM returns_union ru
      WHERE ru.item_sk = se.item_sk
        AND ru.return_date_sk = se.sold_date_sk
    )
    UNION DISTINCT
    SELECT
      ru.return_date_sk       AS date_sk,
      ru.hour                 AS hour,
      ru.item_sk              AS item_sk,
      ru.quantity             AS quantity,
      ru.return_amount        AS amount,
      ru.source               AS source,
      NULL                    AS department,
      ru.item_color           AS item_color,
      NULL                    AS item_units,
      NULL                    AS item_size,
      NULL                    AS promo_purpose,
      NULL                    AS ship_type,
      NULL                    AS warehouse_state,
      ru.address_state        AS address_state,
      NULL                    AS promo_channel
    FROM returns_union ru
  )
SELECT
  c.date_sk,
  c.hour,
  c.item_sk,
  c.source,
  SUM(c.quantity)                     AS total_quantity,
  SUM(c.amount)                       AS total_amount,
  (SELECT SUM(cs2.cs_ext_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = c.item_sk) AS total_item_sales,
  LAG(SUM(c.amount)) OVER (PARTITION BY c.item_sk ORDER BY c.date_sk, c.hour) AS prev_total_amount,
  ii.qty_on_hand,
  c.promo_channel
FROM combined c
LEFT JOIN inventory_info ii ON ii.item_sk = c.item_sk
GROUP BY
  c.date_sk,
  c.hour,
  c.item_sk,
  c.source,
  c.department,
  c.item_color,
  c.item_units,
  c.item_size,
  c.promo_purpose,
  c.ship_type,
  c.warehouse_state,
  c.address_state,
  c.promo_channel,
  ii.qty_on_hand
HAVING SUM(c.amount) > 100
ORDER BY c.date_sk DESC, c.hour ASC
