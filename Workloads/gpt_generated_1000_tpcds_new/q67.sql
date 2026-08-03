WITH promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_number,
        CASE
            WHEN regexp_like(p.p_promo_name, '[A-Z]{3}') THEN 'HAS_3CAPS'
            ELSE 'NO_3CAPS'
        END AS promo_tag
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '[0-9]{2,}')
      AND p.p_promo_name LIKE '%PROMO%'
)
SELECT
    pf.promo_tag,
    pf.promo_number,
    wsit.web_name,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_quantity) AS total_quantity,
    ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
FROM web_sales ws
JOIN promo_filtered pf ON ws.ws_promo_sk = pf.p_promo_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451170
GROUP BY pf.promo_tag, pf.promo_number, wsit.web_name
ORDER BY total_net_paid DESC
LIMIT 100
