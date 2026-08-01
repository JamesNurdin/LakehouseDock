WITH sales_data AS (
    SELECT
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        d_sale.d_year,
        s.s_store_name,
        substr(s.s_store_name, 1, 3) AS store_prefix,
        ws.web_name,
        ws.web_class,
        c.c_email_address,
        d_closed.d_date_sk AS closed_date_sk
    FROM store_sales ss
    JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_closed.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d_sale.d_year = 2002
      AND regexp_like(c.c_email_address, '\\d')
      AND s.s_store_name LIKE '%Mall%'
      AND ws.web_class LIKE '%car%'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp
          WHERE cp.cp_type LIKE 'U%'
            AND cp.cp_end_date_sk = d_closed.d_date_sk
      )
)
SELECT
    s_store_name,
    store_prefix,
    web_name,
    d_year,
    sum(ss_net_paid) AS total_net_paid,
    sum(ss_net_profit) AS total_net_profit,
    count(DISTINCT ss_ticket_number) AS distinct_tickets,
    array_agg(DISTINCT regexp_extract(c_email_address, '([0-9]+)')) AS email_digit_sequences,
    (SELECT max(cp_catalog_number) FROM catalog_page cp) AS max_catalog_number
FROM sales_data
GROUP BY
    s_store_name,
    store_prefix,
    web_name,
    d_year
ORDER BY total_net_profit DESC
LIMIT 100
