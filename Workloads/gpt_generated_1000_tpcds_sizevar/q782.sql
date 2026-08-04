WITH
  -- Pre‑aggregate store returns per store (required pre‑aggregation CTE)
  store_agg AS (
    SELECT
      sr.sr_store_sk,
      SUM(sr.sr_net_loss) AS store_net_loss,
      COUNT(*) AS store_return_cnt
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 10
    GROUP BY sr.sr_store_sk
  ),

  -- Build a map attribute for each item and promotion (used for UNNEST)
  item_attrs AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      MAP(
        ARRAY['promo_name','price'],
        ARRAY[COALESCE(p.p_promo_name, ''), CAST(i.i_current_price AS varchar)]
      ) AS attrs
    FROM item i
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
  ),

  -- Keys used for INTERSECT and EXCEPT
  catalog_keys AS (
    SELECT cr.cr_order_number AS order_num
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 1
  ),
  store_keys AS (
    SELECT sr.sr_ticket_number AS order_num
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 1
  ),
  intersect_keys AS (
    SELECT order_num FROM catalog_keys
    INTERSECT
    SELECT order_num FROM store_keys
  ),
  web_keys AS (
    SELECT wr.wr_order_number AS order_num
    FROM web_returns wr
    WHERE wr.wr_return_quantity = 1
  ),
  except_keys AS (
    SELECT order_num FROM web_keys
    EXCEPT
    SELECT order_num FROM catalog_keys
  ),

  -- Catalog returns side of the UNION
  catalog_part AS (
    SELECT
      cr.cr_order_number                               AS order_number,
      cr.cr_return_amount                              AS return_amount,
      c.c_customer_id                                 AS c_customer_id,
      ca.ca_city                                      AS city,
      cd.cd_gender                                    AS gender,
      hd.hd_income_band_sk                            AS income_band,
      i.i_product_name                                AS product_name,
      p.p_promo_name                                  AS promo_name,
      t.t_hour                                        AS hour,
      w.w_warehouse_name                              AS location_name,
      NULL                                            AS store_net_loss,
      ROW_NUMBER() OVER (PARTITION BY cr.cr_order_number ORDER BY cr.cr_return_amount DESC) AS rn,
      (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
      )                                              AS total_customer_return,
      a.attr_key,
      a.attr_value
    FROM catalog_returns cr
    JOIN customer c               ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cr.cr_refunded_addr_sk    = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk   = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN item i                   ON cr.cr_item_sk            = i.i_item_sk
    LEFT JOIN promotion p         ON p.p_item_sk              = i.i_item_sk
    JOIN time_dim t               ON cr.cr_returned_time_sk   = t.t_time_sk
    JOIN warehouse w              ON cr.cr_warehouse_sk       = w.w_warehouse_sk
    JOIN item_attrs ia            ON ia.i_item_sk             = i.i_item_sk
    CROSS JOIN UNNEST (ia.attrs) AS a (attr_key, attr_value)
    WHERE cr.cr_return_amount > 0
      AND t.t_hour BETWEEN 8 AND 20
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND EXISTS (SELECT 1 FROM intersect_keys ik WHERE ik.order_num = cr.cr_order_number)
  ),

  -- Store returns side of the UNION
  store_part AS (
    SELECT
      sr.sr_ticket_number                               AS order_number,
      sr.sr_return_amt                                   AS return_amount,
      c.c_customer_id                                   AS c_customer_id,
      ca.ca_city                                        AS city,
      cd.cd_gender                                      AS gender,
      hd.hd_income_band_sk                              AS income_band,
      i.i_product_name                                  AS product_name,
      p.p_promo_name                                    AS promo_name,
      t.t_hour                                          AS hour,
      s.s_store_name                                    AS location_name,
      sa.store_net_loss                                 AS store_net_loss,
      ROW_NUMBER() OVER (PARTITION BY sr.sr_ticket_number ORDER BY sr.sr_return_amt DESC) AS rn,
      (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
      )                                                AS total_customer_return,
      a.attr_key,
      a.attr_value
    FROM store_returns sr
    JOIN store s                     ON sr.sr_store_sk   = s.s_store_sk
    JOIN store_agg sa                ON sr.sr_store_sk   = sa.sr_store_sk
    JOIN customer c                  ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca         ON sr.sr_addr_sk    = ca.ca_address_sk
    JOIN customer_demographics cd    ON sr.sr_cdemo_sk   = cd.cd_demo_sk
    JOIN household_demographics hd   ON sr.sr_hdemo_sk   = hd.hd_demo_sk
    JOIN item i                      ON sr.sr_item_sk    = i.i_item_sk
    LEFT JOIN promotion p            ON p.p_item_sk      = i.i_item_sk
    JOIN time_dim t                  ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item_attrs ia               ON ia.i_item_sk     = i.i_item_sk
    CROSS JOIN UNNEST (ia.attrs) AS a (attr_key, attr_value)
    WHERE sr.sr_return_amt > 0
      AND t.t_hour BETWEEN 8 AND 20
      AND ca.ca_state = 'NY'
      AND cd.cd_gender = 'F'
      AND EXISTS (SELECT 1 FROM intersect_keys ik WHERE ik.order_num = sr.sr_ticket_number)
  ),

  -- Web returns side of the UNION (uses web_page and web_returns)
  web_part AS (
    SELECT
      wr.wr_order_number                               AS order_number,
      wr.wr_return_amt                                 AS return_amount,
      c.c_customer_id                                 AS c_customer_id,
      ca.ca_city                                      AS city,
      cd.cd_gender                                    AS gender,
      hd.hd_income_band_sk                            AS income_band,
      i.i_product_name                                AS product_name,
      p.p_promo_name                                  AS promo_name,
      t.t_hour                                        AS hour,
      wp.wp_url                                       AS location_name,
      NULL                                            AS store_net_loss,
      ROW_NUMBER() OVER (PARTITION BY wr.wr_order_number ORDER BY wr.wr_return_amt DESC) AS rn,
      (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
      )                                                AS total_customer_return,
      a.attr_key,
      a.attr_value
    FROM web_returns wr
    JOIN web_page wp                ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c                 ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca        ON wr.wr_refunded_addr_sk    = ca.ca_address_sk
    JOIN customer_demographics cd   ON wr.wr_refunded_cdemo_sk   = cd.cd_demo_sk
    JOIN household_demographics hd  ON wr.wr_refunded_hdemo_sk   = hd.hd_demo_sk
    JOIN item i                     ON wr.wr_item_sk             = i.i_item_sk
    LEFT JOIN promotion p           ON p.p_item_sk               = i.i_item_sk
    JOIN time_dim t                 ON wr.wr_returned_time_sk    = t.t_time_sk
    JOIN item_attrs ia              ON ia.i_item_sk              = i.i_item_sk
    CROSS JOIN UNNEST (ia.attrs) AS a (attr_key, attr_value)
    WHERE wr.wr_return_amt > 0
      AND t.t_hour BETWEEN 8 AND 20
      AND ca.ca_state = 'TX'
      AND cd.cd_gender = 'M'
      AND EXISTS (SELECT 1 FROM intersect_keys ik WHERE ik.order_num = wr.wr_order_number)
  ),

  -- Union of the three return streams (distinct by default)
  combined AS (
    SELECT * FROM catalog_part
    UNION
    SELECT * FROM store_part
    UNION
    SELECT * FROM web_part
  )
SELECT
  order_number,
  return_amount,
  c_customer_id,
  city,
  gender,
  income_band,
  product_name,
  promo_name,
  hour,
  location_name,
  store_net_loss,
  rn,
  total_customer_return,
  attr_key,
  attr_value,
  CASE WHEN order_number IN (SELECT order_num FROM except_keys) THEN 'EXCEPTED' ELSE 'NORMAL' END AS flag
FROM combined
ORDER BY return_amount DESC
LIMIT 100
