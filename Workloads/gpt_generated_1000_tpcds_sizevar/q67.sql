-- Goal: Analyse catalog return amounts by department and year for returns whose description mentions "return" and whose customer city starts with "New".
-- The query also checks that in the same year there was at least one web sale promoted via a channel whose details contain the word "National".
-- It extracts the first three letters of the city, aggregates the return amounts and net loss, and returns the top 100 rows.
WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cp.cp_department,
        d.d_year,
        ca.ca_city
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(cp.cp_description, '(?i)return')
      AND ca.ca_city LIKE 'New%'
)
SELECT
    fr.cp_department,
    fr.d_year,
    SUM(fr.cr_return_amount) AS total_return_amount,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    SUBSTRING(fr.ca_city, 1, 3) AS city_prefix
FROM filtered_returns fr
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d2
        ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = fr.d_year
      AND regexp_like(p.p_channel_details, 'National')
)
GROUP BY
    fr.cp_department,
    fr.d_year,
    SUBSTRING(fr.ca_city, 1, 3)
ORDER BY total_return_amount DESC
LIMIT 100
