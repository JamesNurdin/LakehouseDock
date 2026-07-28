WITH agg_store_returns AS (
    SELECT
        sr_store_sk,
        sr_reason_sk,
        COUNT(*) AS return_cnt,
        SUM(sr_return_amt) AS return_amt_total
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
    GROUP BY sr_store_sk, sr_reason_sk
)
SELECT
    s.s_store_id,
    s.s_state,
    i.i_category,
    p.p_promo_name,
    td1.t_hour,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(ar.return_amt_total, 0)) AS total_return_amount,
    AVG(ss.ss_sales_price) AS avg_store_sales_price,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    MAX(ss.ss_net_profit) AS max_net_profit,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) DESC) AS sales_rank_state
FROM store_sales ss
JOIN time_dim td1
  ON ss.ss_sold_time_sk = td1.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN agg_store_returns ar
  ON s.s_store_sk = ar.sr_store_sk
LEFT JOIN reason r
  ON ar.sr_reason_sk = r.r_reason_sk
-- web side joins
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN time_dim td2
  ON ws.ws_sold_time_sk = td2.t_time_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN promotion p2
  ON ws.ws_promo_sk = p2.p_promo_sk
LEFT JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
WHERE ca.ca_state = 'CA'
  AND i.i_current_price BETWEEN 10 AND 100
  AND s.s_gmt_offset = -5.00
  AND td1.t_hour BETWEEN 9 AND 17
  AND p.p_discount_active = 'Y'
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451500
  AND NOT EXISTS (
        SELECT 1 FROM web_returns wr_ex
        WHERE wr_ex.wr_refunded_customer_sk = c.c_customer_sk
    )
GROUP BY s.s_store_id, s.s_state, i.i_category, p.p_promo_name, td1.t_hour
ORDER BY total_sales DESC
LIMIT 100
