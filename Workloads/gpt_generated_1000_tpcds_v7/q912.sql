WITH filtered_items AS (
        SELECT i.i_item_sk,
               i.i_item_desc,
               REGEXP_EXTRACT(i.i_item_desc, '(\\d{3})', 1) AS extracted_digits
        FROM item i
        WHERE REGEXP_LIKE(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
    ),
    rs AS (
        SELECT sr.sr_store_sk,
               sr.sr_reason_sk,
               sr.sr_net_loss,
               sr.sr_item_sk,
               sr.sr_ticket_number
        FROM store_returns sr
        JOIN store_sales ss
          ON sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_item_sk = ss.ss_item_sk
    )
SELECT s.s_store_name,
       r.r_reason_desc,
       SUM(rs.sr_net_loss) AS total_net_loss,
       COUNT(*) AS return_count,
       CONCAT(s.s_store_name, ':', r.r_reason_desc) AS store_reason_key,
       MAX(fi.extracted_digits) AS sample_extracted_digits
FROM rs
JOIN filtered_items fi
  ON rs.sr_item_sk = fi.i_item_sk
JOIN store s
  ON rs.sr_store_sk = s.s_store_sk
JOIN reason r
  ON rs.sr_reason_sk = r.r_reason_sk
WHERE s.s_store_name LIKE '%Market%'
GROUP BY s.s_store_name, r.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
