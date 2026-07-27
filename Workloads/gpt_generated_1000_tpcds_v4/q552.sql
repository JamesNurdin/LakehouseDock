WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid) AS store_total_net_paid,
        SUM(ss_quantity) AS store_total_qty
    FROM store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_store_sk, ss_sold_date_sk
    HAVING SUM(ss_net_paid) > 1000
)
SELECT
    c.c_customer_id,
    s.s_store_id,
    s.s_store_name,
    cc.cc_name AS call_center_name,
    w.w_warehouse_name,
    hd.hd_buy_potential,
    cs.cs_net_paid_inc_tax,
    ss_agg.store_total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cs.cs_net_paid_inc_tax DESC) AS rn_customer_by_sales,
    RANK() OVER (ORDER BY ss_agg.store_total_net_paid DESC) AS store_rank_by_total
FROM ss_agg
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN store_sales ss
  ON ss.ss_store_sk = s.s_store_sk
 AND ss.ss_sold_date_sk = ss_agg.ss_sold_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN catalog_sales cs
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
WHERE
    s.s_tax_percentage >= 0.03
    AND c.c_birth_month IN (1, 6, 11)
    AND cs.cs_ext_ship_cost > 500
    AND cc.cc_gmt_offset BETWEEN -5 AND 5
    AND w.w_state = 'TX'
    AND hd.hd_buy_potential = 'High'
    AND sr.sr_return_quantity > 0
GROUP BY
    c.c_customer_id,
    s.s_store_id,
    s.s_store_name,
    cc.cc_name,
    w.w_warehouse_name,
    hd.hd_buy_potential,
    cs.cs_net_paid_inc_tax,
    ss_agg.store_total_net_paid
HAVING
    SUM(cs.cs_net_paid_inc_tax) > 2000
ORDER BY store_rank_by_total
LIMIT 100
