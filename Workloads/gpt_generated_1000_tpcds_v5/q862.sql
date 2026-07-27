WITH filtered_sites AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        ws.web_name,
        regexp_extract(ws.web_name, '(\\w+)', 1) AS first_word,
        substring(ws.web_name, 1, 5) AS name_prefix
    FROM web_site ws
    WHERE regexp_like(ws.web_street_number, '^7[0-9]{2}$')
      AND ws.web_name LIKE '%Shop%'
),
sales_agg AS (
    SELECT
        fs.web_site_id,
        fs.web_name,
        fs.first_word,
        fs.name_prefix,
        d.d_year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM filtered_sites fs
    JOIN web_sales ws
        ON ws.ws_web_site_sk = fs.web_site_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        fs.web_site_id,
        fs.web_name,
        fs.first_word,
        fs.name_prefix,
        d.d_year
)
SELECT
    web_site_id,
    web_name,
    first_word,
    name_prefix,
    d_year,
    total_net_paid,
    total_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS yearly_sales_rank
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
