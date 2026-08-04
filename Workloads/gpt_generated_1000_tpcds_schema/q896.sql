WITH base1 AS (
   SELECT
      cc.cc_name,
      i.i_category,
      d.d_month_seq,
      c.c_customer_sk,
      SUM(sr.sr_return_amt)                          AS total_return_amt,
      AVG(sr.sr_return_quantity)                     AS avg_return_qty,
      COUNT(DISTINCT sr.sr_ticket_number)            AS cnt_tickets,
      MIN(sr.sr_return_tax)                          AS min_tax,
      MAX(sr.sr_store_credit)                        AS max_credit,
      CASE WHEN i.i_color = 'sandy' THEN 'Warm' ELSE 'Other' END AS color_group,
      (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_customer_sk = c.c_customer_sk) AS cust_return_cnt
   FROM store_returns sr
   JOIN date_dim d       ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i           ON sr.sr_item_sk = i.i_item_sk
   JOIN promotion p      ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = d.d_date_sk
   JOIN customer c      ON sr.sr_customer_sk = c.c_customer_sk
   JOIN web_page w       ON w.wp_customer_sk = c.c_customer_sk
   JOIN call_center cc  ON cc.cc_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
     AND i.i_color = 'sandy'
     AND c.c_birth_month = 7
     AND cc.cc_country = 'United States'
     AND w.wp_link_count > 5
     AND EXISTS (SELECT 1 FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk AND p2.p_discount_active = 'Y')
   GROUP BY cc.cc_name, i.i_category, d.d_month_seq, c.c_customer_sk, i.i_color
),
base2 AS (
   SELECT
      cc.cc_name,
      i.i_category,
      d.d_month_seq,
      c.c_customer_sk,
      SUM(sr.sr_return_amt)                          AS total_return_amt,
      AVG(sr.sr_return_quantity)                     AS avg_return_qty,
      COUNT(DISTINCT sr.sr_ticket_number)            AS cnt_tickets,
      MIN(sr.sr_return_tax)                          AS min_tax,
      MAX(sr.sr_store_credit)                        AS max_credit,
      CASE WHEN i.i_color = 'sandy' THEN 'Warm' ELSE 'Other' END AS color_group,
      (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_customer_sk = c.c_customer_sk) AS cust_return_cnt
   FROM store_returns sr
   JOIN date_dim d       ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i           ON sr.sr_item_sk = i.i_item_sk
   JOIN promotion p      ON p.p_item_sk = i.i_item_sk AND p.p_end_date_sk = d.d_date_sk
   JOIN customer c      ON sr.sr_customer_sk = c.c_customer_sk
   JOIN web_page w       ON w.wp_customer_sk = c.c_customer_sk
   JOIN call_center cc  ON cc.cc_open_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND i.i_color = 'tan'
     AND c.c_birth_month = 3
     AND cc.cc_country = 'United States'
     AND w.wp_link_count BETWEEN 2 AND 10
   GROUP BY cc.cc_name, i.i_category, d.d_month_seq, c.c_customer_sk, i.i_color
),
unioned AS (
   SELECT * FROM base1
   UNION
   SELECT * FROM base2
)
SELECT
   cc_name,
   i_category,
   d_month_seq,
   color_group,
   SUM(total_return_amt)   AS sum_return_amt,
   AVG(avg_return_qty)      AS avg_return_qty,
   SUM(cnt_tickets)         AS total_tickets,
   MIN(min_tax)             AS min_tax,
   MAX(max_credit)          AS max_credit,
   SUM(cust_return_cnt)    AS total_cust_returns,
   ROW_NUMBER() OVER (ORDER BY SUM(total_return_amt) DESC) AS rn
FROM unioned
GROUP BY cc_name, i_category, d_month_seq, color_group
ORDER BY sum_return_amt DESC
LIMIT 100
