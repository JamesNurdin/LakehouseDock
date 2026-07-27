-- goal: Identify high‑revenue web sites whose market description mentions "children" or "electric",
--   compute total net paid (including shipping) per state and keyword, and classify revenue levels.
WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_paid_inc_ship,
        ws.ws_quantity,
        ws.ws_list_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_ship_cost,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_date_sk
    FROM web_sales ws
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE regexp_like(site.web_mkt_desc, '(?i)children|electric')
      AND site.web_name LIKE 'Web%'
      AND ws.ws_quantity > 1
      AND ws.ws_ext_ship_cost > 0
      AND site.web_state LIKE 'C%'
      AND site.web_street_name LIKE '%Street%'
      AND NOT site.web_mkt_desc LIKE '%Basic%'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = ws.ws_item_sk
            AND ws2.ws_quantity > 5
      )
)
SELECT
    site.web_state,
    regexp_extract(site.web_mkt_desc, '(?i)(children|electric)', 1) AS market_keyword,
    COUNT(DISTINCT fs.ws_order_number) AS distinct_orders,
    SUM(fs.ws_net_paid_inc_ship) AS total_net_paid_inc_ship,
    AVG(fs.ws_ext_ship_cost) AS avg_ship_cost,
    CASE
        WHEN SUM(fs.ws_net_paid_inc_ship) > (SELECT avg(ws_net_paid_inc_ship) FROM web_sales)
            THEN 'High Revenue'
        ELSE 'Normal Revenue'
    END AS revenue_category
FROM filtered_sales fs
JOIN web_site site
    ON fs.ws_web_site_sk = site.web_site_sk
GROUP BY
    site.web_state,
    regexp_extract(site.web_mkt_desc, '(?i)(children|electric)', 1)
HAVING COUNT(DISTINCT fs.ws_order_number) > 5
ORDER BY total_net_paid_inc_ship DESC
LIMIT 100
