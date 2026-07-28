WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        i.i_item_sk,
        i.i_category,
        c.c_customer_sk,
        c.c_birth_year,
        t.t_time_sk,
        t.t_hour,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        MAX(ss.ss_net_profit) AS max_profit,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'CA'
      AND i.i_current_price > 20.00
      AND c.c_birth_year BETWEEN 1960 AND 1980
      AND t.t_hour BETWEEN 9 AND 17
      AND p.p_discount_active = 'Y'
      AND p.p_cost > 100.00
    GROUP BY s.s_store_sk, s.s_store_id,
             i.i_item_sk, i.i_category,
             c.c_customer_sk, c.c_birth_year,
             t.t_time_sk, t.t_hour,
             p.p_promo_sk, p.p_promo_name, p.p_discount_active
)
SELECT
    sa.s_store_id,
    sa.i_category,
    sa.c_birth_year,
    sa.t_hour,
    sa.promo_status,
    sa.total_net_paid,
    sa.total_discount,
    sa.distinct_tickets,
    SUM(sr.sr_return_amt) OVER (PARTITION BY sa.s_store_id) AS store_return_total,
    SUM(wr.wr_refunded_cash) OVER (PARTITION BY sa.s_store_id) AS store_refund_total,
    ROW_NUMBER() OVER (PARTITION BY sa.s_store_id ORDER BY sa.total_net_paid DESC) AS rn
FROM sales_agg sa
LEFT JOIN store_returns sr
    ON sr.sr_store_sk = sa.s_store_sk
   AND sr.sr_item_sk = sa.i_item_sk
   AND sr.sr_customer_sk = sa.c_customer_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = sa.i_item_sk
   AND wr.wr_returned_time_sk = sa.t_time_sk
   AND wr.wr_refunded_customer_sk = sa.c_customer_sk
WHERE sr.sr_return_amt > 5.00
  AND wr.wr_return_ship_cost > 100.00
  AND r.r_reason_desc IS NOT NULL
LIMIT 100
