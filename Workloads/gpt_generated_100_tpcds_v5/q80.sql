WITH max_promo AS (
    SELECT p.p_item_sk,
           MAX(p.p_cost) AS max_promo_cost
    FROM promotion p
    GROUP BY p.p_item_sk
)
SELECT
    c.c_customer_id,
    i.i_product_name,
    i.i_category,
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    t.t_hour,
    cs.cs_net_profit,
    p.p_promo_name,
    max_promo.max_promo_cost,
    wp.wp_url,
    sr.sr_return_amt,
    (SELECT SUM(sr2.sr_return_amt)
     FROM store_returns sr2
     WHERE sr2.sr_item_sk = i.i_item_sk) AS total_item_return_amt,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.cs_net_profit DESC) AS rn_customer_profit,
    RANK() OVER (PARTITION BY i.i_category ORDER BY cs.cs_net_profit DESC) AS profit_rank_in_category
FROM catalog_sales cs
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN max_promo
  ON p.p_item_sk = max_promo.p_item_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
  AND sr.sr_return_time_sk = t.t_time_sk
WHERE t.t_hour BETWEEN 8 AND 12
  AND i.i_current_price > 5.0
  AND p.p_discount_active = 'Y'
  AND wp.wp_type = 'order'
ORDER BY cs.cs_net_profit DESC
LIMIT 100
