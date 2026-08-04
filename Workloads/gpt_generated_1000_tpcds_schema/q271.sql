WITH filtered AS (
   SELECT
       sr.sr_ticket_number,
       sr.sr_return_amt,
       sr.sr_net_loss,
       sr.sr_fee,
       sr.sr_refunded_cash,
       sr.sr_return_quantity,
       sr.sr_customer_sk,
       sr.sr_cdemo_sk,
       sr.sr_addr_sk,
       sr.sr_reason_sk,
       cd.cd_gender,
       cd.cd_marital_status,
       ca.ca_state,
       r.r_reason_desc,
       cc.cc_name,
       cc.cc_state,
       cc.cc_hours,
       cp.cp_department,
       cp.cp_catalog_number,
       cp.cp_catalog_page_number,
       wr.wr_return_amt_inc_tax,
       wr.wr_return_quantity,
       wr.wr_order_number
   FROM store_returns sr
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN catalog_returns cr ON r.r_reason_sk = cr.cr_reason_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN web_returns wr ON r.r_reason_sk = wr.wr_reason_sk
   WHERE sr.sr_fee > 20
     AND sr.sr_refunded_cash < 1000
     AND r.r_reason_desc LIKE '%purchase%'
     AND cc.cc_state = 'CA'
     AND cp.cp_catalog_number = 5
     AND cp.cp_catalog_page_number BETWEEN 10 AND 20
     AND wr.wr_return_amt_inc_tax > 500
),
hours_unnest AS (
   SELECT f.sr_ticket_number,
          h.value AS hour_part,
          h.ordinality
   FROM filtered f
   CROSS JOIN UNNEST(split(f.cc_hours, '-')) WITH ORDINALITY AS h(value, ordinality)
),
 ticket_diff AS (
   SELECT sr_ticket_number FROM store_returns
   EXCEPT
   SELECT wr_order_number FROM web_returns
 )
SELECT
   f.r_reason_desc,
   f.cc_name,
   f.cp_department,
   SUM(f.sr_net_loss) AS total_net_loss,
   AVG(f.wr_return_amt_inc_tax) AS avg_return_inc_tax,
   COUNT(DISTINCT f.sr_ticket_number) AS unique_tickets,
   COUNT(DISTINCT h.hour_part) AS distinct_hour_parts,
   (SELECT COUNT(*) FROM ticket_diff) AS diff_ticket_count
FROM filtered f
LEFT JOIN hours_unnest h ON f.sr_ticket_number = h.sr_ticket_number
GROUP BY f.r_reason_desc, f.cc_name, f.cp_department
ORDER BY total_net_loss DESC
LIMIT 100
