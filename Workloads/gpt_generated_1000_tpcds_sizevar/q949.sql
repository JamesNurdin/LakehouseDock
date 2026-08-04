WITH sales AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_time_sk,
    ss.ss_addr_sk,
    ss.ss_ext_sales_price,
    ss.ss_ext_tax,
    ss.ss_net_profit,
    ca.ca_address_id,
    ca.ca_state,
    td.t_sub_shift
  FROM store_sales ss
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE regexp_like(ca.ca_address_id, '^AAAAAAA[AB]')
),
returns AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_return_time_sk,
    sr.sr_return_amt,
    sr.sr_return_tax,
    ca.ca_address_id AS return_address_id,
    ca.ca_state AS return_state,
    td.t_sub_shift AS return_sub_shift
  FROM store_returns sr
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  WHERE ca.ca_address_id LIKE 'AAAAAAA%'
),
full_join AS (
  SELECT
    COALESCE(s.ss_ticket_number, r.sr_ticket_number) AS ticket_number,
    s.ss_ext_sales_price,
    r.sr_return_amt,
    s.ca_address_id,
    r.return_address_id,
    s.ca_state,
    r.return_state,
    s.t_sub_shift,
    r.return_sub_shift
  FROM sales s
  FULL OUTER JOIN returns r
    ON s.ss_ticket_number = r.sr_ticket_number
),
sales_with_lateral AS (
  SELECT
    fj.*, 
    la.extracted_part,
    CASE WHEN fj.ss_ext_sales_price IS NULL THEN 0 ELSE fj.ss_ext_sales_price END AS sales_price_coalesce
  FROM full_join fj
  LEFT JOIN LATERAL (
    SELECT regexp_extract(fj.ca_address_id, '(\\d+)$') AS extracted_part
  ) la ON true
),
common_tickets AS (
  SELECT ticket FROM (
    SELECT ss_ticket_number AS ticket FROM store_sales
    INTERSECT
    SELECT sr_ticket_number AS ticket FROM store_returns
  ) intersected
),
final AS (
  SELECT
    swl.ticket_number,
    swl.sales_price_coalesce,
    swl.sr_return_amt,
    swl.extracted_part,
    CASE
      WHEN swl.sr_return_amt IS NULL THEN 'NoReturn'
      WHEN swl.sr_return_amt > 100 THEN 'HighReturn'
      ELSE 'LowReturn'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY swl.ca_state ORDER BY swl.sales_price_coalesce DESC) AS rn_state_sales
  FROM sales_with_lateral swl
  INNER JOIN common_tickets ct ON swl.ticket_number = ct.ticket
)
SELECT
  ticket_number,
  sales_price_coalesce,
  sr_return_amt,
  extracted_part,
  return_category,
  rn_state_sales
FROM final
WHERE return_category LIKE 'H%'
ORDER BY sales_price_coalesce DESC, ticket_number
LIMIT 100
