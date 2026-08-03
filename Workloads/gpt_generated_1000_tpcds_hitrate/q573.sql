WITH
  -- Catalog sales enriched with all dimension tables
  cs_detail AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sales_price,
      cs.cs_net_profit,
      c.c_customer_id,
      ca.ca_state,
      hd.hd_income_band_sk,
      p.p_promo_id,
      w.w_warehouse_name,
      td.t_hour
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE p.p_end_date_sk > 2450300
  ),

  -- Web sales enriched with the same dimensions (different aliases)
  ws_detail AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sales_price,
      ws.ws_net_profit,
      c.c_customer_id AS ws_customer_id,
      ca.ca_state AS ws_state,
      hd.hd_income_band_sk AS ws_income_band,
      p.p_promo_id AS ws_promo_id,
      w.w_warehouse_name AS ws_warehouse,
      td.t_hour AS ws_hour
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE p.p_end_date_sk > 2450300
  ),

  -- Store returns enriched – used later in the CASE expression
  sr_detail AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      c.c_customer_id AS sr_customer_id,
      ca.ca_state AS sr_state,
      hd.hd_income_band_sk AS sr_income_band,
      td.t_shift
    FROM store_returns sr
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td
      ON sr.sr_return_time_sk = td.t_time_sk
  ),

  -- Distinct promo ids for the UNNEST example
  promo_list AS (
    SELECT ARRAY_AGG(p.p_promo_id) AS promos
    FROM promotion p
    WHERE p.p_end_date_sk > 2450300
  ),

  -- Orders appearing in both catalog and web sales (INTERSECT)
  orders_cs AS (
    SELECT cs_order_number AS order_id FROM cs_detail
  ),
  orders_ws AS (
    SELECT ws_order_number AS order_id FROM ws_detail
  ),
  intersect_orders AS (
    SELECT order_id FROM orders_cs
    INTERSECT
    SELECT order_id FROM orders_ws
  ),

  -- Small dimension for a CROSS JOIN
  shift_vals AS (
    SELECT 'morning' AS shift UNION ALL SELECT 'evening' AS shift
  ),

  -- Main result set
  final AS (
    SELECT
      io.order_id,
      COUNT(*) OVER (PARTITION BY io.order_id) AS order_cnt,
      CASE
        WHEN EXISTS (
          SELECT 1
          FROM sr_detail sr
          WHERE sr.sr_ticket_number = io.order_id
            AND sr.t_shift = 'night'
        ) THEN 'Returned'
        ELSE 'No Return'
      END AS return_flag,
      COALESCE(u.promo_code, 'NO_PROMO') AS promo_code,
      sv.shift
    FROM intersect_orders io
    CROSS JOIN shift_vals sv
    LEFT JOIN LATERAL (
      SELECT val AS promo_code
      FROM UNNEST((SELECT promos FROM promo_list)) AS t(val)
      WHERE val LIKE 'AAAAAAA%'
      LIMIT 1
    ) u ON TRUE
  )
SELECT
  f.order_id,
  f.order_cnt,
  f.return_flag,
  f.promo_code,
  f.shift
FROM final f
ORDER BY f.order_id DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
