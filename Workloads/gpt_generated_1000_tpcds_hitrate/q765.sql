WITH inv_open AS (
   SELECT
       dd.d_year,
       ws.web_state,
       SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS total_qty
   FROM inventory i
   RIGHT JOIN date_dim dd
       ON i.inv_date_sk = dd.d_date_sk
   LEFT JOIN web_site ws
       ON ws.web_open_date_sk = dd.d_date_sk
   WHERE dd.d_year = 2001
   GROUP BY CUBE (dd.d_year, ws.web_state)
),
inv_close AS (
   SELECT
       dd.d_year,
       ws.web_state,
       SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS total_qty
   FROM inventory i
   RIGHT JOIN date_dim dd
       ON i.inv_date_sk = dd.d_date_sk
   LEFT JOIN web_site ws
       ON ws.web_close_date_sk = dd.d_date_sk
   WHERE dd.d_year = 2000
   GROUP BY CUBE (dd.d_year, ws.web_state)
),
combined AS (
   SELECT d_year, web_state, total_qty FROM inv_open
   UNION
   SELECT d_year, web_state, total_qty FROM inv_close
)
SELECT
    c.d_year,
    c.web_state,
    c.total_qty,
    ROW_NUMBER() OVER (PARTITION BY c.d_year ORDER BY c.total_qty DESC) AS rank_within_year
FROM combined c
WHERE c.total_qty IS NOT NULL
ORDER BY c.d_year DESC, rank_within_year
LIMIT 100
