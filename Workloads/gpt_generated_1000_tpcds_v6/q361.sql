WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Single' END AS sale_type,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_reason_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_customer_sk,
        ca.ca_city,
        s.s_store_name,
        p.p_promo_name,
        d_sales.d_year AS sales_year,
        d_return.d_year AS return_year,
        r.r_reason_desc
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
)
SELECT
    sd.s_store_name,
    sd.sales_year,
    COUNT(DISTINCT sd.c_customer_sk) AS unique_customers,
    SUM(sd.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sd.sr_return_amt, 0)) AS total_return_amount,
    SUM(sd.ss_quantity) AS total_quantity,
    CASE WHEN SUM(sd.ss_net_profit) > 50000 THEN 'High' ELSE 'Normal' END AS profit_category,
    CASE WHEN SUM(sd.ss_quantity) > 1000 THEN 'BulkStore' ELSE 'RegularStore' END AS store_type
FROM sales_data sd
JOIN store s2 ON sd.ss_store_sk = s2.s_store_sk               -- reuse store with a different alias
JOIN date_dim d_closed ON s2.s_closed_date_sk = d_closed.d_date_sk   -- join closed‑date dimension
JOIN web_page wp ON wp.wp_customer_sk = sd.c_customer_sk
WHERE EXISTS (
    SELECT 1 FROM promotion p2
    WHERE p2.p_promo_sk = sd.ss_promo_sk
      AND p2.p_discount_active = 'Y'
)
  AND wp.wp_type = 'article'
GROUP BY
    sd.s_store_name,
    sd.sales_year
HAVING
    SUM(sd.ss_net_profit) > 10000
    AND COUNT(DISTINCT sd.c_customer_sk) > 5
ORDER BY
    total_net_profit DESC
LIMIT 100
