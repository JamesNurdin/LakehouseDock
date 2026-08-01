WITH promo_cte AS (
    SELECT p.p_promo_sk,
           d.d_date AS start_date
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
union_set AS (
    SELECT DISTINCT
        cc.cc_call_center_sk AS call_center_sk,
        cc.cc_name          AS name
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    JOIN LATERAL (
        SELECT SUM(cr.cr_return_amount) AS total_return
        FROM catalog_returns cr
        WHERE cr.cr_call_center_sk = cc.cc_call_center_sk
    ) cr_agg ON TRUE
    WHERE d.d_year = 2000
      AND cr_agg.total_return > (SELECT MAX(ws2.ws_net_paid) FROM web_sales ws2)

    UNION

    SELECT DISTINCT
        ws.ws_ship_mode_sk AS call_center_sk,
        sm.sm_type         AS name
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2000
      AND ws.ws_ext_sales_price > (SELECT MIN(cr3.cr_return_amount) FROM catalog_returns cr3)
      AND EXISTS (SELECT 1 FROM promo_cte p WHERE p.p_promo_sk = ws.ws_promo_sk)
)
SELECT *
FROM union_set
INTERSECT
SELECT
    cc.cc_call_center_sk AS call_center_sk,
    cc.cc_name          AS name
FROM call_center cc
WHERE cc.cc_gmt_offset > 0
EXCEPT
SELECT
    cr.cr_call_center_sk AS call_center_sk,
    CAST('Return' AS varchar) AS name
FROM catalog_returns cr
WHERE cr.cr_return_amount < 0
ORDER BY call_center_sk
LIMIT 100
