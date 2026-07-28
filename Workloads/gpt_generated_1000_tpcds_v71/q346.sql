WITH base AS (
  SELECT
    ca.ca_state,
    i.i_category,
    ss.ss_net_paid,
    ss.ss_ext_discount_amt,
    ss.ss_ticket_number,
    ss.ss_quantity,
    ss.ss_list_price,
    p.p_discount_active,
    cc.cc_state,
    wr.wr_return_amt,
    sr.sr_reason_sk,
    r.r_reason_desc
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                              AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                         AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
                         AND cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
                         AND wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE cc.cc_state = 'CA'
    AND ca.ca_city IN ('Montpelier', 'Maple Grove')
    AND i.i_category = 'Electronics'
    AND ss.ss_quantity > 5
    AND ss.ss_list_price BETWEEN 20 AND 150
    AND p.p_discount_active = 'Y'
    AND wr.wr_return_amt > 10
),
agg AS (
  SELECT
    ca_state,
    i_category,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss_ticket_number) AS order_count
  FROM base
  GROUP BY ca_state, i_category
)
SELECT
  ca_state,
  i_category,
  total_net_paid,
  avg_discount,
  order_count,
  (SELECT AVG(ss_net_paid) FROM store_sales) AS overall_avg_net_paid,
  ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_net_paid DESC) AS rank_within_state
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
