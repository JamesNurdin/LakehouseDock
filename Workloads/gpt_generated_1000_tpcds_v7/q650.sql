/*
  Goal: Calculate total net profit and ticket count per store and state for the current quarter, 
  focusing on customers whose city starts with 'San' or 'Los' and whose zip code begins with '9'. 
  The query extracts the zip prefix using a regular expression, concatenates city and state, 
  and only includes dates where inventory on hand exceeds 500 units. Results are ordered by profit.
*/
WITH date_filtered AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_quarter_name,
        d.d_current_quarter
    FROM date_dim d
    WHERE d.d_current_quarter = 'Y'
)
SELECT
    s.s_store_name,
    ca.ca_state,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    REGEXP_EXTRACT(ca.ca_zip, '^(\d{2})', 1) AS zip_prefix,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state
FROM store_sales ss
JOIN date_filtered d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
WHERE REGEXP_LIKE(ca.ca_city, '^San|^Los')
  AND ca.ca_zip LIKE '9____'
  AND EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_date_sk = d.d_date_sk
          AND i.inv_quantity_on_hand > 500
      )
GROUP BY
    s.s_store_name,
    ca.ca_state,
    REGEXP_EXTRACT(ca.ca_zip, '^(\d{2})', 1),
    CONCAT(ca.ca_city, ', ', ca.ca_state)
ORDER BY total_net_profit DESC
LIMIT 100
