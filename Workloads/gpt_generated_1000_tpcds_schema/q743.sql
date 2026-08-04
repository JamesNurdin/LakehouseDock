WITH sampled_inventory AS (
      SELECT *
      FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    web_order_intersect AS (
      SELECT ws.ws_order_number
      FROM web_sales ws
      JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
      JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
      WHERE td.t_meal_time = 'lunch' AND wsite.web_state = 'CA'
      INTERSECT
      SELECT wr.wr_order_number
      FROM web_returns wr
      JOIN time_dim td2 ON wr.wr_returned_time_sk = td2.t_time_sk
      JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
      WHERE td2.t_meal_time = 'lunch' AND wp2.wp_type = 'product'
    ),
    union_returns AS (
      SELECT
        r.r_reason_desc,
        td.t_meal_time,
        cr.cr_return_amount      AS return_amount,
        cr.cr_return_quantity    AS return_quantity,
        cr.cr_order_number       AS order_number,
        c.c_customer_id,
        inv_l.total_on_hand
      FROM catalog_returns cr
      JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
      JOIN item i ON cr.cr_item_sk = i.i_item_sk
      JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
      JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
      JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
      JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
      CROSS JOIN LATERAL (
        SELECT SUM(si.inv_quantity_on_hand) AS total_on_hand
        FROM sampled_inventory si
        WHERE si.inv_item_sk = i.i_item_sk
      ) AS inv_l
      WHERE i.i_color = 'Red' AND c.c_birth_month = 5
      UNION DISTINCT
      SELECT
        r.r_reason_desc,
        td.t_meal_time,
        sr.sr_return_amt        AS return_amount,
        sr.sr_return_quantity   AS return_quantity,
        sr.sr_ticket_number     AS order_number,
        c.c_customer_id,
        inv_l.total_on_hand
      FROM store_returns sr
      JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
      JOIN item i ON sr.sr_item_sk = i.i_item_sk
      JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
      JOIN store s ON sr.sr_store_sk = s.s_store_sk
      JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
      JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
      JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
      CROSS JOIN LATERAL (
        SELECT SUM(si.inv_quantity_on_hand) AS total_on_hand
        FROM sampled_inventory si
        WHERE si.inv_item_sk = i.i_item_sk
      ) AS inv_l
      WHERE s.s_state = 'TX' AND i.i_size = 'M'
    ),
    final_agg AS (
      SELECT
        ur.r_reason_desc,
        ur.t_meal_time,
        COUNT(DISTINCT ur.order_number)                AS cnt_orders,
        SUM(ur.return_amount)                         AS total_return_amount,
        AVG(ur.return_quantity)                       AS avg_return_qty,
        MAX(ur.total_on_hand)                         AS max_inventory_on_hand
      FROM union_returns ur
      JOIN web_order_intersect wi ON ur.order_number = wi.ws_order_number
      GROUP BY ur.r_reason_desc, ur.t_meal_time
    ),
    expanded AS (
      SELECT
        f.r_reason_desc,
        f.t_meal_time,
        f.cnt_orders,
        f.avg_return_qty,
        ARRAY[f.total_return_amount, f.max_inventory_on_hand] AS metrics
      FROM final_agg f
    )
SELECT
  e.r_reason_desc,
  e.t_meal_time,
  e.cnt_orders,
  e.avg_return_qty,
  u.metric_value,
  CASE WHEN u.idx = 1 THEN 'total_return_amount' ELSE 'max_inventory_on_hand' END AS metric_name
FROM expanded e
CROSS JOIN UNNEST(e.metrics) WITH ORDINALITY AS u(metric_value, idx)
ORDER BY e.r_reason_desc, u.idx
