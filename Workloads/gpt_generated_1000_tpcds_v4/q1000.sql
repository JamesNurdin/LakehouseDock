WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_ticket_number,
        SUM(ss_net_profit)      AS total_net_profit,
        SUM(ss_quantity)        AS total_quantity
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk, ss_sold_time_sk, ss_ticket_number
)
SELECT
    d.d_year,
    i.i_item_id,
    i.i_brand,
    p.p_promo_name,
    cc.cc_name,
    ws.ws_net_profit,
    sr.sr_net_loss,
    cr.cr_return_amount,
    ss_agg.total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ss_agg.total_net_profit DESC) AS profit_rank
FROM ss_agg
JOIN store_sales ss
  ON ss_agg.ss_item_sk      = ss.ss_item_sk
 AND ss_agg.ss_sold_date_sk = ss.ss_sold_date_sk
 AND ss_agg.ss_sold_time_sk = ss.ss_sold_time_sk
 AND ss_agg.ss_ticket_number = ss.ss_ticket_number
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk        = i.i_item_sk
 AND cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_item_sk      = i.i_item_sk
 AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
WHERE d.d_year = 1998
  AND i.i_brand = 'Brand#23'
  AND p.p_discount_active = 'Y'
  AND t.t_am_pm = 'PM'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_net_loss > 100
      )
ORDER BY ss_agg.total_net_profit DESC
LIMIT 100
