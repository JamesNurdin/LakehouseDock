/*
Goal: Identify web sites whose name starts with the letter "A" and whose company name contains the letter "c". For each such site, compute total net paid sales from store_sales that occurred in the same calendar year as the site opened, filter to items that are red‑colored and have abundant inventory, and compare the site’s sales to the average net paid for all sales in that year.
*/
WITH site_info AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        ws.web_city,
        ws.web_state,
        ws.web_company_name,
        wd.d_year AS open_year,
        regexp_extract(ws.web_name, '(^[A-Za-z]+)') AS name_prefix
    FROM web_site ws
    JOIN date_dim wd
        ON ws.web_open_date_sk = wd.d_date_sk
    WHERE regexp_like(ws.web_name, '^A.*')
      AND ws.web_company_name LIKE '%c%'
)
SELECT
    si.web_site_id,
    si.web_name,
    CONCAT(si.web_city, ', ', si.web_state) AS location,
    si.name_prefix,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders_count,
    (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        JOIN date_dim d2
            ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = si.open_year
    ) AS avg_year_net_paid
FROM site_info si
JOIN store_sales ss
    ON ss.ss_sold_date_sk = ss.ss_sold_date_sk  -- placeholder to allow subsequent join to date_dim
JOIN date_dim sd_date
    ON ss.ss_sold_date_sk = sd_date.d_date_sk
WHERE sd_date.d_year = si.open_year
  AND EXISTS (
        SELECT 1
        FROM inventory inv
        JOIN item i
            ON inv.inv_item_sk = i.i_item_sk
        WHERE inv.inv_quantity_on_hand > 500
          AND i.i_item_sk = ss.ss_item_sk
          AND i.i_color LIKE 'Red%'
    )
GROUP BY
    si.web_site_id,
    si.web_name,
    si.web_city,
    si.web_state,
    si.name_prefix,
    si.open_year,
    CONCAT(si.web_city, ', ', si.web_state)
ORDER BY total_net_paid DESC
LIMIT 100
