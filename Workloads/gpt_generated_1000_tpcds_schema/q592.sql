WITH sampled_sales AS (
    SELECT ws_order_number,
           ws_item_sk,
           ws_web_page_sk,
           ws_sold_time_sk,
           ws_net_profit
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    re.r_reason_desc AS reason,
    concat('Domain: ', regexp_extract(p.wp_url, 'https?://([^/]+)/', 1)) AS domain,
    sum(r.wr_return_amt) AS total_return_amt,
    sum(s.ws_net_profit) AS total_profit,
    (
        SELECT avg(ws_wholesale_cost)
        FROM web_sales
        WHERE ws_wholesale_cost > 20
    ) AS avg_wholesale_cost
FROM sampled_sales s
JOIN web_returns r
  ON r.wr_order_number = s.ws_order_number
JOIN time_dim t
  ON r.wr_returned_time_sk = t.t_time_sk
JOIN web_page p
  ON r.wr_web_page_sk = p.wp_web_page_sk
JOIN reason re
  ON r.wr_reason_sk = re.r_reason_sk
WHERE regexp_like(p.wp_url, '^https?://.*example\\.com')
  AND p.wp_url LIKE '%shop%'
  AND t.t_sub_shift = 'morning'
GROUP BY re.r_reason_desc, p.wp_url

UNION

SELECT
    CAST(NULL AS varchar) AS reason,
    concat('Domain: ', regexp_extract(p.wp_url, 'https?://([^/]+)/', 1)) AS domain,
    CAST(0 AS decimal(7,2)) AS total_return_amt,
    sum(ws.ws_net_profit) AS total_profit,
    (
        SELECT avg(ws_wholesale_cost)
        FROM web_sales
        WHERE ws_wholesale_cost > 20
    ) AS avg_wholesale_cost
FROM web_sales ws
JOIN web_page p
  ON ws.ws_web_page_sk = p.wp_web_page_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
WHERE regexp_like(p.wp_url, '^https?://.*example\\.com')
  AND p.wp_url LIKE '%shop%'
  AND t.t_sub_shift = 'morning'
GROUP BY p.wp_url

LIMIT 100
