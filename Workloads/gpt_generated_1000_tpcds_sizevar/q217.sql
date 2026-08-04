/*
Goal: Identify the top‑3 web sites per state (by total net profit) where the site name contains the word "Shop" and the market description contains the word "political" (case‑insensitive). Show each site’s location, zip prefix, total profit, average coupon amount and sales count, compare the site profit against the overall average profit, assign a global row number, and keep only the top‑3 per state.
*/
WITH site_sales AS (
    SELECT
        w.web_state,
        w.web_site_id,
        CONCAT(w.web_city, ', ', w.web_state) AS location,
        SUBSTRING(w.web_zip FROM 1 FOR 3) AS zip_prefix,
        SUM(ws.ws_net_profit)                AS total_profit,
        AVG(ws.ws_coupon_amt)                AS avg_coupon,
        COUNT(*)                              AS sales_cnt
    FROM web_sales ws
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_name LIKE '%Shop%'
      AND REGEXP_LIKE(w.web_mkt_desc, '(?i)political')
    GROUP BY
        w.web_state,
        w.web_site_id,
        w.web_city,
        w.web_state,
        w.web_zip
),
ranked AS (
    SELECT
        ss.*,
        ROW_NUMBER() OVER (ORDER BY ss.total_profit DESC)                                 AS global_row_num,
        ROW_NUMBER() OVER (PARTITION BY ss.web_state ORDER BY ss.total_profit DESC) AS state_rank
    FROM site_sales ss
    WHERE ss.total_profit > (
        SELECT AVG(ws_all.ws_net_profit)
        FROM web_sales ws_all
    )
)
SELECT
    web_state,
    web_site_id,
    location,
    zip_prefix,
    total_profit,
    avg_coupon,
    sales_cnt,
    global_row_num,
    state_rank
FROM ranked
WHERE state_rank <= 3
ORDER BY web_state, total_profit DESC
