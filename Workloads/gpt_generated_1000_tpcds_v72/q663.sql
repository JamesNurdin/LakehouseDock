WITH inv_max_cte AS (
    SELECT i.inv_item_sk, MAX(i.inv_quantity_on_hand) AS max_qty
    FROM inventory i
    GROUP BY i.inv_item_sk
)
SELECT
    d_ret.d_year,
    ws.web_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(inv.inv_quantity_on_hand) AS avg_quantity_on_hand,
    MAX(im.max_qty) AS max_quantity_on_hand_overall,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk                               -- join 1
JOIN inventory inv
  ON inv.inv_date_sk = d_ret.d_date_sk                                      -- join 2
JOIN date_dim d_start
  ON inv.inv_date_sk = d_start.d_date_sk                                    -- join 3
JOIN promotion p_start
  ON p_start.p_start_date_sk = d_start.d_date_sk                           -- join 4
JOIN date_dim d_end
  ON p_start.p_end_date_sk = d_end.d_date_sk                                -- join 5
JOIN promotion p_end
  ON p_end.p_end_date_sk = d_end.d_date_sk                                  -- join 6
JOIN web_site ws
  ON ws.web_open_date_sk = d_end.d_date_sk                                  -- join 7
JOIN date_dim d_close
  ON ws.web_close_date_sk = d_close.d_date_sk                               -- join 8
JOIN web_site ws_close
  ON ws_close.web_close_date_sk = d_close.d_date_sk                         -- join 9
CROSS JOIN LATERAL (
    SELECT max_qty
    FROM inv_max_cte im
    WHERE im.inv_item_sk = inv.inv_item_sk
) im
WHERE d_ret.d_current_quarter = 'Y'
  AND NOT EXISTS (
      SELECT 1
      FROM promotion p_ex
      WHERE p_ex.p_item_sk = inv.inv_item_sk
        AND p_ex.p_promo_name = 'Clearance'
  )
  AND EXISTS (
      SELECT 1
      FROM web_site ws2
      WHERE ws2.web_state = 'CA'
        AND ws2.web_site_sk = ws.web_site_sk
  )
GROUP BY ROLLUP (d_ret.d_year, ws.web_name)
LIMIT 100
