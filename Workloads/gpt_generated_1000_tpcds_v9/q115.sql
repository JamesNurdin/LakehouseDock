WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_product_name,
        i.i_current_price,
        regexp_extract(i.i_item_desc, '([A-Z]{2}[0-9]{3})') AS item_code
    FROM item i
    WHERE regexp_like(i.i_item_desc, '(?i)blue')
      AND i.i_product_name LIKE 'A%'
),
sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price
    FROM store_sales ss
    JOIN filtered_items f
        ON ss.ss_item_sk = f.i_item_sk
)
SELECT
    s.s_store_id,
    CONCAT('Store ', s.s_store_name) AS store_label,
    ca.ca_country,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_ticket_cnt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sales.ss_ext_sales_price) AS total_sales_price,
    SUM(sr.sr_net_loss) / NULLIF(SUM(sales.ss_ext_sales_price), 0) AS loss_ratio,
    (
        SELECT r.r_reason_desc
        FROM reason r
        JOIN store_returns sr2 ON sr2.sr_reason_sk = r.r_reason_sk
        WHERE sr2.sr_store_sk = s.s_store_sk
        GROUP BY r.r_reason_desc
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS top_return_reason,
    (
        SELECT f2.item_code
        FROM filtered_items f2
        JOIN store_returns sr3 ON sr3.sr_item_sk = f2.i_item_sk
        WHERE sr3.sr_store_sk = s.s_store_sk
        GROUP BY f2.item_code
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS top_item_code
FROM store_returns sr
JOIN sales
    ON sr.sr_ticket_number = sales.ss_ticket_number
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
  AND s.s_store_name LIKE '%Market%'
  AND EXISTS (
      SELECT 1
      FROM reason r
      WHERE r.r_reason_sk = sr.sr_reason_sk
        AND regexp_like(r.r_reason_desc, '(?i)damage|defect')
  )
GROUP BY s.s_store_id, s.s_store_name, s.s_store_sk, ca.ca_country
ORDER BY total_net_loss DESC
LIMIT 20
