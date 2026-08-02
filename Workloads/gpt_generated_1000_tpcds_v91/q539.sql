/*
  Goal: Analyze web sales and returns for promotions whose names contain a numeric code, showing per‑promotion and per‑website metrics such as distinct order counts, distinct sales amounts, distinct return quantities, and total net profit. The query uses regular‑expression filters, string concatenation, a lateral join to pull out the numeric code, a CTE with DISTINCT, an EXISTS sub‑query, and aggregates with DISTINCT.
*/
WITH filtered_promotions AS (
    SELECT DISTINCT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_purpose,
        p.p_channel_event,
        p.p_channel_dmail
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '^Promo[0-9]+')
      AND p.p_channel_event LIKE 'N%'
)
SELECT
    ws.ws_sold_date_sk,
    d.d_date,
    d.d_year,
    ws.ws_web_site_sk,
    web_site.web_name,
    CONCAT(p.p_promo_name, ' - ', p.p_purpose) AS promo_desc,
    pc.promo_code,
    COUNT(DISTINCT ws.ws_order_number)               AS distinct_orders,
    SUM(DISTINCT ws.ws_ext_sales_price)              AS distinct_sales_amount,
    COUNT(DISTINCT wr.wr_return_quantity)            AS distinct_return_qty,
    SUM(ws.ws_net_profit)                            AS total_net_profit
FROM filtered_promotions p
INNER JOIN web_sales ws
    ON ws.ws_promo_sk = p.p_promo_sk
INNER JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
INNER JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
INNER JOIN web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
CROSS JOIN LATERAL (
    SELECT regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_code
) AS pc
WHERE d.d_date >= DATE '2001-01-01'
  AND d.d_date <  DATE '2003-01-01'
  AND t.t_am_pm = 'PM'
  AND EXISTS (
      SELECT 1
      FROM web_returns wr2
      WHERE wr2.wr_order_number = ws.ws_order_number
        AND wr2.wr_return_quantity > 0
  )
GROUP BY
    ws.ws_sold_date_sk,
    d.d_date,
    d.d_year,
    ws.ws_web_site_sk,
    web_site.web_name,
    CONCAT(p.p_promo_name, ' - ', p.p_purpose),
    pc.promo_code
ORDER BY
    distinct_sales_amount DESC,
    total_net_profit DESC
LIMIT 100
